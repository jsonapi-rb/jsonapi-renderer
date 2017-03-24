require 'jsonapi/include_directive/parser'

module JSONAPI
  # Represent a recursive set of include directives
  # (c.f. http://jsonapi.org/format/#fetching-includes)
  #
  # Addition to the spec: two wildcards, namely '*' and '**'.
  # The former stands for any one level of relationship, and the latter stands
  # for any number of levels of relationships.
  # @example 'posts.*' # => Include related posts, and all the included posts'
  #   related resources.
  # @example 'posts.**' # => Include related posts, and all the included
  #   posts' related resources, and their related resources, recursively.
  class IncludeDirective
    # @param include_args (see Parser.parse_include_args)
    def initialize(include_args, options = {})
      @include_hash = Parser.parse_include_args(include_args)

      outer = options[:outer].nil? ? true : outer
      @hash = @include_hash.each_with_object({}) do |(key, value), hash|
        hash[key] = self.class.new(value, outer: false, **options)
      end
      @options = options

      validate if outer
    end

    # @param key [Symbol, String]
    def key?(key)
      @hash.key?(key.to_sym) ||
        (@options[:allow_wildcard] && (@hash.key?(:*) || @hash.key?(:**)))
    end

    # @return [Array<Symbol>]
    def keys
      @hash.keys
    end

    # @param key [Symbol, String]
    # @return [IncludeDirective, nil]
    def [](key)
      case
      when @hash.key?(key.to_sym)
        @hash[key.to_sym]
      when @options[:allow_wildcard] && @hash.key?(:**)
        self.class.new({ :** => {} }, @options)
      when @options[:allow_wildcard] && @hash.key?(:*)
        @hash[:*]
      end
    end

    # @return [Hash{Symbol => Hash}]
    def to_hash
      @hash.each_with_object({}) do |(key, value), hash|
        hash[key] = value.to_hash
      end
    end

    # @return [String]
    def to_string
      string_array = @hash.map do |(key, value)|
        string_value = value.to_string
        if string_value == ''
          key.to_s
        else
          string_value
            .split(',')
            .map { |x| key.to_s + '.' + x }
            .join(',')
        end
      end

      string_array.join(',')
    end

    class InvalidKey < StandardError
      def initialize(keys)
        @keys = keys
      end

      def message
        @keys.join(',')
      end
    end

    private

    def validate
      validation_result = deep_validate(to_hash)
      invalid_keys = extract_invalid_keys(validation_result)

      if invalid_keys.any?
        raise InvalidKey.new(invalid_keys)
      end
    end

    def deep_validate(hash, parent_key = nil, parent_result = true)
      hash.flat_map do |key, value|
        current_key = [parent_key, key.to_s].compact.join(".")
        current_result = valid?(key)

        if value.any?
          deep_validate(value, current_key, current_result)
        else
          { current_key => current_result && parent_result }
        end
      end
    end

    def extract_invalid_keys(validation_result)
      validation_result.map do |result|
        result.map do |key, is_valid|
          key unless is_valid
        end
      end.flatten.compact
    end

    def valid?(key)
      !!key.match(valid_json_key_name_regex)
    end

    def valid_json_key_name_regex
      # not start with hyphen/underscore/space
      # not end with hyphen/underscore/space
      # contains a-zA-Z, *  and hyphen/underscore/space in member names
      /^(?![\s\-_])[\w\s\-\*]+(?<![\s\-_])$/
    end
  end
end
