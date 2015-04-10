class FakeRedis
  delegate :publish, to: :pubsub

  def pubsub
    @pubsub ||= PubSub.new
  end

  class PubSub
    def publish channel, message
      keys = subscriptions.keys.select do |c|
        c.split(':').zip(channel.split(':')).all? do |a,b|
          a == '*' || a == b
        end
      end
      subscriptions.values_at(*keys).flatten.each do |c|
        c.call channel, message
      end
    end

    def psubscribe channel, &block
      subscriptions[channel] << block
    end

    def punsubscribe channel
      subscriptions.delete channel
    end

    private

    def subscriptions
      @subscriptions ||= Hash.new { |h,k| h[k] = [] }
    end
  end
end
