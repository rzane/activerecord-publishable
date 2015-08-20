require 'bundler'
Bundler.require(:default, :examples)

ActiveRecord::Publishable.redis = Redis.new(driver: :celluloid)

class Angelo::Server
  def report_errors?
    true
  end
end

class App < Angelo::Base
  report_errors!

  get '/' do
    erb :index
  end

  eventsource '/events/posts' do |sse|
    ActiveRecord::Publishable.redis.psubscribe('posts:*') do |on|
      on.pmessage do |_, channel, message|
        sse.event channel.split(':').last, message
      end
    end
  end
end

App.run!
