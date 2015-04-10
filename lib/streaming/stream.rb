module Streaming
  module Stream
    def self.registered(app)
      app.helpers Helpers
    end

    def stream(path, options = {}, &block)
      get path, options.merge(provides: 'text/event-stream') do
        response.headers['X-Accel-Buffering'] = 'no'
        channel = channel_for options, &block
        stream :keep_open do |out|
          # Sending an empty byte should prevent connections from
          # from closing prematurely on the client side
          EM.add_periodic_timer(20) { out << "\0" }

          trigger_event :open, channel, out

          subscribe_to channel, out

          out.callback do
            trigger_event :close, channel
            Streaming.unsubscribe_from channel
          end
        end
      end
    end

    def events
      @events ||= Hash.new { |h, k| h[k] = [] }
    end

    def on(type, &block)
      events[type] << block
    end

    module Helpers
      def channel_for(options = {}, &block)
        options[:channel] || (instance_exec(&block) if block_given?) || '*'
      end

      def subscribe_to(pattern, out)
        Streaming.subscribe_to pattern do |channel, message|
          trigger_event :message, channel, message, out
          out << "event: #{channel.split(':').last}\n"
          out << "data: #{message}\n\n"
        end
      end

      def trigger_event(type, *args)
        self.class.events[type].each do |block|
          instance_exec *args, &block
        end
      end
    end
  end
end
