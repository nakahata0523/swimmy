[![Actions Status](https://github.com/nomlab/swimmy/workflows/build/badge.svg)](https://github.com/nomlab/swimmy/actions?query=workflow%3Abuild)
# swimmy
swimmyとは，B4新人課題で作成した各々のSlackBotを1つにまとめたものである．本プロジェクト名は，絵本作家レオ・レオニ作の絵本「swimmy」に由来し，各々のプログラムをまとめた1つの成果物を表している．



# Setup
- このリポジトリを clone する．

  ```
  $ git clone https://github.com/nomlab/swimmy.git
  ```

- gem のインストール
  - 以下のコマンドを実行し，gemをインストールする．
 
   ```
   $ gem install bundler
   $ bundle install --path vendor/bundle
   ```

- 設定ファイルの作成
  - 以下のコマンドを実行し，.env.sample を .envに変更する．

    ```
    $ cp .env.sample .env
    ```

- Slack appの作成とOAuth Tokenの取得
  - [https://api.slack.com/authentication/basics](https://api.slack.com/authentication/basics)へアクセスし，リンク先の手順に従いclassic Slack appを作成する．[#251](https://github.com/slack-ruby/slack-ruby-bot/pull/251)
  - Appのインストール後生成されるOAuth Tokenを.envに記述する．

- APIキーの設定
  - Google Maps API の API キー取得
    - [Google Maps API](https://developers.google.com/maps/web/) へアクセスし，「キーの取得」をクリックする．
    - 「Select or create project」をクリックする．
    - 「Create a new project」をクリックし，プロジェクト名を付ける．
    - 「NEXT」をクリックすると，Google Maps APIキーが作成される．
    
  - Google Places API の API キー取得
    - [Google Place API](https://developers.google.com/places/web-service)へアクセスし， 「キーの取得」をクリックする．
    - 「Create a new project」を選択し，プロジェクト名を決定する．
    - 「Next」をクリックすると API キーが生成される．

  - Yahoo! JAPAN デベロッパーネットワーク Web API の Client ID の取得
    - [Yahoo! JAPAN デベロッパーネットワーク](https://developer.yahoo.co.jp/)にアクセスする．
    - ページ上部の「機能」をクリックし，「アプリケーションの開発」をクリックする．
    - 本プログラムの使用者の Yahoo!JAPAN アカウントにログインする．
    - 「新しいアプリケーションの開発」をクリックする．
    - アプリケーション情報を入力し，「ガイドラインに同意する」にチェックを入れ，「確認」をクリックする．
    - Client ID を取得する．なお，Client ID を API キーとして用いる．

  - 取得したAPIキーを.envに記述する．

  - Rask CLI との連携
    - `homework` コマンド等が利用する [Rask](docs/rask_cli_driver.md) を使うには，[rask/cli](https://github.com/nomlab/rask/tree/main/cli) をビルドし，`RASK_CLI_DIR`・`RASK_API_KEY`・`RASK_URL` を.envに設定する．詳細は [docs/rask_cli_driver.md](docs/rask_cli_driver.md) を参照．

- sheetqの設定
  - [https://github.com/nomlab/sheetq](https://github.com/nomlab/sheetq)にしたがって設定を行う．
  - GoogleスプレッドシートIDを.envに設定する．

- Google OAuthの設定  
  この設定はtodayコマンド，及びphoto_uploadコマンドの使用に必須である．
  1. [Google Cloud Console](https://console.cloud.google.com/apis/credentials)上で作成したOAuthクライアント認証情報をダウンロード(「OAuthクライアントをダウンロード」，「JSONをダウンロード」の順にクリック)し，config/credentials.jsonとして保存する．
    または，[config/credentials.json.sample](./config/credentials.json.sample)をconfig/credentials.jsonとしてコピーし，自身のクライアント認証情報に沿って編集する．
  2. 以下のコマンドを実行し，Google OAuth アクセストークンを作成する．
     ```bash
     $ ./exe/google_oauth_initializer
     ```

- systemdの設定
  - 以下のコマンドを実行する．
    ```
	# root ユーザ
    $ cp systemd_conf/swimmy.service /etc/systemd/system/swimmy.service
    $ cp systemd_conf/swimmy_env /etc/default/swimmy_env

	# 非 root ユーザ
	$ cp systemd_conf/user/swimmy.service ~/.config/systemd/user/swimmy.service
    $ cp systemd_conf/swimmy_env ~/.config/systemd/user/swimmy_env
    ```

  - コピーした`swimmy.service`について，以下の項目を環境に合わせて設定する．
    ```
    5 WorkingDirectory=/home/nomlab/swimmy
    6 ExecStart=/bin/sh -c 'exec /home/nomlab/swimmy/exe/swimmy >> /var/log/swimmy.log 2>&1'
    7 User=nomlab
    8 Group=nomlab
    ```

  - コピーした`swimmy_env`について，PATHを環境に合わせて設定する．


# Run
以下のコマンドを実行することでswimmyを起動できる．
```
# root ユーザ
$ sudo systemctl start swimmy

# 非 root ユーザ
$ systemctl --user start swimmy
```

また，以下のコマンドを実行することでswimmyを停止できる．
```
# root ユーザ
$ sudo systemctl stop swimmy

# 非 root ユーザ
$ systemctl --user stop swimmy
```
