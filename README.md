# Streaming

Push changes to your ActiveRecord models to the client side using server-sent events and Redis.

![Streaming Preview](example/public/streaming.gif?raw=true)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'streaming'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install streaming

## Usage

### Model

To start pushing changes your models' attributes, include `Streaming::Model` and call `streamable`.

```ruby
class Post < ActiveRecord::Base
  include Streaming::Model
  streamable
end
```

The `stream` method creates an `after_commit` hook on create, update, and destroy. You can pass the `:on` option to only push certain events. It accepts all of the options you can pass to an `after_commit` hook, like `:if` and `:unless`.

```ruby
streamable on: [:update, :destroy]
streamable on: :create, if: :some_condition?
streamable on: :create, unless: ->{ dont_push? }
```

When pushing to Redis, your model will be serialized as JSON. If you have ActiveModel::Serializers loaded, your serializer will be looked up. Otherwise, `as_json` will be called.

You can pass options for serialization by using the `:serialize` option. The `:with` option allows you to override the serializer that is used.

```ruby
streamable serialize: { with: OtherPostSerializer }
streamable serialize: { only: [:title, :content] }
```

By default, events will be published to `<collection>:create`, `<collection>:update`, and `<collection>:destroy`, where collection is the plural name of your model. To override this behavior, you can pass the `:channel` option:

```ruby
streamable on: :create, channel: "custom:create"
```

Alternatively, you can override `channel_for_streaming`:

```ruby
class Post < ActiveRecord::Base
  include Streaming::Model
  streamable

  def channel_for_streaming(action)
    "posts:#{user.id}:#{action}"
  end
end
```

### Stream

To start broadcasting your models over SSE, create a new class that inherits from `Sinatra::Base`. If you're using Rails, you'll want to put this file in your `lib` directory.

```ruby
class EventStream < Sinatra::Base
  stream '/posts'
end
```

By default, this stream will subscribe to all published events. If you want to restrict it to a specific model, you can pass the `:channel` option:

```ruby
stream '/posts', channel: "posts:*"
```

Alternatively, you can provide a block to be evaluated in the context of the request:

```ruby
stream '/posts' do
  "posts:#{current_user.id}:*"
end
```

If you're using Rails, you'll want to mount this class in your `routes.rb` file.

```ruby
require 'event_stream'

Rails.application.routes.draw do
  mount EventStream, at: '/stream'
end
```

If you're using Devise, you can authenticate this route using `#authenticated`:

```ruby
authenticated :user do
  mount EventStream, at: '/stream'
end
```

### Javascript

Here's the part you've been waiting for: receiving these events on the client side. The [EventSource API](https://developer.mozilla.org/en-US/docs/Web/API/EventSource) is available [all browsers except IE](http://caniuse.com/#search=eventsource).

```javascript
var stream = new EventSource('/stream/posts');

stream.addEventListener('open', function() {
  console.log('Subscribed to ' + stream.url);
});

stream.addEventListener('create', function(event) {
  console.log('Record created', JSON.parse(event.data));
});

stream.addEventListener('update', function() {
  console.log('Record updated', JSON.parse(event.data));
});

stream.addEventListener('destroy', function() {
  console.log('Record destroyed', JSON.parse(event.data));
});

stream.addEventListener('close', function() {
  console.log('Unsubscribed from ' + stream.url);
});
```

## Running the demo app

1. Clone the repository
2. Run `bundle install`
3. Run `rake example`
4. Open your browser to localhost:4567

## Contributing

1. Fork it ( https://github.com/rzane/streaming/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
