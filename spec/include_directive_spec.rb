require 'spec_helper'

require 'jsonapi/include_directive'

describe JSONAPI::IncludeDirective, '.initialize' do
  context 'raises InvalidKey when' do
    (
      ["\u002B", "\u002C", "\u002E", "\u005B", "\u005D", "\u002A", "\u002F",
       "\u0040", "\u005C", "\u005E", "\u0060"] + ("\u0021".."\u0029").to_a \
                                               + ("\u003A".."\u003F").to_a \
                                               + ("\u007B".."\u007F").to_a \
                                               + ("\u0000".."\u001F").to_a \
                                               - ['*', '.', ',']
    ).each do |invalid_character|
      it "invalid character provided: '#{invalid_character}'" do
        expect { JSONAPI::IncludeDirective.new(invalid_character) }
          .to raise_error(JSONAPI::IncludeDirective::InvalidKey)
      end
    end

    [' ', '_', '-'].each do |char|
      it "starts with following character: '#{char}'" do
        expect { JSONAPI::IncludeDirective.new("#{char}_with_valid") }
          .to raise_error(JSONAPI::IncludeDirective::InvalidKey, "#{char}_with_valid")
      end

      it "ends with following character: '#{char}'" do
        expect { JSONAPI::IncludeDirective.new("valid_with_#{char}") }
          .to raise_error(JSONAPI::IncludeDirective::InvalidKey, "valid_with_#{char}")
      end
    end
  end

  context 'not raises InvalidKey' do
    ["\u0080", "B", "t", "5", "\u0100", "\u10FFFAA"].each do |char|
      it "when provided characher '#{char}'" do
        expect(JSONAPI::IncludeDirective.new(char).key?(char)).to be true
      end
    end
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
