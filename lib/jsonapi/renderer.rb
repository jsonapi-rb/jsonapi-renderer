require 'jsonapi/renderer/error_document'
require 'jsonapi/renderer/success_document'

module JSONAPI
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
    Renderer::SuccessDocument.new(resources, options).as_json
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
    Renderer::ErrorDocument.new(errors).as_json
  end
end
