module JSONAPI
  class Renderer
    # @private
    class ResourcesProcessor
      def process(resources, include, fields)
        @resources = resources
        @include   = include
        @fields    = fields

        traverse_resources
        process_resources

        [@primary, @included]
      end

      private

      def traverse_resources
        # Use hash instead of set for better performances
        @traversed    = {} # Hash[type, id, prefix] => true
        @include_rels = {} # Hash[type, id] => Hash[include_key => true]
        @queue        = []
        @primary      = []
        @included     = []

        initialize_queue
        traverse_queue
      end

      def initialize_queue
        @resources.each do |res|
          @traversed[[res.jsonapi_type, res.jsonapi_id, '']] = true
          traverse_resource(res, @include.keys, true)
          enqueue_related_resources(res, '', @include)
        end
      end

      def traverse_queue
        until @queue.empty?
          res, prefix, include_dir = @queue.shift
          traverse_resource(res, include_dir.keys, false)
          enqueue_related_resources(res, prefix, include_dir)
        end
      end

      def traverse_resource(res, include_keys, primary)
        ri = [res.jsonapi_type, res.jsonapi_id]
        keys_hash = {}
        include_keys.each { |k| keys_hash[k] = true }

        if @include_rels.include?(ri)
          @include_rels[ri].merge!(keys_hash)

          include_duplicate_resource(res) unless primary
        else
          @include_rels[ri] = keys_hash
          (primary ? @primary : @included) << res
        end
      end

      def include_duplicate_resource(res)
        duplicate_index = find_included_duplicate_resource(res)

        return unless duplicate_index

        duplicate = @included.delete_at(duplicate_index)

        if duplicate.is_a?(Array)
          duplicate << res
        else
          duplicate = [duplicate, res]
        end

        @included << duplicate
      end

      def find_included_duplicate_resource(res)
        @included.find_index do |included|
          if included.is_a?(Array)
            unless included.empty?
              included.first.jsonapi_type == res.jsonapi_type && included.first.jsonapi_id == res.jsonapi_id
            end
          else
            included.jsonapi_type == res.jsonapi_type && included.jsonapi_id == res.jsonapi_id
          end
        end
      end

      def enqueue_related_resources(res, prefix, include_dir)
        res.jsonapi_related(include_dir.keys).each do |key, data|
          child_prefix = "#{prefix}.#{key}".freeze
          data.each do |child_res|
            next if child_res.nil?
            enqueue_resource(child_res, child_prefix, include_dir[key])
          end
        end
      end

      def enqueue_resource(res, prefix, include_dir)
        key = [res.jsonapi_type, res.jsonapi_id, prefix]
        return if @traversed[key]

        @traversed[key] = true
        @queue << [res, prefix, include_dir]
      end

      def process_resources
        raise 'Not implemented'
      end
    end
  end
end
