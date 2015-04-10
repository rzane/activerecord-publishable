require 'streaming/version'
require 'sinatra/base'
require 'redis'
require 'em-hiredis'

module Streaming
  autoload :Model,  'streaming/model'
  autoload :Stream, 'streaming/stream'

  class << self
    attr_writer :redis, :hiredis

    def disable!
      @disabled = true
    end

    def disabled?
      @disabled
    end

    def redis
      @redis ||= Redis.connect
    end

    def hiredis
      @hiredis ||= EM::Hiredis.connect
    end

    def publish channel, message
      redis.publish channel, message
    end

    def subscribe_to channel, &block
      hiredis.pubsub.psubscribe channel, &block
    end

    def unsubscribe_from channel
      hiredis.pubsub.punsubscribe channel
    end
  end
end

Sinatra::Base.register Streaming::Stream