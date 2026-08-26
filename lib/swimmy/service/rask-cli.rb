module Swimmy
    module Service
        class RaskCli
            def initialize(rask_cli_path)
                @RASK_CLI_PATH = rask_cli_path
            end

            def fetch_task_list(GitHub_Username)
                command="task list --assigner-name #{GitHub_Username} --json"
                stdout, stderr, status = Open3.capture3(command, chdir: @RASK_CLI_PATH)
                unless status.success?
                    error_msg = stderr.empty? ? "fetch_task_list の実行に失敗しましたが，エラーメッセージはありませんでした．" : stderr
                raise RTaskToGcError, error_msg
            end

        end
    end
end