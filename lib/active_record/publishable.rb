require 'redis'
require 'active_record/publishable/version'

module ActiveRecord
  module Publishable
    class << self
      attr_writer :redis

      def included(base)
        base.extend ClassMethods
      end

      def disable!
        @disabled = true
      end

      def enable!
        @disabled = nil
      end

      def disabled?
        !!@disabled
      end

      def redis
        @redis ||= Redis.new
      end

      def publish(channel, message)
        redis.publish(channel, message) unless disabled?
      end
    end

    module ClassMethods
      def publishable(options = {})
        Array(options.fetch(:on, [:create, :update, :destroy])).each do |verb|
          after_commit options.merge(on: verb) do
            unless ActiveRecord::Publishable.disabled?
              publish_action(verb, options)
            end
          end
        end
      end
    end

    def publish_action(action, options = {})
      channel = options[:channel] || channel_for_publishing(action)
      data = serialize_for_publishing(options.fetch(:serialize, {}))

      ActiveRecord::Publishable.publish(channel, data.to_json)
    end

    def serialize_for_publishing(options = {})
      opts = options.reverse_merge(root: false).except(:with)

      serializer = options.fetch :with do
        next unless defined? ActiveModel::Serializer
        ActiveModel::Serializer.serializer_for self
      end

      serializer ? serializer.new(self, opts) : as_json(opts)
    end

    def channel_for_publishing(action)
      "#{self.class.model_name.collection}:#{action}"
    end
  end
end
