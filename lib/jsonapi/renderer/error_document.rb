module JSONAPI
  module Renderer
    class ErrorRenderer
      def initialize(errors, options = {})
        @errors = errors
        @meta = options[:meta] || nil
        @links = options[:links] || {}
        @jsonapi = options[:jsonapi_object] || nil
      end

      def as_json
        return @json unless @json.nil?

        @json = {}
        @json[:errors] = @resources.map(&:as_jsonapi)
        @json[:links] = @links if @links.any?
        @json[:meta] = @meta unless @meta.nil?
        @json[:jsonapi] = @jsonapi unless @jsonapi.nil?

        @json
      end
    end
  end
end
