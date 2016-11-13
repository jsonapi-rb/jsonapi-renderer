require 'jsonapi/renderer/document'

module JSONAPI
  module_function

  # Render a JSON API document.
  #
  # @param [Hash] params
  #   @option [(#jsonapi_id, #jsonapi_type, #jsonapi_related, #as_jsonapi),
  #           Array<(#jsonapi_id, #jsonapi_type, #jsonapi_related, #as_jsonapi)>,
  #           nil] data Primary resource(s) to be rendered.
  #   @option [Array<#jsonapi_id>] errors Errors to be rendered.
  #   @option [String, Hash{Symbol => Hash}] include Relationships to be
  #     included.
  #   @option [Hash{Symbol, Array<Symbol>}] fields List of requested fields
  #     for some or all of the resource types.
  #   @option [Hash] meta Non-standard top-level meta information to be
  #     included.
  #   @option [Hash] links Top-level links to be included.
  #   @option [Hash] jsonapi_object JSON API object.
  def render(params)
    Renderer::Document.new(params).to_hash
  end
end
