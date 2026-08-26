require 'open3'

module Swimmy
  module Driver
    # Thin wrapper around the rask-cli binary (rask/cli).
    #
    # Usage (called as class methods, no need to instantiate):
    #   Swimmy::Driver::RaskCliDriver.task_list(username, is_json)
    #   Swimmy::Driver::RaskCliDriver.document_list(content: ["title"], json: true)
    class RaskCliDriver
      class CommandFailedError < StandardError; end

      class << self
        # task create --title --assigner-name [--state] [--project-name] [--due-at] [--description]
        def task_create(title:, assigner_name:, state: nil, project_name: nil, due_at: nil, description: nil)
          args = ["task", "create", "--title", title, "--assigner-name", assigner_name]
          args += ["--state", state] if state
          args += ["--project-name", project_name] if project_name
          args += ["--due-at", due_at] if due_at
          args += ["--description", description] if description

          run(args)
        end

        # task list [--username] [--json]
        def task_list(username = nil, is_json = false)
          args = ["task", "list"]
          args += ["--username", username] if username
          args << "--json" if is_json

          run(args)
        end

        # document list [filters...] [--json]
        def document_list(id: nil, content: nil, creator_id: nil, creator_name: nil, description: nil,
                           project_id: nil, project_name: nil, created_at: nil, updated_at: nil,
                           start_at: nil, end_at: nil, term_duration: nil, is_json: false)
          args = ["document", "list"]
          args += ["--id", id.to_s] if id
          args += multi_value_option("--content", content)
          args += ["--creator-id", creator_id.to_s] if creator_id
          args += multi_value_option("--creator-name", creator_name)
          args += multi_value_option("--description", description)
          args += ["--project-id", project_id.to_s] if project_id
          args += multi_value_option("--project-name", project_name)
          args += ["--created-at", created_at] if created_at
          args += ["--updated-at", updated_at] if updated_at
          args += ["--start-at", start_at] if start_at
          args += ["--end-at", end_at] if end_at
          args += ["--term-duration", term_duration.to_s] if term_duration
          args << "--json" if is_json

          run(args)
        end

        # user list [--json]
        def user_list(is_json = false)
          args = ["user", "list"]
          args << "--json" if is_json

          run(args)
        end

        # project list [--json]
        def project_list(is_json = false)
          args = ["project", "list"]
          args << "--json" if is_json

          run(args)
        end

        private

        def multi_value_option(flag, values)
          return [] if values.nil?
          values = Array(values)
          return [] if values.empty?

          [flag, *values]
        end

        def run(args)
          stdout, stderr, status = Open3.capture3(cli_path, *args, chdir: cli_dir)

          unless status.success?
            raise CommandFailedError, "CLIコマンド実行エラー: #{stderr.strip}"
          end

          stdout
        end

        def cli_dir
          @cli_dir ||= resolve_cli_dir
        end

        def cli_path
          File.join(cli_dir, "target", "debug", "rask-cli")
        end

        def resolve_cli_dir
          dir = ENV['RASK_CLI_DIR'].to_s.strip
          return dir unless dir.empty?
          raise "環境変数 RASK_CLI_DIR が設定されていません。`.env` または実行環境に `RASK_CLI_DIR=/path/to/RASK_CLI_TEMPLATE` を追加してください。"
        end
      end
    end
  end
end
