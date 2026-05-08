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

        def to_s
        # タスクを箇条書きで表示する
          # タスクの期限日時と現在日時の差を計算する
          now = DateTime.now
          diff_days = @due_at - now
          diff_hours = diff_days * 24

          days_left = diff_days.to_i
          hours_left = (diff_hours % 24).to_i

          # 期限まで1週間以内か過ぎている場合，太字で表示する
          if days_left < 7
            " *<#{@url}|#{@content}>* （あと *#{days_left}日#{hours_left}時間* ）\n"
          else
            " <#{@url}|#{@content}> （あと #{days_left}日#{hours_left}時間 ）\n"
          end
        end
      end

      command "task_reminder" do |client, data, match|
        # $ ./rask-cli task list を実行してタスク一覧を取得する
        # 取得したデータをハッシュ形式に変換後，表示するメッセージを作成
        cli_tasks = IO.popen(["/path/to/your/rask-cli", "task", "list"], &:read) # 実際に使用するときのパスは検討する
        tasks = JSON.parse(cli_tasks)

        count = 1;
        msg = ""
        tasks.each do |t|
          task = Task.from_json(t)
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
