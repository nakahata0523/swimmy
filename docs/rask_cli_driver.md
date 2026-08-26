# RaskCliDriver

`Swimmy::Service::RaskCliDriver`([lib/swimmy/service/rask_cli_driver.rb](../lib/swimmy/service/rask_cli_driver.rb))は，Rustで実装された [rask-cli](https://github.com/nomlab/rask/tree/main/cli) をサブプロセスとして呼び出し，Rask（議事録・タスク管理サービス）のデータをswimmyから扱うためのラッパーです．

## 特徴

- クラスメソッドのみで構成されており，インスタンス化は不要
  ```ruby
  Swimmy::Service::RaskCliDriver.task_list("john")
  ```
- 一覧取得系のコマンドは内部で常に `rask-cli ... --json` を実行し，結果を `Swimmy::Resource` 配下の型付きオブジェクトへ変換して返す．呼び出し側はJSONであることを意識する必要がない．

## 前提条件

- `rask-cli` バイナリがビルド済みであること
  ```bash
  cd /path/to/rask/cli
  cargo build
  ```
- 以下の環境変数が `.env`（`Dotenv.load`経由）または実行環境に設定されていること

  | 変数名 | 説明 | 例 |
  |---|---|---|
  | `RASK_CLI_DIR` | `rask-cli` のCargoプロジェクトのルートディレクトリ（`target/debug/rask-cli` を含むディレクトリ） | `/home/nomlab/rask-swimmy/rask/cli` |
  | `RASK_API_KEY` | Raskの APIトークン | `rask-xxxxxxxx-xxxx-...` |
  | `RASK_URL` | RaskサーバーのURL | `https://rask.nomlab.org/` |

  `RASK_API_KEY`/`RASK_URL` はドライバがサブプロセスに直接渡すのではなく，`rask-cli` 側がclapの`env`属性で環境変数から読み取る．`Open3.capture3` は現在のプロセスの環境変数をそのまま子プロセスへ引き継ぐため，`.env` に設定しておけば追加のコード変更なしに反映される．

  `RASK_CLI_DIR` が未設定の場合，呼び出し時に例外が発生する．

## API

| メソッド | 対応するrask-cliコマンド | 戻り値 |
|---|---|---|
| `task_create(title:, assigner_name:, state: nil, project_name: nil, due_at: nil, description: nil)` | `task create` | 標準出力の文字列（例: `"Success to add new task"`） |
| `task_list(username = nil)` | `task list --json [--username]` | `Array<Swimmy::Resource::Task>` |
| `document_list(id: nil, content: nil, creator_id: nil, creator_name: nil, description: nil, project_id: nil, project_name: nil, created_at: nil, updated_at: nil, start_at: nil, end_at: nil, term_duration: nil)` | `document list --json [フィルタ]` | `Array<Swimmy::Resource::Document>` |
| `user_list` | `user list --json` | `Array<Swimmy::Resource::User>` |
| `project_list` | `project list --json` | `Array<Swimmy::Resource::Project>` |

`content`・`creator_name`・`description`・`project_name` は文字列1件でも配列でも渡せる（`Array(...)` で正規化され，rask-cliの複数値オプションとして展開される）．

`task_create` は `rask-cli`側に `--json` 出力が存在しないため，パース済みオブジェクトではなく素の標準出力文字列を返す．

## 返り値のクラス

`Swimmy::Resource` 配下に，rask-cliのレスポンスに対応するクラスを用意している．いずれも `self.parse_list(json_string)` でJSON文字列から配列を生成する．

- [Swimmy::Resource::Task](../lib/swimmy/resource/task.rb) — `id`, `content`, `state`, `description`, `due_at`, `created_at`, `updated_at`, `creator`, `assigner`, `project`, `url`
- [Swimmy::Resource::Document](../lib/swimmy/resource/document.rb) — `id`, `content`, `creator`, `description`, `created_at`, `updated_at`, `project`, `start_at`, `end_at`, `location`, `url`
- [Swimmy::Resource::User](../lib/swimmy/resource/user.rb) — `id`, `name`, `screen_name`, `active`, `created_at`, `updated_at`, `url`
- [Swimmy::Resource::Project](../lib/swimmy/resource/project.rb) — `id`, `name`, `created_at`, `updated_at`, `user`, `url`
- [Swimmy::Resource::IdName](../lib/swimmy/resource/id_name.rb) — `creator`/`assigner`/`project`/`user` として使われる `{id, name}` の参照オブジェクト

## エラーハンドリング

- CLIが非0終了した場合: `Swimmy::Service::RaskCliDriver::CommandFailedError`（標準エラー出力を含むメッセージ）
- `RASK_CLI_DIR` が未設定の場合: 通常の `RuntimeError`

いずれも `StandardError` のサブクラス（または`RuntimeError`）なので，呼び出し側で `rescue StandardError` すれば拾える．

## 使用例

```ruby
require "swimmy"

driver = Swimmy::Service::RaskCliDriver

# タスク一覧（担当者で絞り込み）
tasks = driver.task_list("john")
tasks.each { |t| puts "#{t.content} (#{t.creator.name})" }

# 文書検索
documents = driver.document_list(content: ["第539回New検討打合せ議事録"])

# タスク作成
driver.task_create(
  title: "資料作成",
  assigner_name: "john",
  project_name: "新規プロジェクト",
  due_at: "2026-09-01"
)
```

Slackコマンドから使う場合は `Swimmy::Command::Base` に生えている `driver` ヘルパー経由で同じインターフェースを利用できる．

```ruby
class SomeCommand < Swimmy::Command::Base
  command "tasks" do |client, data, match|
    tasks = driver.task_list
    client.say(channel: data.channel, text: tasks.map(&:content).join("\n"))
  end
end
```

## テスト

`spec/rask_cli_driver_spec.rb` は `Open3.capture3` をスタブし，実バイナリを呼ばずに引数の組み立てとJSONパースを検証する．

```bash
bundle exec rspec spec/rask_cli_driver_spec.rb
```

実サーバーに対する疎通確認は，`.env` に有効な `RASK_API_KEY`/`RASK_URL`/`RASK_CLI_DIR` を設定した上で，`bundle exec ruby` から直接呼び出すか，Slackコマンドを模したスクリプトで `Swimmy::Command::Base.invoke_all` を叩いて確認する．
