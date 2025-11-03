# frozen_string_literal: true

module Types
  class DateTimeType < Types::BaseScalar
    description "Represents a datetime value in ISO 8601 format"

    def self.coerce_input(input_value, context)
      case input_value
      when String
        begin
          DateTime.iso8601(input_value)
        rescue Date::Error
          raise GraphQL::CoercionError, "#{input_value} is not a valid ISO 8601 datetime"
        end
      when DateTime, Time, Date
        input_value.to_datetime
      else
        raise GraphQL::CoercionError,
              "Expected DateTime to be a String or DateTime object, but got #{input_value.class}"
      end
    end

    def self.coerce_result(ruby_value, context)
      case ruby_value
      when DateTime, Time, Date
        ruby_value.iso8601
      when String
        begin
          DateTime.iso8601(ruby_value).iso8601
        rescue Date::Error
          ruby_value.to_s
        end
      else
        ruby_value.to_s
      end
    end
  end
end
