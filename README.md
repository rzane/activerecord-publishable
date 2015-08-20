# ActiveRecord::Publishable

Publish changes to your ActiveRecord models to Redis for use with PubSub. This allows you to easily implement Server-Sent events.

![Preview](examples/sse/public/streaming.gif?raw=true)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord-publishable'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activerecord-publishable

## Usage

To start publishing changes to your models, include the module and call `publishable`.

```ruby
class Post < ActiveRecord::Base
  include ActiveRecord::Publishable

  publishable
end
```

The `publishable` method creates an `after_commit` hook on create, update, and destroy. You can pass the `:on` option to only push certain events. It accepts all of the options you can pass to an `after_commit` hook, like `:if` and `:unless`.

```ruby
publishable on: [:update, :destroy]
publishable on: :create, if: :some_condition?
publishable on: :create, unless: ->{ dont_push? }
```

When pushing to Redis, your model will be serialized as JSON. If you have ActiveModel::Serializers loaded, your serializer will be looked up. Otherwise, `as_json` will be used.

You can pass options for serialization by using the `:serialize` option. The `:with` option allows you to override the serializer that is used.

```ruby
publishable serialize: { with: OtherPostSerializer }
publishable serialize: { only: [:title, :content] }
```

By default, events will be published to `<collection>:create`, `<collection>:update`, and `<collection>:destroy`, where collection is the plural name of your model. To override this behavior, you can pass the `:channel` option:

```ruby
publishable on: :create, channel: "custom:create"
```

Alternatively, you can override `channel_for_publishing`:

```ruby
class Post < ActiveRecord::Base
  include ActiveRecord::Publishable

  publishable

  def channel_for_publishing(action)
    "posts:#{user.id}:#{action}"
  end
end
```

## Running the demo app

The demo app provides an example of streaming changes to your models using Server-Sent events.

1. Clone the repository
2. Run `bundle install`
3. Run `rake example`
4. Open your browser to localhost:4567

## Contributing

1. Fork it ( https://github.com/rzane/activerecord-publishable/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
