require 'time'

module Swimmy
  module Resource
    class ThisMonth
      # attr_reader :id, :content, :due_at
      def self.due_this_month?(base_date, due_at)
        return false unless due_at
        due_at.year == base_date.year && due_at.month == base_date.month
      end

      def self.start_time_as_string(due_at)
        (due_at - 3600).strftime("%Y/%m/%d/%H:%M")
      end

      def self.end_time_as_string(due_at)
        due_at.strftime("%Y/%m/%d/%H:%M")
      end

    end
  end
end
