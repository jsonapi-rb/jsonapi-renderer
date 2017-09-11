require 'spec_helper'

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

  it 'renders nil' do
    actual = subject.render(data: nil)
    expected = {
      data: nil
    }

    expect(actual).to eq(expected)
  end

  it 'renders an empty array' do
    actual = subject.render(data: [])
    expected = {
      data: []
    }

    expect(actual).to eq(expected)
  end

  it 'renders a single resource' do
    actual = subject.render(data: @users[0])
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
    actual = subject.render(data: [@users[0],
                                   @users[1]])
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
    actual = subject.render(data: @users[0],
                            include: JSONAPI::IncludeDirective.from_string('posts'))
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
    actual = subject.render(data: @users[0],
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

  context 'when fields option is nil' do
    it 'does not filter out fields' do
      actual = subject.render(data: @users[0], fields: nil)

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
  end

  it 'renders a toplevel meta' do
    actual = subject.render(data: nil,
                            meta: { this: 'is_meta' })
    expected = {
      data: nil,
      meta: { this: 'is_meta' }
    }

    expect(actual).to eq(expected)
  end

  it 'renders toplevel links' do
    actual = subject.render(data: nil,
                            links: { self: 'http://api.example.com/users' })
    expected = {
      data: nil,
      links: { self: 'http://api.example.com/users' }
    }

    expect(actual).to eq(expected)
  end

  it 'renders a toplevel jsonapi object' do
    actual = subject.render(data: nil,
                            jsonapi: {
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

  it 'renders an empty hash if neither errors nor data provided' do
    actual = subject.render({})
    expected = {}

    expect(actual).to eq(expected)
  end

  class ErrorResource
    def initialize(id, title)
      @id = id
      @title = title
    end

    def as_jsonapi
      { id: @id, title: @title }
    end
  end

  it 'renders errors' do
    errors = [ErrorResource.new('1', 'Not working'),
              ErrorResource.new('2', 'Works poorly')]
    actual = subject.render(errors: errors)
    expected = {
      errors: [{ id: '1', title: 'Not working' },
               { id: '2', title: 'Works poorly' }]
    }

    expect(actual).to eq(expected)
  end

  context 'when rendering a relationship' do
    it 'renders the linkage data only' do
      actual = subject.render(data: @users[0], relationship: :posts)
      expected = {
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

      expect(actual).to eq(expected)
    end

    it 'renders supports include parameter' do
      actual = subject.render(
        data: @users[0], relationship: :posts,
        include: JSONAPI::IncludeDirective.from_string('posts.author')
      )
      actual_included = actual.delete(:included)

      expected = {
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
      expected_included = [
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
          type: 'posts',
          id: '2',
          attributes: {
            title: 'Post 2',
            date: 'today'
          },
          relationships: {
            author: {
              data: { type: 'users', id: '1' },
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

      expect(actual).to eq(expected)
      expect(actual_included).to match_array(expected_included)
    end
  end
end
