require 'set'

module JSONAPI
  module Renderer
    class ResourcesProcessor
      def initialize(resources, include, fields)
        @resources = resources
        @include   = include
        @fields    = fields
        @primary   = []
        @included  = []
        @hashes    = {}
        @queue     = []
        @processed = Set.new # NOTE(beauby): Set of [type, id, prefix].
      end

      def process
        @resources.each do |res|
          process_resource(res, '', @include, true)
          @processed.add([res.jsonapi_type, res.jsonapi_id, ''])
        end
        until @queue.empty?
          res, prefix, include_dir = @queue.pop
          process_resource(res, prefix, include_dir, false)
        end

        [@primary, @included]
      end

      private

      def merge_resources!(a, b)
        b[:relationships].each do |name, rel|
          a[:relationships][name][:data] ||= rel[:data] if rel.key?(:data)
          if rel.key?(:links)
            (a[:relationships][name][:links] ||= {}).merge!(rel[:links])
          end
        end
      end

      def process_resource(res, prefix, include_dir, is_primary)
        ri = [res.jsonapi_type, res.jsonapi_id]
        hash = res.as_jsonapi(fields: @fields[res.jsonapi_type.to_sym],
                              include: include_dir.keys)
        if @hashes.key?(ri)
          merge_resources!(@hashes[ri], hash)
        else
          (is_primary ? @primary : @included) << (@hashes[ri] = hash)
        end
        process_relationships(res, prefix, include_dir)
      end

      def process_relationships(res, prefix, include_dir)
        res.jsonapi_related(include_dir.keys).each do |key, data|
          data.each do |child_res|
            next if child_res.nil?
            child_prefix = "#{prefix}.#{key}"
            next unless @processed.add?([child_res.jsonapi_type,
                                         child_res.jsonapi_id,
                                         child_prefix])
            @queue << [child_res, child_prefix, include_dir[key]]
          end
        end
      end
    end
  end
end
