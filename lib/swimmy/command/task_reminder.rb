require 'json'
require "time"

module Swimmy
  module Command
    class TaskReminder < Swimmy::Command::Base
      class Task
        def initialize(content, due_at, assigner, url)
          @content = content
          @due_at = due_at
          @name = assigner["name"]
          @url = url.sub(/.json$/, "")
        end

        def self.from_json(task_json)
          content = task_json["content"]
          due_at = task_json["due_at"] ? DateTime.parse(task_json["due_at"]) : nil # task_json["due_at"]があればDateTimeにパース, なければ nil 
          assigner = task_json["assigner"]
          url = task_json["url"]
          new(content, due_at, assigner, url)
        end

        def due_at
          @due_at
        end

        def to_s
        # タスクのキーを1つずつ取り出して表示
        <<~TEXT
          #{@name} さん
              タスク：#{@content} の期限は【#{@due_at ? @due_at.strftime('%Y年%m月%d日%H時%M分') : "未設定"}】までです．
              #{@url} から確認して下さい．
        TEXT
        end
      end

      command "task_reminder" do |client, data, match|
        # rask-cliを $ cargo run task listして
        # タスクのリストを取得する
        cli_tasks = IO.popen(["/path/to/your/rask-cli", "task", "list"], &:read) # 実際に使用するときのパスは検討する
        tasks = JSON.parse(cli_tasks)
        puts "------------------------------------------------------------------------------------"
        now = DateTime.now
        next_week = now + 7

        msg = ""
        tasks.each do |t|
        task = Task.from_json(t)
        if task.due_at && task.due_at < next_week
          msg << task.to_s
        end
      end
      puts msg
      puts "------------------------------------------------------------------------------------"
        client.say(channel: data.channel, text: msg)
      end
      
      help do
        title "task_reminder"
        desc "タスクリマインダー"
        long_desc "期限が1週間以内のタスクを表示する"
      end #help
    end #class TaskReminder    
  end #module Command
end #module Swimmy 
