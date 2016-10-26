require 'jsonapi/include_directive'

module JSONAPI
  class Renderer
    def initialize(resources, options = {})
      @resources = resources
      @errors = options[:errors] || false
      @meta = options[:meta] || nil
      @links = options[:links] || {}
      @fields = options[:fields] || {}
      # NOTE(beauby): Room for some nifty defaults on those.
      @jsonapi = options[:jsonapi_object] || nil
      @include = JSONAPI::IncludeDirective.new(options[:include] || {})
    end

    def as_json
      return @json unless @json.nil?

      process_resources
      @json = {}

      if @errors
        @json[:errors] = @resources.map(&:as_jsonapi)
      else
        @json[:data] = @resources.respond_to?(:each) ? @primary : @primary[0]
        @json[:included] = @included if @included.any?
      end
      @json[:links] = @links if @links.any?
      @json[:meta] = @meta unless @meta.nil?
      @json[:jsonapi] = @jsonapi unless @jsonapi.nil?

      @json
    end

    private

    def process_resources
      @primary = []
      @included = []
      @hashes = {}
      @processed = Set.new # NOTE(beauby): Set of [type, id, prefix].
      @queue = []

      Array(@resources).each do |res|
        process_resource(res, '', @include, true)
        @processed.add([res.jsonapi_type, res.jsonapi_id, ''])
      end
      until @queue.empty?
        res, prefix, include_dir = @queue.pop
        process_resource(res, prefix, include_dir, false)
      end
    end

    def merge_resources!(a, b)
      b[:relationships].each do |name, rel|
        a[:relationships][name][:data] ||= rel[:data] if rel.key?(:data)
        (a[:relationships][name][:links] ||= {})
          .merge!(rel[:links]) if rel.key?(:links)
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
        Array(data).each do |child_res|
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

  module_function

  # Render a success JSON API document.
  #
  # @param [(#jsonapi_id, #jsonapi_type, #jsonapi_related, #as_jsonapi),
  #         Array<(#jsonapi_id, #jsonapi_type, #jsonapi_related, #as_jsonapi)>,
  #         nil] resources The primary resource(s) to be rendered.
  # @param [Hash] options All optional.
  #   @option [String, Hash{Symbol => Hash}] include Relationships to be
  #     included.
  #   @option [Hash{Symbol, Array<Symbol>}] fields List of requested fields
  #     for some or all of the resource types.
  #   @option [Hash] meta Non-standard top-level meta information to be
  #     included.
  #   @option [Hash] links Top-level links to be included.
  #   @option [Hash] jsonapi_object JSON API object.
  def render(resources, options = {})
    Renderer.new(resources, options).as_json
  end

  # Render an error JSON API document.
  #
  # @param [Array<#jsonapi_id>] errors Errors to be rendered.
  # @param [Hash] options All optional.
  #   @option [Hash] meta Non-standard top-level meta information to be
  #     included.
  #   @option [Hash] links Top-level links to be included.
  #   @option [Hash] jsonapi_object JSON API object.
  def render_errors(errors)
    Renderer.new(errors, errors: true).as_json
  end
end
