require "json"
require 'time'

module Swimmy
  module Resource
    class Task
      attr_reader :id, :content, :state, :description, :due_at, :created_at,
                  :updated_at, :creator, :assigner, :project, :url

      def initialize(id:, content:, created_at:, updated_at:, creator:, assigner:, url:,
                      state: nil, description: nil, due_at: nil, project: nil)
        @id = id
        @content = content
        @state = state
        @description = description
        @due_at = Time.parse(due_at)
        @created_at = Time.parse(created_at)
        @updated_at = Time.parse(updated_at)
        @creator = creator
        @assigner = assigner
        @project = project
        @url = url
      end

      def self.from_hash(hash)
        new(
          id: hash["id"],
          content: hash["content"],
          state: hash["state"],
          description: hash["description"],
          due_at: hash["due_at"],
          created_at: hash["created_at"],
          updated_at: hash["updated_at"],
          creator: IdName.from_hash(hash["creator"]),
          assigner: IdName.from_hash(hash["assigner"]),
          project: IdName.from_hash(hash["project"]),
          url: hash["url"]
        )
      end

      def due_this_month?(base_date)
        return false unless due_at
        due_at.year == base_date.year && due_at.month == base_date.month
      end

      def url(rask_url)
        return '' if rask_url.empty? || id.nil?
        "#{rask_url}/tasks/#{id}"
      end

      def self.parse_list(json_string)
        JSON.parse(json_string).map { |hash| from_hash(hash) }
      end
    end
  end
end
