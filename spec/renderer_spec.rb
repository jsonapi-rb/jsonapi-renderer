require 'jsonapi/renderer'

class Model
  def initialize(params)
    params.each { |k, v| instance_variable_set("@#{k}", v) }
  end
end

class User < Model
  attr_accessor :id, :name, :address, :posts
end

class Post < Model
  attr_accessor :id, :title, :date, :author
end

class UserResource
  def initialize(user)
    @user = user
  end

  def jsonapi_type
    'users'
  end

  def jsonapi_id
    @user.id.to_s
  end

  def jsonapi_related(included)
    if included.include?(:posts)
      { posts: @user.posts.map { |p| PostResource.new(p) } }
    else
      {}
    end
  end

  def as_jsonapi(options = {})
    fields = options[:fields] || [:name, :address, :posts]
    included = options[:include] || []

    hash = { id: jsonapi_id, type: jsonapi_type }
    hash[:attributes] = { name: @user.name, address: @user.address }
                        .select { |k, _| fields.include?(k) }
    if fields.include?(:posts)
      hash[:relationships] = { posts: {} }
      hash[:relationships][:posts] = {
        links: {
          self: "http://api.example.com/users/#{@user.id}/relationships/posts",
          related: {
            href: "http://api.example.com/users/#{@user.id}/posts",
            meta: {
              do_not_use: true
            }
          }
        },
        meta: {
          deleted_posts: 5
        }
      }
      if included.include?(:posts)
        hash[:relationships][:posts][:data] = @user.posts.map do |p|
          { type: 'posts', id: p.id.to_s }
        end
      end
    end

    hash[:links] = {
      self: "http://api.example.com/users/#{@user.id}"
    }
    hash[:meta] = { user_meta: 'is_meta' }

    hash
  end
end

class PostResource
  def initialize(post)
    @post = post
  end

  def jsonapi_type
    'posts'
  end

  def jsonapi_id
    @post.id.to_s
  end

  def jsonapi_related(included)
    included.include?(:author) ? { author: UserResource.new(@post.author) } : {}
  end

  def as_jsonapi(options = {})
    fields = options[:fields] || [:title, :date, :author]
    included = options[:include] || []
    hash = { id: jsonapi_id, type: jsonapi_type }

    hash[:attributes] = { title: @post.title, date: @post.date }
                        .select { |k, _| fields.include?(k) }
    if fields.include?(:author)
      hash[:relationships] = { author: {} }
      hash[:relationships][:author] = {
        links: {
          self: "http://api.example.com/posts/#{@post.id}/relationships/author",
          related: "http://api.example.com/posts/#{@post.id}/author"
        },
        meta: {
          author_active: true
        }
      }
      if included.include?(:author)
        hash[:relationships][:author][:data] =
          if @post.author.nil?
            nil
          else
            { type: 'users', id: @post.author.id.to_s }
          end
      end
    end

    hash
  end
end

describe JSONAPI, '#render' do
  before(:all) do
    @users = [
      User.new(id: 1, name: 'User 1', address: '123 Example st.', posts: []),
      User.new(id: 2, name: 'User 2', address: '234 Example st.', posts: []),
      User.new(id: 3, name: 'User 3', address: '345 Example st.', posts: []),
      User.new(id: 4, name: 'User 4', address: '456 Example st.', posts: [])
    ]
    @posts = [
      Post.new(id: 1, title: 'Post 1', date: 'yesterday', author: @users[1]),
      Post.new(id: 2, title: 'Post 2', date: 'today', author: @users[0]),
      Post.new(id: 3, title: 'Post 3', date: 'tomorrow', author: @users[1])
    ]
    @users[0].posts = [@posts[1]]
    @users[1].posts = [@posts[0], @posts[2]]
  end

  it 'renders nil' do
    actual = JSONAPI.render(nil)
    expected = {
      data: nil
    }

    expect(actual).to eq(expected)
  end

  it 'renders an empty array' do
    actual = JSONAPI.render([])
    expected = {
      data: []
    }

    expect(actual).to eq(expected)
  end

  it 'renders a single resource' do
    actual = JSONAPI.render(UserResource.new(@users[0]))
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
      }
    }

    expect(actual).to eq(expected)
  end

  it 'renders a collection of resources' do
    actual = JSONAPI.render([UserResource.new(@users[0]),
                             UserResource.new(@users[1])])
    expected = {
      data: [
        {
          type: 'users',
          id: '1',
          attributes: {
            name: 'User 1',
            address: '123 Example st.'
          },
          relationships: {
            posts: {
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
        {
          type: 'users',
          id: '2',
          attributes: {
            name: 'User 2',
            address: '234 Example st.'
          },
          relationships: {
            posts: {
              links: {
                self: 'http://api.example.com/users/2/relationships/posts',
                related: {
                  href: 'http://api.example.com/users/2/posts',
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
            self: 'http://api.example.com/users/2'
          },
          meta: {
            user_meta: 'is_meta'
          }
        }
      ]
    }

    expect(actual).to eq(expected)
  end

  it 'renders included relationships' do
    actual = JSONAPI.render(UserResource.new(@users[0]),
                            include: 'posts')
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

    expect(actual).to eq(expected)
  end

  it 'filters out fields' do
    actual = JSONAPI.render(UserResource.new(@users[0]),
                            fields: { users: [:name] })
    expected = {
      data: {
        type: 'users',
        id: '1',
        attributes: {
          name: 'User 1'
        },
        links: {
          self: 'http://api.example.com/users/1'
        },
        meta: {
          user_meta: 'is_meta'
        }
      }
    }

    expect(actual).to eq(expected)
  end

  it 'renders a toplevel meta' do
    actual = JSONAPI.render(nil,
                            meta: { this: 'is_meta' })
    expected = {
      data: nil,
      meta: { this: 'is_meta' }
    }

    expect(actual).to eq(expected)
  end

  it 'renders toplevel links' do
    actual = JSONAPI.render(nil,
                            links: { self: 'http://api.example.com/users' })
    expected = {
      data: nil,
      links: { self: 'http://api.example.com/users' }
    }

    expect(actual).to eq(expected)
  end

  it 'renders a toplevel jsonapi object' do
    actual = JSONAPI.render(nil,
                            jsonapi_object: {
                              version: '1.0',
                              meta: 'For real'
                            })
    expected = {
      data: nil,
      jsonapi: {
        version: '1.0',
        meta: 'For real'
      }
    }

    expect(actual).to eq(expected)
  end
end
