module Types
  class JsonType < Types::BaseScalar
    description "Represents JSON data as a hash or array"

    def self.coerce_input(input_value, context)
      case input_value
      when Hash, Array
        input_value
      when String
        begin
          JSON.parse(input_value)
        rescue JSON::ParserError
          raise GraphQL::CoercionError, "#{input_value} is not valid JSON"
        end
      else
        raise GraphQL::CoercionError, "Expected JSON to be a Hash, Array, or String, but got #{input_value.class}"
      end
    end

    def self.coerce_result(ruby_value, context)
      # Convert the result to JSON string and back to ensure consistent serialization
      JSON.parse(JSON.generate(ruby_value))
    rescue JSON::GeneratorError, JSON::ParserError => e
      raise GraphQL::CoercionError, "Could not serialize JSON: #{e.message}"
    end
  end
end
