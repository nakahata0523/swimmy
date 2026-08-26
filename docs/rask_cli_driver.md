# Rask

`Swimmy::Service::Rask`([lib/swimmy/service/rask.rb](../lib/swimmy/service/rask.rb)) is a wrapper that shells out to [rask-cli](https://github.com/nomlab/rask/tree/main/cli) (a Rust binary) so swimmy can access data from Rask, the meeting-minutes/task management service.

## Features

- Consists only of class methods; no need to instantiate it
  ```ruby
  Swimmy::Service::Rask.task_list("john")
  ```
- List commands always run `rask-cli ... --json` internally and convert the result into typed objects under `Swimmy::Resource`. Callers never need to think about JSON.

## Prerequisites

- The `rask-cli` binary must already be built
  ```bash
  cd /path/to/rask/cli
  cargo build
  ```
- The following environment variables must be set in `.env` (loaded via `Dotenv.load`) or in the runtime environment

  | Variable | Description | Example |
  |---|---|---|
  | `RASK_CLI_DIR` | Root directory of the `rask-cli` Cargo project (the directory containing `target/debug/rask-cli`) | `/home/nomlab/rask-swimmy/rask/cli` |
  | `RASK_API_KEY` | Rask API token | `rask-xxxxxxxx-xxxx-...` |
  | `RASK_URL` | Rask server URL | `https://rask.nomlab.org/` |

  `RASK_API_KEY`/`RASK_URL` aren't passed to the subprocess directly by the driver — `rask-cli` itself reads them from the environment via clap's `env` attribute. `Open3.capture3` inherits the current process's environment into the child process, so setting them in `.env` is enough; no extra code changes are needed.

  If `RASK_CLI_DIR` isn't set, an exception is raised at call time.

## API

| Method | Corresponding rask-cli command | Return value |
|---|---|---|
| `task_create(title:, assigner_name:, state: nil, project_name: nil, due_at: nil, description: nil)` | `task create` | Raw stdout string (e.g. `"Success to add new task"`) |
| `task_list(username = nil)` | `task list --json [--username]` | `Array<Swimmy::Resource::Task>` |
| `document_list(id: nil, content: nil, creator_id: nil, creator_name: nil, description: nil, project_id: nil, project_name: nil, created_at: nil, updated_at: nil, start_at: nil, end_at: nil, term_duration: nil)` | `document list --json [filters]` | `Array<Swimmy::Resource::Document>` |
| `user_list` | `user list --json` | `Array<Swimmy::Resource::User>` |
| `project_list` | `project list --json` | `Array<Swimmy::Resource::Project>` |

`content`, `creator_name`, `description`, and `project_name` accept either a single string or an array (normalized via `Array(...)` and expanded into rask-cli's multi-value options).

`task_create` returns the raw stdout string rather than a parsed object, since `rask-cli` has no `--json` output for that command.

## Return value classes

`Swimmy::Resource` contains classes matching rask-cli's response shapes. Each one builds an array from a JSON string via `self.parse_list(json_string)`.

- [Swimmy::Resource::Task](../lib/swimmy/resource/task.rb) — `id`, `content`, `state`, `description`, `due_at`, `created_at`, `updated_at`, `creator`, `assigner`, `project`, `url`
- [Swimmy::Resource::Document](../lib/swimmy/resource/document.rb) — `id`, `content`, `creator`, `description`, `created_at`, `updated_at`, `project`, `start_at`, `end_at`, `location`, `url`
- [Swimmy::Resource::User](../lib/swimmy/resource/user.rb) — `id`, `name`, `screen_name`, `active`, `created_at`, `updated_at`, `url`
- [Swimmy::Resource::Project](../lib/swimmy/resource/project.rb) — `id`, `name`, `created_at`, `updated_at`, `user`, `url`
- [Swimmy::Resource::IdName](../lib/swimmy/resource/id_name.rb) — the `{id, name}` reference object used for `creator`/`assigner`/`project`/`user`

## Error handling

- When the CLI exits non-zero: `Swimmy::Service::Rask::CommandFailedError` (message includes stderr)
- When `RASK_CLI_DIR` isn't set: a plain `RuntimeError`

Both are `StandardError` (or `RuntimeError`) subclasses, so callers can catch them with `rescue StandardError`.

## Usage

```ruby
require "swimmy"

driver = Swimmy::Service::Rask

# List tasks (filtered by assignee)
tasks = driver.task_list("john")
tasks.each { |t| puts "#{t.content} (#{t.creator.name})" }

# Search documents
documents = driver.document_list(content: ["第539回New検討打合せ議事録"])

# Create a task
driver.task_create(
  title: "資料作成",
  assigner_name: "john",
  project_name: "新規プロジェクト",
  due_at: "2026-09-01"
)
```

From a Slack command, use the same interface via the `driver` helper on `Swimmy::Command::Base`.

```ruby
class SomeCommand < Swimmy::Command::Base
  command "tasks" do |client, data, match|
    tasks = driver.task_list
    client.say(channel: data.channel, text: tasks.map(&:content).join("\n"))
  end
end
```

## Tests

`spec/rask_spec.rb` stubs `Open3.capture3` to verify argument building and JSON parsing without calling the real binary.

```bash
bundle exec rspec spec/rask_spec.rb
```

To verify connectivity against the real server, set valid `RASK_API_KEY`/`RASK_URL`/`RASK_CLI_DIR` values in `.env`, then call the driver directly from `bundle exec ruby`, or drive `Swimmy::Command::Base.invoke_all` with a script that simulates a Slack command.
