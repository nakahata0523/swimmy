require 'json'
require "sheetq"
require 'swimmy/resource/task_reminder'

module Swimmy
  module Command
    class TaskReminder < Swimmy::Command::Base
      command "task_reminder" do |client, data, match|
        begin
          exec_slack_name = client.web_client.users_info(user: data.user).user.profile.display_name
          rask_members = spreadsheet.sheet("members", Swimmy::Resource::Member).fetch
          exec_member = rask_members.find {|m| m.account == exec_slack_name}
          exec_github_name = exec_member&.github

          msg = ""
          tasks_list = Swimmy::Service::RaskCliDriver.task_list(exec_github_name).map do |t|
            Swimmy::Resource::TaskList.from_task(t)
          end

          if match[:expression]
            msg << "引数は必要ありません．実行した人のタスクのみ表示します．\n\n"
          end

          if tasks_list.empty?
            return msg << "タスクはありません．\n"
          else
            tasks_list.each_with_index do |task, i|
              msg << "#{i + 1}. #{task.to_s}"
            end
          end
        rescue => e
          msg = "タスク取得中にエラーが発生しました．(詳細: #{e.message})\n"
        end
        client.say(channel: data.channel, text: msg)
      end

      help do
        title "task_reminder"
        desc "実行した人のタスクと期限までの日数を表示する"
        long_desc "task_reminder [引数] - メッセージ「引数は必要ありません．」と，実行した人のタスクと期限までの日数を表示する"
      end #help
    end #class TaskReminder
  end #module Command
end #module Swimmy 
