require 'json'
require "time"

module Swimmy
  module Command
    class TaskReminder < Swimmy::Command::Base
      class Task
        def initialize(content, description, due_at, creator, assigner, url)
          @content = content
          @description = description
          @due_at = due_at
          @creator = creator
          @assigner = assigner
          @url = url
        end

        def self.from_json(task_json)
          content = task_json["content"]
          description = task_json["description"]
          due_at = task_json["due_at"] ? DateTime.parse(task_json["due_at"]) : nil # task_json["due_at"]があればDateTimeにパース, なければ nil 
          creator = task_json["creator"]
          assigner = task_json["assigner"]
          url = task_json["url"]
          new(content, description, due_at, creator, assigner, url)
        end

        def due_at
          @due_at
        end

        def to_s
        # タスクのキーを1つずつ取り出して表示
        <<~TEXT
          タスク: #{@content}
          説明: #{@description}
          期限: #{@due_at ? @due_at.strftime('%Y年%m月%d日%H時%M分') : "未設定"}
          作成者: #{@creator}
          担当者: #{@assigner}
          URL: #{@url}
        TEXT
        end
    end

      command "task_reminder" do |client, data, match|
        # rask-cliを $ cargo run task listして
        # タスクのリストを取得する
        cli_tasks = IO.popen(["/path/to/your/rask-cli", "task", "list"], &:read) # 実際に使用するときのパスは検討する
        tasks = JSON.parse(cli_tasks)
        puts "------------------------------------------------------------------------------------"
        current_day = DateTime.now
        one_week = current_day + 7

        msg_info = "期限が1週間以内のタスクを表示します\n"
        msg = ""
        tasks.each do |t|
        task = Task.from_json(t)
        if task.due_at && task.due_at < one_week
          msg << task.to_s
        end
      end
      total_msg = msg_info + msg
      puts total_msg
      puts "------------------------------------------------------------------------------------"
        client.say(channel: data.channel, text: total_msg)
      end
      
      help do
        title "task_reminder"
        desc "タスクリマインダー"
        long_desc "期限が1週間以内のタスクを表示する"
      end #help
    end #class TaskReminder    
  end #module Command
end #module Swimmy 
