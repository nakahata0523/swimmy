require 'open3'
require 'json'

module Swimmy
  module Service
    class Homework
      DESC_GT_ENTITY = /\\u003e/
      HOMEWORK_TASK_PATTERN = /--\s*>\s*\(([^!]+) !:(\d+)\)/

      class ParseError < StandardError; end

      def self.driver
        Swimmy::Service::RaskCliDriver
      end

      # タイトルからホームワークを取得
      def self.get_homeworks_by_title(title)
        result = driver.document_list(content: [title], is_json: true)
        extract_homeworks(result)
      end

      # JSONからホームワーク情報を抽出
      def self.extract_homeworks(json_string)
        homeworks = []

        json = JSON.parse(json_string)
        return homeworks if json.nil? || json.empty?

        json.each do |doc|
          desc = doc["description"]
          doc_id = doc["id"]
          task_url = doc["task_url"]

          next unless desc

          # \\u003eを>に変換
          desc = desc.gsub(DESC_GT_ENTITY, ">")

          desc.scan(HOMEWORK_TASK_PATTERN).each do |name, ai_num|
            homework = Swimmy::Resource::Homework.new(
              name: name.strip,
              ai_number: ai_num.strip,
              doc_id: doc_id.to_s,
              task_url: task_url,
              rask_url: doc["rask_url"] || "https://rask.nomlab.org"
            )
            homeworks << homework
          end
        end

        homeworks
      rescue JSON::ParserError => e
        raise ParseError, "JSONの解析に失敗しました: #{e.message}"
      end

      # インスタンス経由の呼び出しを許容
      def get_homeworks_by_title(title)
        self.class.get_homeworks_by_title(title)
      end
    end
  end
end
