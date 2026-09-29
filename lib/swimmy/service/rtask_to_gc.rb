require 'open3'
require 'json'
require 'date'
require 'time'
require 'swimmy/resource'

module Swimmy
  module Service
    class RTaskToGc
      class RTaskToGcError < StandardError
        attr_reader :code, :detail

        def initialize(code, detail = nil)
          @code = code
          @detail = detail
          super(code.to_s)
        end
      end


      def initialize(spreadsheet, target_dir: RASK_CLI_DIR, rask_url: RASK_URL)
        @spreadsheet = spreadsheet
        @target_dir = target_dir
        @rask_url = rask_url
      end

      def sync_rtask_to_google_calendar(slack_name)
        github_name = @spreadsheet.sheet("members", Resource::Member).fetch.find { |member| member.account == slack_name }&.github
        raise RTaskToGcError.new(:github_account_not_found, slack_name) if github_name.nil?


        #rask_service= Service;;Rask.new(@rask_url)
        #tasks=Service::Rask::task_list(github_name)
        tasks = fetch_rtask_tasks(github_name)
        google_oauth = Resource::GoogleOAuth.new('config/credentials.json', 'config/tokens.json')
        calendar_service = Service::GoogleCalendar.from_spreadsheet(google_oauth, @spreadsheet, "nomlab")

        results = []
        tasks.each do |task|
          next unless Resource::ThisMonth.due_this_month?(Date.today, task.due_at)

          event = Resource::CalendarEvent.new(task.content, Resource::ThisMonth.start_time_as_string(task.due_at), Resource::ThisMonth.end_time_as_string(task.due_at))
          if event_registered?(event)
            results << { content: task.content, status: :already_registered }
          else
            calendar_service.add_event(event)
            results << { content: task.content, status: :registered }
          end
        end

        results
      end

      private

      def fetch_rtask_tasks(github_name)
        result = Service::Rask.task_list(github_name)
        raise RTaskToGcError.new(:cli_empty_output) if result.empty?
        result
      end

      def event_registered?(event)
        sheet = @spreadsheet.sheet("calendar", Resource::Calendar)
        calendars = sheet.fetch
        events = Service::CalendarService.new.get_events(calendars, event.name)
        events.any? do |existing|
          existing && existing.summary == event.name && existing.start.iso8601 == event.start.iso8601
        end
      end

    end
  end
end
