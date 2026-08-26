# Ryota Nishi / nomlab
# This is a part of https://github.com/nomlab/swimmy

require 'json'
require 'uri'
require 'net/https'
require 'pp'

module Swimmy
  module Command
    class PhotoUploadBot < Base
      # https://console.developers.google.com/apis/dashboard
      # からダウンロードして置いておく
      GOOGLE_CREDENTIAL_PATH = "config/credentials.json"
      GOOGLE_TOKEN_PATH = "config/tokens.json"

      on 'message' do |client, data|
        if data.files
          data.files.each do |file|
            next unless ["jpg", "png"].include?(file.filetype)
            client.say(channel: data.channel,
                       text: "Google Photos にアップロード中 (#{file.name})...",
                       thread_ts: data.thread_ts || data.ts)

            # NOTE: We cannot use threads to upload multiple photos asynchronously.
            # This is because Google Photos API returns 429 (Too Many Requests)
            # when we upload multiple photos at the same time.
            begin
              google_oauth ||= begin
                  Swimmy::Resource::GoogleOAuth.new(GOOGLE_CREDENTIAL_PATH, GOOGLE_TOKEN_PATH)
                rescue => e
                  message = 'Google OAuthの認証に失敗しました．適切な認証情報が設定されているか確認してください．'
                  client.say(channel: data.channel, text: message)
                  return
                end
              blob = SlackFileDownloader.new(ENV["SLACK_BOT_TOKEN"]).fetch(file.url_private_download)
              url = GooglePhotosUploader.new(google_oauth).upload(blob, file.name, data.text)
              client.say(channel: data.channel,
                         text: "アップロード完了 #{url}",
                         thread_ts: data.thread_ts || data.ts)
            rescue
              message = "写真のアップロードに失敗しました (ファイル名: #{file.name})．"
              client.say(channel: data.channel, text: message)
            end
          end
        end
      end # on message
    end # class PhotoUploadBot

    class GooglePhotosUploader
      def initialize(google_oauth)
        @google_oauth = google_oauth
      end

      def upload(file, filename, comment)
        # 画像データをアップロード
        @upload_url = "https://photoslibrary.googleapis.com/v1/uploads"
        @mkmedia_url = "https://photoslibrary.googleapis.com/v1/mediaItems:batchCreate"

        header =  {
          "Authorization" => "Bearer #{@google_oauth.token}",
          "Content-Type" => "application/octet-stream",
          "X-Goog-Upload-Protocol" => "raw",
          "X-Goog-Upload-File-Name" =>  filename
        }

        uri = URI.parse(@upload_url)
        res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          http.post(uri.request_uri, file, header)
        end
        upload_token = res.body

        # メディアアイテムの作成
        header =  {
          "Authorization" => "Bearer #{@google_oauth.token}",
          "Content-Type" => "application/json"
        }
        req = {:newMediaItems => {:simpleMediaItem => {:uploadToken => upload_token}}}
        uri = URI.parse(@mkmedia_url)
        res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          http.post(uri.request_uri, req.to_json, header)
        end

        result = JSON.parse(res.body)["newMediaItemResults"][0]

        if result["status"]["message"] == "OK"
          url = result["mediaItem"]["productUrl"]
          filename = result["mediaItem"]["filename"]
          "<#{url}|#{filename}>"
        else
          nil
        end
      end
    end # class GooglePhotosUploader

    class SlackFileDownloader
      def initialize(api_token)
        @api_token = api_token
      end

      def fetch(url_private_download)
        uri = URI.parse(url_private_download)
        req = Net::HTTP::Get.new(uri)
        req['Authorization'] = "Bearer #{@api_token}"

        file = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          http.request(req)
        end

        return file.body
      end
    end # class SlackFileDownloader

  end # module Command
end # module Swimmy
