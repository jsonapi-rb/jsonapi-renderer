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

    # Utility class for handling path expansions in include strings.
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
      def next_token(inc, pos)
        delim_off = inc[pos..-1].index(/[\.,\(\)]/)
        path_elem = inc[pos, delim_off]

        [pos + delim_off, path_elem]
      end

      # @api private
      def combine(p1, p2)
        if p1.empty?
          p2
        else
          p1.product(p2).map! { |p, q| "#{p}.#{q}" }
        end
      end

      # @api private
      # rubocop:disable Metrics/PerceivedComplexity, Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
      def _expand(inc, pos)
        path_elem = ''
        paths = []
        cur_paths = []
        while pos < inc.length
          pos, path_elem = next_token(inc, pos)
          cur_paths = combine(cur_paths, [path_elem]) unless path_elem == ''

          delim = inc[pos]
          if delim == '('
            pos, sub_paths = _expand(inc, pos + 1)
            cur_paths = combine(cur_paths, sub_paths)
          elsif delim == ',' || delim == ')'
            paths.concat(cur_paths)
            cur_paths = []
            return [pos, paths] if delim == ')'
          end

          pos += 1
        end

        [inc.length, []]
      end
      # rubocop:enable Metrics/PerceivedComplexity, Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity

      # @api private
      def expand(inc)
        _expand(inc + ')', 0)[1]
      end
    end
  end
end
