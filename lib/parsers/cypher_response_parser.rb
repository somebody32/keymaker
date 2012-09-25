module Keymaker
  class CypherResponseParser

    def self.parse(response_body)
      response_body.data.map do |result|
        if result.first.kind_of?(Hashie::Mash)
          result.first.data
        else
          translate_response(response_body, result)
        end
      end
    end

    def self.translate_response(response_body, result)
      Hashie::Mash.new(Hash[response_body.columns.zip(result)])
    end

  end
end
