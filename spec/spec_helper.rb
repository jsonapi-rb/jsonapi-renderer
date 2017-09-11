require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'jsonapi/renderer'

class UserResource
  attr_accessor :id, :name, :address, :posts

  def initialize(id, name, address, posts)
    @id = id
    @name = name
    @address = address
    @posts = posts
  end

  def jsonapi_type
    'users'
  end

  def jsonapi_id
    @id.to_s
  end

  def jsonapi_related(included)
    if included.include?(:posts)
      { posts: @posts.map { |p| p } }
    else
      {}
    end
  end

  def jsonapi_cache_key(options = {})
    "#{jsonapi_type} - #{jsonapi_id} - #{options[:include].to_a.sort} - #{(options[:fields] || Set.new).to_a.sort}"
  end

  def as_jsonapi(options = {})
    fields = options[:fields] || [:name, :address, :posts]
    included = options[:include] || []

    hash = { id: jsonapi_id, type: jsonapi_type }
    hash[:attributes] = { name: @name, address: @address }
                        .select { |k, _| fields.include?(k) }
    if fields.include?(:posts)
      hash[:relationships] = { posts: {} }
      hash[:relationships][:posts] = {
        links: {
          self: "http://api.example.com/users/#{@id}/relationships/posts",
          related: {
            href: "http://api.example.com/users/#{@id}/posts",
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
        hash[:relationships][:posts][:data] = @posts.map do |p|
          { type: 'posts', id: p.id.to_s }
        end
      end
    end

    hash[:links] = {
      self: "http://api.example.com/users/#{@id}"
    }
    hash[:meta] = { user_meta: 'is_meta' }

    hash
  end
end

class PostResource
  attr_accessor :id, :title, :date, :author

  def initialize(id, title, date, author)
    @id = id
    @title = title
    @date = date
    @author = author
  end

  def jsonapi_type
    'posts'
  end

  def jsonapi_id
    @id.to_s
  end

  def jsonapi_related(included)
    included.include?(:author) ? { author: [@author] } : {}
  end

  def jsonapi_cache_key(options = {})
    "#{jsonapi_type} - #{jsonapi_id} - #{options[:include].to_a.sort} - #{(options[:fields] || Set.new).to_a.sort}"
  end

  def as_jsonapi(options = {})
    fields = options[:fields] || [:title, :date, :author]
    included = options[:include] || []
    hash = { id: jsonapi_id, type: jsonapi_type }

    hash[:attributes] = { title: @title, date: @date }
                        .select { |k, _| fields.include?(k) }
    if fields.include?(:author)
      hash[:relationships] = { author: {} }
      hash[:relationships][:author] = {
        links: {
          self: "http://api.example.com/posts/#{@id}/relationships/author",
          related: "http://api.example.com/posts/#{@id}/author"
        },
        meta: {
          author_active: true
        }
      }
      if included.include?(:author)
        hash[:relationships][:author][:data] =
          if @author.nil?
            nil
          else
            { type: 'users', id: @author.id.to_s }
          end
      end
    end

    hash
  end
end
