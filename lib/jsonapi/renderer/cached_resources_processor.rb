require 'jsonapi/renderer/resources_processor'

module JSONAPI
  class Renderer
    # @private
    class CachedResourcesProcessor < ResourcesProcessor
      def initialize(cache)
        @cache = cache
      end

      def process_resources
        [@primary, @included].each do |resources|
          cache_hash = cache_key_map(resources)
          processed_resources = @cache.fetch_multi(*cache_hash.keys) do |key|
            res, include, fields = cache_hash[key]
            res.as_jsonapi(include: include, fields: fields)
          end

          resources.replace(processed_resources.values)
        end
      end

      def cache_key_map(resources)
        resources.each_with_object({}) do |res, h|
          ri = [res.jsonapi_type, res.jsonapi_id]
          include_dir = @include_rels[ri]
          fields = @fields[ri.first.to_sym]
          h[res.jsonapi_cache_key(include: include_dir, fields: fields)] =
            [res, include_dir, fields]
        end
      end
    end
  end
end
