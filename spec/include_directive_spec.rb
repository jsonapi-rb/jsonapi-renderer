require 'spec_helper'

require 'jsonapi/include_directive'

describe JSONAPI::IncludeDirective, '.initialize' do
  it 'raises InvalidKey exception when keys are invalid' do
    valid_keys   = 'friends,post.comments'
    invalid_keys = ' leading.space,trailing.space ,middle. space'

    expect { JSONAPI::IncludeDirective.new("#{valid_keys},#{invalid_keys}") }.
      to raise_error(JSONAPI::IncludeDirective::InvalidKey, invalid_keys)
  end
end

describe JSONAPI::IncludeDirective, '.key?' do
  it 'handles existing keys' do
    str = 'posts.comments'
    include_directive = JSONAPI::IncludeDirective.new(str)

    expect(include_directive.key?(:posts)).to be_truthy
  end

  it 'handles absent keys' do
    str = 'posts.comments'
    include_directive = JSONAPI::IncludeDirective.new(str)

    expect(include_directive.key?(:author)).to be_falsy
  end

  it 'handles wildcards' do
    str = 'posts.*'
    include_directive = JSONAPI::IncludeDirective.new(
      str, allow_wildcard: true)

    expect(include_directive[:posts].key?(:author)).to be_truthy
    expect(include_directive[:posts][:author].key?(:comments)).to be_falsy
  end

  it 'handles wildcards' do
    str = 'posts.**'
    include_directive = JSONAPI::IncludeDirective.new(
      str, allow_wildcard: true)

    expect(include_directive[:posts].key?(:author)).to be_truthy
    expect(include_directive[:posts][:author].key?(:comments)).to be_truthy
  end
end

describe JSONAPI::IncludeDirective, '.to_string' do
  it 'works' do
    str = 'friends,comments.author,posts.author,posts.comments.author'
    include_directive = JSONAPI::IncludeDirective.new(str)
    expected = include_directive.to_hash
    actual = JSONAPI::IncludeDirective.new(include_directive.to_string)
                                        .to_hash

    expect(actual).to eq expected
  end
end
