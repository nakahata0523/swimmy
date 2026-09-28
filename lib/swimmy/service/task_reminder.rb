require "sheetq"
require 'swimmy/service/rask_cli_driver'
require 'swimmy/resource/task_reminder'

module Swimmy
  module Service
    class TaskFinder
    # コマンドを実行したユーザのタスクを取得する
      def self.find_tasks(username)
        task_list = Swimmy::Service::RaskCliDriver.task_list(username).map do |t|
          Swimmy::Resource::TaskList.from_task(t)
        end
      end
    end # class TaskFinder
  end # module Service
end # module Swimmy
