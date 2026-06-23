require 'json'
require 'swimmy/service/task_reminder'

module Swimmy
  module Command
    class TaskReminder < Swimmy::Command::Base
      command "task_reminder" do |client, data, match|
        begin
          rask_cli_path = ENV["RASK_CLI_PATH"]
          tasks_json = `#{rask_cli_path} task list`
          tasks_hash = JSON.parse(tasks_json)

          exec_user_slack_name = client.web_client.users_info(user: data.user).user.profile.display_name
          exec_user_github_name = Swimmy::Service::NameConverter.slack_to_github(spreadsheet, exec_user_slack_name)

          expression = match[:expression]
          msg = Swimmy::Service::MsgGenerator.msg_generate(expression, tasks_hash, exec_user_github_name)
        rescue => e
          msg = "タスク取得中にエラーが発生しました．(詳細: #{e.message})"
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
