require "sheetq"

module Swimmy
  module Service
    class TaskFinder
    # コマンドを実行したユーザと担当者 (assigner) が同一人物であるタスクを取得する
      def self.find_user_id(github_name)
      # user リストから github_name と一致する screen_name の id を取得する
        rask_cli_path = ENV["RASK_CLI_PATH"]
        users_json = `#{rask_cli_path} user list`
        users_hash = JSON.parse(users_json)

        user = users_hash.find {|u| u["screen_name"] == github_name}
        user_id = user&.dig("id")
      end

      def self.find_tasks(github_name)
      # assigner id と user_id が一致するタスクを取得する
        rask_cli_path = ENV["RASK_CLI_PATH"]
        tasks_json = `#{rask_cli_path} task list`
        tasks_hash = JSON.parse(tasks_json)
        user_id = find_user_id(github_name)

        my_tasks = []
        tasks_hash.each do |t|
          if t["assigner"]["id"] == user_id
            my_tasks << Swimmy::Resource::Task.from_json(t)
          end
        end
        my_tasks
      end
    end # class TaskFinder
  end # module Service
end # module Swimmy
