require "swimmy/service/rtask_to_gc"

module Swimmy

  module Command

    class RTaskToGC < Swimmy::Command::Base
      command "rtask_to_gc" do |client, data, match|
        begin
          user = client.web_client.users_info(user: data.user).user
          user_name = user.profile.display_name
          raise ArgumentError, "ユーザの表示名が見つかりませんでした。" if user_name.nil?

          results = Swimmy::Service::RTaskToGc.new(spreadsheet, target_dir: ENV['RASK_CLI_DIR'], rask_url: ENV['RASK_URL']).sync_rtask_to_google_calendar(user_name)
          message = if results.empty?
            "同期対象のタスクはありませんでした．"
          else
            results.map do |result|
              if result[:status] == :already_registered
                "タスク『#{result[:content]}』は既にカレンダに登録されています．"
              else
                "タスク『#{result[:content]}』をカレンダに登録しました．"
              end
            end.join("\n")
          end
          client.say(channel: data.channel, text: message)
        rescue Swimmy::Service::RTaskToGc::RTaskToGcError => e
          message = case e.code
          when :github_account_not_found
            "ユーザ #{e.detail} のGitHubアカウントが見つかりませんでした．"
          when :cli_failed
            e.detail.to_s.empty? ? "rtaskの実行に失敗しましたが，エラーメッセージはありませんでした．" : e.detail
          when :cli_empty_output
            "rtaskの実行に成功しましたが，出力はありませんでした．"
          when :invalid_json
            "JSONのパースに失敗しました．出力内容を確認してください．"
          else
            "rtask_to_gcの実行に失敗しました．"
          end
          client.say(channel: data.channel, text: message)
        rescue Errno::ENOENT => e
          client.say(channel: data.channel, text: "必要なファイルまたはディレクトリが見つかりませんでした: #{e.message}")
        rescue => e
          debug_msg = "エラー発生: #{e.message} (#{e.class})\n場所: #{e.backtrace.first}"
          client.say(channel: data.channel, text: debug_msg)
        end
      end

      help do
        title "rtask_to_gc"
        desc "rtaskのタスクをGoogle Calendarに同期します。"
        long_desc "rtask_to_gc\nGitHub上のタスクをGoogle Calendarへ登録します。"
      end
    end

  end

end
