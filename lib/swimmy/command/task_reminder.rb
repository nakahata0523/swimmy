require 'json'

module Swimmy
  module Command
    class TaskReminder < Swimmy::Command::Base
      command "task_reminder" do |client, data, match|
        # $ ./rask-cli task list を実行してタスク一覧を取得する
        # 取得したデータをハッシュ形式に変換後，表示するメッセージを作成
        cli_tasks = IO.popen(["/path/to/your/rask-cli", "task", "list"], &:read) # 実際に使用するときのパスは検討する
        tasks = JSON.parse(cli_tasks)

        count = 1;
        msg = ""
        tasks.each do |t|
          task = Swimmy::Resource::Task.from_json(t)
            msg << "#{count}. #{task.to_s}"
          count += 1
        end
        client.say(channel: data.channel, text: msg)
      end

      help do
        title "task_reminder"
        desc "タスクリマインダー"
        long_desc "タスクと期限までの日数を表示する"
      end #help
    end #class TaskReminder    
  end #module Command
end #module Swimmy 
