### Changed

* Introduced:
  * `JSONAPI::IncludeDirective.create`.
  * `JSONAPI::IncludeDirective.from_string`
  * `JSONAPI::IncludeDirective.from_array`
  * `JSONAPI::IncludeDirective.from_hash`
* `JSONAPI::IncludeDirective.new` now part of the private API.
* `JSONAPI::Renderer#render`'s `include` option now requires an instance of
    `JSONAPI::IncludeDirective`.

# v0.2.0

### Added

* Support for relationship rendering.
* Support for fragment caching.
* Support for arrays of arrays when rendering errors.

# v0.1.3

# v0.1.2

# v0.1.1
