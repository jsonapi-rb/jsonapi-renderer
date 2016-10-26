require 'jsonapi/include_directive'

describe JSONAPI::IncludeDirective::Parser, '.parse_include_args' do
  it 'handles arrays of symbols and hashes' do
    args = [:friends,
            comments: [:author],
            posts: [:author,
                    comments: [:author]]]
    hash = JSONAPI::IncludeDirective::Parser.parse_include_args(args)
    expected = {
      friends: {},
      comments: { author: {} },
      posts: { author: {}, comments: { author: {} } }
    }

    expect(hash).to eq expected
  end

  it 'handles strings' do
    str = 'friends,comments.author,posts.author,posts.comments.author'
    hash = JSONAPI::IncludeDirective::Parser.parse_include_args(str)
    expected = {
      friends: {},
      comments: { author: {} },
      posts: { author: {}, comments: { author: {} } }
    }

    expect(hash).to eq expected
  end

  it 'treats spaces as part of the resource name' do
    str = 'friends, comments.author , posts.author,posts. comments.author'
    hash = JSONAPI::IncludeDirective::Parser.parse_include_args(str)
    expected = {
      friends: {},
      :' comments' => { :'author ' => {} },
      :' posts' => { author: {} },
      :'posts' => { :' comments' => { author: {} } }
    }

    expect(hash).to eq expected
  end

  it 'handles common prefixes in strings' do
    args = ['friends', 'comments.author', 'posts.author',
            'posts.comments.author']
    hash = JSONAPI::IncludeDirective::Parser.parse_include_args(args)
    expected = {
      friends: {},
      comments: { author: {} },
      posts: { author: {}, comments: { author: {} } }
    }

    expect(hash).to eq expected
  end

  it 'handles an empty string' do
    args = ''
    hash = JSONAPI::IncludeDirective::Parser.parse_include_args(args)
    expected = {}

    expect(hash).to eq expected
  end

  it 'handles an empty array' do
    args = []
    hash = JSONAPI::IncludeDirective::Parser.parse_include_args(args)
    expected = {}

    expect(hash).to eq expected
  end
end
