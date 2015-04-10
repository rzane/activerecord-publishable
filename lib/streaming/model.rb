module Streaming
  module Model
    extend ActiveSupport::Concern

    module ClassMethods
      def streamable(options = {})
        Array(options.fetch(:on, [:create, :update, :destroy])).each do |verb|
          after_commit options.merge(on: verb) do
            publish_to_stream verb, options
          end
        end
      end
    end

    def publish_to_stream(action, options = {})
      channel = options[:channel] || channel_for_streaming(action)
      data  = serialize_for_streaming options.fetch(:serialize, {})
      Streaming.publish channel, data.to_json
    end

    def serialize_for_streaming(options = {})
      opts = options.reverse_merge(root: false).except(:with)

      serializer = options.fetch :with do
        next unless defined? ActiveModel::Serializer
        ActiveModel::Serializer.serializer_for self
      end

      serializer ? serializer.new(self, opts) : as_json(opts)
    end

    def channel_for_streaming action
      "#{self.class.model_name.collection}:#{action}"
    end
  end
end
