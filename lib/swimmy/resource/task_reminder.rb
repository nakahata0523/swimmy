require "date"

module Swimmy
  module Resource
    class Task
      def initialize(content, due_at, assigner, url)
        @content = content
        @due_at = due_at
        @name = assigner["name"]
        @url = url.sub(/.json$/, "")
      end

      def self.from_json(task_json)
        content = task_json["content"]
        due_at = task_json["due_at"] ? DateTime.parse(task_json["due_at"]) : nil
        assigner = task_json["assigner"]
        url = task_json["url"]
        new(content, due_at, assigner, url)
      end

      def to_s
        now = DateTime.now
        diff_days = @due_at - now
        diff_hours = diff_days * 24

        days_left = diff_days.to_i
        hours_left = (diff_hours % 24).to_i

        if days_left < 0
          " _<#{@url}|#{@content}> (期限超過: #{days_left}日#{hours_left}時間_ )\n"
        elsif days_left >= 0 && days_left < 7
          " *<#{@url}|#{@content}>* （期限まで: *#{days_left}日#{hours_left}時間* ）\n"
        else
          " <#{@url}|#{@content}> （期限まで: #{days_left}日#{hours_left}時間 ）\n"
        end
      end # to_s
    end # class Task
  end # module Resouce
end # module Swimmy
