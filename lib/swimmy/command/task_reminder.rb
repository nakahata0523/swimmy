require 'json'

module Swimmy
  module Command
    class TaskReminder < Swimmy::Command::Base
      command "task_reminder" do |client, data, match|
        begin
          rask_cli_path = ENV["RASK_CLI_PATH"]
          cli_tasks = `#{rask_cli_path} task list`
          tasks = JSON.parse(cli_tasks)

          msg = ""
          if !match[:expression].nil?
            msg << "引数は必要ありません．実行した人のタスクのみ表示します．\n\n"
          end

          tasks.each_with_index do |t, i|
            task = Swimmy::Resource::Task.from_json(t)
            msg << "#{i+1}. #{task.to_s}"
          end
        rescue => e
          msg = "タスク取得中にエラーが発生しました．"
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
