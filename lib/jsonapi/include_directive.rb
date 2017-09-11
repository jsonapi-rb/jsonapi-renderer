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
    # Convenience method to build an IncludeDirective from a string, an array,
    #   or a hash.
    # @param obj [String,Array,Hash]
    # @param options [Hash]
    # @return [IncludeDirective]
    def self.create(obj, options = {})
      if obj.is_a?(String)
        from_string(obj, options)
      elsif obj.is_a?(Array)
        from_array(obj, options)
      elsif obj.is_a?(Hash)
        from_hash(obj, options)
      end
    end

    # Build IncludeDirective from a string.
    # @param string [String]
    # @param options [Hash]
    # @return [IncludeDirective]
    def self.from_string(string, options = {})
      new(Parser.parse_string(string), options)
    end

    # Build IncludeDirective from an array.
    # @param array [Array]
    # @param options [Hash]
    # @return [IncludeDirective]
    def self.from_array(array, options = {})
      new(Parser.parse_array(array), options)
    end

    # Build IncludeDirective from a hash.
    # @param hash [Hash]
    # @param options [Hash]
    # @return [IncludeDirective]
    def self.from_hash(hash, options = {})
      new(Parser.parse_hash(hash), options)
    end

    # @api private
    def initialize(include_hash, options = {})
      @hash = include_hash.each_with_object({}) do |(key, value), hash|
        hash[key] = self.class.new(value, options)
      end
      @options = options
    end

    # @param key [Symbol, String]
    # @return [Boolean]
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
      if @hash.key?(key.to_sym)
        @hash[key.to_sym]
      elsif @options[:allow_wildcard] && @hash.key?(:**)
        self.class.new({ :** => {} }, @options)
      elsif @options[:allow_wildcard] && @hash.key?(:*)
        @hash[:*]
      end
    end

    # @return [Hash{Symbol => Hash}]
    def to_hash
      @hash.each_with_object({}) do |(key, value), hash|
        hash[key] = value.to_hash
      end
    end
    alias to_h to_hash

    # @return [String]
    def to_string
      string_array = @hash.map do |(key, value)|
        string_value = value.to_string
        if string_value == ''
          key.to_s
        else
          string_value.split(',').map { |x| key.to_s + '.' + x }.join(',')
        end
      end

      string_array.join(',')
    end
    alias to_s to_string
  end
end
