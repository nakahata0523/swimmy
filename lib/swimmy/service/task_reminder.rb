require "sheetq"

module Swimmy
  module Service
    class NameConverter
    # slack ユーザ名に対応する github ユーザ名に変換する
      def self.slack_to_github(spreadsheet, slack_name)
        members = spreadsheet.sheet("members", Swimmy::Resource::Member).fetch
        member = members.find {|m| m.account == slack_name}
        member&.github
      end
    end # class NameConverter

    class MsgGenerator
    # コマンドを実行したユーザと assigner が同一人物であるタスクを一覧表示する
      def self.find_user_id(github_name)
      # user リストから github_name と一致する screen_name の id を取得する
        rask_cli_path = ENV["RASK_CLI_PATH"]
        users_json = `#{rask_cli_path} user list`
        users_hash = JSON.parse(users_json)

        user = users_hash.find {|u| u["screen_name"] == github_name}
        user_id = user&.dig("id")
      end

      def self.find_tasks(tasks_hash, user_id)
      # assigner id と user_id が一致するタスクを取得する
        my_tasks = []
        tasks_hash.each do |t|
          if t["assigner"]["id"] == user_id
            my_tasks << Swimmy::Resource::Task.from_json(t)
          end
        end
        my_tasks
      end

      def self.msg_generate(expression, tasks_hash, github_name)
        msg = ""

        if expression
          msg << "引数は必要ありません．実行した人のタスクのみ表示します．\n\n"
        end

        user_id = find_user_id(github_name)
        if user_id.nil?
          return msg << "あなたは Rask のユーザに登録されていません．\n"
        end

        my_tasks = find_tasks(tasks_hash, user_id)

        if my_tasks.empty?
          return msg << "タスクはありません．"
        else
          my_tasks.each_with_index do |task, i|
            msg << "#{i + 1}. #{task.to_s}"
          end
        end
        msg
      end # def generate
    end # class MsgGenerator
  end # module Service
end # module Swimmy
