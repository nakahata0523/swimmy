require 'json'
require "time"

module Swimmy
  module Command
    class TaskReminder < Swimmy::Command::Base
      command "task_reminder" do |client, data, match|
        # rask-cliを $ cargo run task listして
        # タスクのリストを取得する
        cli_tasks = IO.popen(["/path/to/your/rask-cli", "task", "list"], &:read) # 実際に使用するときのパスは検討する
        tasks = JSON.parse(cli_tasks)
        puts "------------------------------------------------------------------------------------"
        # ループですべてのリストの due_at と現在日時を比べる
            # 現在日時から1週間後の日時を取得
            # その日時とタスクの日時を比較
            # 1週間以内のものを表示する
        current_day = Time.now
        one_week = current_day + 7 * 86400

        task_one_week = []
        tasks.each do |task|
          due_at = Time.parse(task["due_at"])
          if due_at < one_week
            task_one_week << task
            p task_one_week
          end
        end
        puts "------------------------------------------------------------------------------------"

        client.say(channel: data.channel, text: task_one_week)
      end
      
      help do
        title "task_reminder"
        desc "タスクリマインダー"
        long_desc ""
      end #help
    end #class TaskReminder    
  end #module Command
end #module Swimmy 
