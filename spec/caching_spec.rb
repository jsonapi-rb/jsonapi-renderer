require 'spec_helper'

class Cache
  def initialize
    @cache = {}
  end

  def fetch_multi(*keys)
    keys.each_with_object({}) do |k, h|
      @cache[k] = yield(k) unless @cache.key?(k)
      h[k] = @cache[k]
    end
  end
end

describe JSONAPI::Renderer, '#render' do
  before(:all) do
    @users = [
      UserResource.new(1, 'User 1', '123 Example st.', []),
      UserResource.new(2, 'User 2', '234 Example st.', []),
      UserResource.new(3, 'User 3', '345 Example st.', []),
      UserResource.new(4, 'User 4', '456 Example st.', [])
    ]
    @posts = [
      PostResource.new(1, 'Post 1', 'yesterday', @users[1]),
      PostResource.new(2, 'Post 2', 'today', @users[0]),
      PostResource.new(3, 'Post 3', 'tomorrow', @users[1])
    ]
    @users[0].posts = [@posts[1]]
    @users[1].posts = [@posts[0], @posts[2]]
  end

  it 'renders included relationships' do
    cache = Cache.new
    # Warm up the cache.
    subject.render(data: @users[0],
                   include: 'posts',
                   cache: cache)
    # Actual call on warm cache.
    actual = subject.render(data: @users[0],
                            include: 'posts',
                            cache: cache)
    expected = {
      data: {
        type: 'users',
        id: '1',
        attributes: {
          name: 'User 1',
          address: '123 Example st.'
        },
        relationships: {
          posts: {
            data: [{ type: 'posts', id: '2' }],
            links: {
              self: 'http://api.example.com/users/1/relationships/posts',
              related: {
                href: 'http://api.example.com/users/1/posts',
                meta: {
                  do_not_use: true
                }
              }
            },
            meta: {
              deleted_posts: 5
            }
          }
        },
        links: {
          self: 'http://api.example.com/users/1'
        },
        meta: {
          user_meta: 'is_meta'
        }
      },
      included: [
        {
          type: 'posts',
          id: '2',
          attributes: {
            title: 'Post 2',
            date: 'today'
          },
          relationships: {
            author: {
              links: {
                self: 'http://api.example.com/posts/2/relationships/author',
                related: 'http://api.example.com/posts/2/author'
              },
              meta: {
                author_active: true
              }
            }
          }
        }
      ]
    }

    expect(JSON.parse(actual.to_json)).to eq(JSON.parse(expected.to_json))
    expect(actual[:data]).to be_a(Hash)
  end
end
