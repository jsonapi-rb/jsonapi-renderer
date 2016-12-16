module JSONAPI
  class IncludeDirective
    # Utilities to create an IncludeDirective hash from various types of
    # inputs.
    class Parser
      # @api private
      def initialize(include_args)
        @hash = parse_include_args(include_args)
        freeze
      end

      def to_hash
        @hash
      end
      alias to_h to_hash

      private

      # @api private
      def parse_include_args(include_args)
        case include_args
        when Symbol
          { include_args => {} }
        when Hash
          parse_hash(include_args)
        when Array
          parse_array(include_args)
        when String
          str = PathExpander.new(include_args).to_str
          parse_string(str)
        else
          {}
        end
      end

      # @api private
      def parse_string(include_string)
        include_string.split(',')
          .each_with_object({}) do |path, hash|
            deep_merge!(hash, parse_path_string(path))
        end
      end

      # @api private
      def parse_path_string(include_path)
        include_path.split('.')
          .reverse
          .reduce({}) { |a, e| { e.to_sym => a } }
      end

      # @api private
      def parse_hash(include_hash)
        include_hash.each_with_object({}) do |(key, value), hash|
          hash[key.to_sym] = parse_include_args(value)
        end
      end

      # @api private
      def parse_array(include_array)
        include_array.each_with_object({}) do |x, hash|
          deep_merge!(hash, parse_include_args(x))
        end
      end

      # @api private
      def deep_merge!(src, ext)
        ext.each do |k, v|
          if src[k].is_a?(Hash) && v.is_a?(Hash)
            deep_merge!(src[k], v)
          else
            src[k] = v
          end
        end
      end
    end

    class PathExpander
      def initialize(str)
        @str = expand(str).join(',')
        freeze
      end

      def to_str
        @str
      end
      alias to_s to_str

      private

      # @api private
      def _expand(inc, pos)
        path_elem = ''
        paths = []
        cur_paths = []
        while pos < inc.length
          if inc[pos] == '('
            end_pos, sub_paths = _expand(inc, pos + 1)
            pos = end_pos
            if cur_paths.empty?
              cur_paths = sub_paths
            else
              cur_paths = cur_paths.product(sub_paths).map { |p, q| "#{p}.#{q}" }
            end
            next
          end

          # delimit path element
          if inc[pos] == '.' || inc[pos] == ',' || inc[pos] == ')'
            if path_elem != ''
              if cur_paths.empty?
                cur_paths = [path_elem]
              else
                cur_paths.map! { |p| "#{p}.#{path_elem}" }
              end
              path_elem = ''
            end
          else
            path_elem += inc[pos]
          end

          if inc[pos] == ',' || inc[pos] == ')'
            paths.concat(cur_paths)
            cur_paths = []
          end

          return [pos + 1, paths] if inc[pos] == ')'

          pos += 1
        end

        [inc.length, []]
      end

      # @api private
      def expand(inc)
        _expand(inc + ')', 0)[1]
      end
    end
  end
end
