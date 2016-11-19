# jsonapi-renderer
Ruby gem for rendering [JSON API](http://jsonapi.org) documents.

## Status

[![Gem Version](https://badge.fury.io/rb/jsonapi-renderer.svg)](https://badge.fury.io/rb/jsonapi-renderer)
[![Build Status](https://secure.travis-ci.org/jsonapi-rb/renderer.svg?branch=master)](http://travis-ci.org/jsonapi-rb/renderer?branch=master)
[![codecov](https://codecov.io/gh/jsonapi-rb/renderer/branch/master/graph/badge.svg)](https://codecov.io/gh/jsonapi-rb/renderer)

## Installation
```ruby
# In Gemfile
gem 'jsonapi-renderer'
```
then
```
$ bundle
```
or manually via
```
$ gem install jsonapi-renderer
```

## Usage

First, require the gem:
```ruby
require 'jsonapi/renderer'
```

### Rendering resources

A resource here is any class that implements the following interface:
```ruby
class ResourceInterface
  # Returns the type of the resource.
  # @return [String]
  def jsonapi_type; end

  # Returns the id of the resource.
  # @return [String]
  def jsonapi_id; end

  # Returns a hash containing, for each included relationship, the resource(s)
  # to be included from that one.
  # @param [Array<Symbol>] included_relationships The keys of the relationships
  #   to be included.
  # @return [Hash{Symbol => #ResourceInterface, Array<#ResourceInterface>}]
  def jsonapi_related(included_relationships); end

  # Returns a JSON API-compliant representation of the resource as a hash.
  # @param [Hash] options
  #   @option [Array<Symbol>, Nil] fields The requested fields, or nil.
  #   @option [Array<Symbol>, Nil] included The requested included
  #     relationships, or nil.
  # @return [Hash]
  def as_jsonapi(options = {}); end
end
```

#### Rendering a single resource
```ruby
JSONAPI.render(data: resource,
               include: include_string,
               fields: fields_hash,
               meta: meta_hash,
               links: links_hash)
```

This returns a JSON API compliant hash representing the described document.

#### Rendering a collection of resources
```ruby
JSONAPI.render(data: resources,
               include: include_string,
               fields: fields_hash,
               meta: meta_hash,
               links: links_hash)
```

This returns a JSON API compliant hash representing the described document.

### Rendering errors

```ruby
JSONAPI.render_errors(errors: errors,
                      meta: meta_hash,
                      links: links_hash)
```

where `errors` is an array of objects implementing the `as_jsonapi` method, that
returns a JSON API-compliant representation of the error.

This returns a JSON API compliant hash representing the described document.

## License

jsonapi-renderer is released under the [MIT License](http://www.opensource.org/licenses/MIT).
