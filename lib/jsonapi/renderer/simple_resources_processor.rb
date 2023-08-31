require 'jsonapi/renderer/resources_processor'

module JSONAPI
  class Renderer
    # @api private
    class SimpleResourcesProcessor < ResourcesProcessor
      def process_resources
        [@primary, @included].each do |resources|
          resources.map! do |res|
            # Duplicates array
            if res.is_a?(Array)
              process_duplicates(res)
            # Regular resource case
            else
              process_resource(res)
            end
          end
        end
      end

      def process_resource(resource)
        ri = [resource.jsonapi_type, resource.jsonapi_id]
        include_dir = @include_rels[ri].keys
        fields = @fields[resource.jsonapi_type.to_sym]
        resource.as_jsonapi(include: include_dir, fields: fields)
      end

      def process_duplicates(duplicates)
        return unless duplicates.is_a?(Array) && duplicates.any?

        duplicates.inject({}) do |result, duplicate|
          if result.empty?
            result = process_resource(duplicate) if result.empty?
          else
            duplicate_result = process_resource(duplicate)
            result = deep_merge_duplicate_hashes(result, duplicate_result)
          end
        end
      end

      def deep_merge_duplicate_hashes(hash1, hash2)
        merger = proc do |_, v1, v2|
          if v1.is_a?(Hash) && v2.is_a?(Hash)
            v1.merge(v2, &merger)
          elsif v1.is_a?(Array) && v2.is_a?(Array)
            v1 | v2
          elsif [:undefined, nil, :nil].include?(v2)
            v1
          else
            v2
          end
        end

        hash1.merge(hash2, &merger)
      end
    end
  end
end
