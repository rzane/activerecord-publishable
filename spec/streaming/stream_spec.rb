require 'spec_helper'

module Streaming
  describe 'Stream' do
    let(:klass) do
      Class.new do
        extend Stream
        include Stream::Helpers
      end
    end

    describe '.on' do
      it 'should register :open event' do
        klass.on(:open) { 'test' }
        klass.events[:open].wont_be_empty
      end

      it 'should register :message event' do
        klass.on(:message) { 'test' }
        klass.events[:message].wont_be_empty
      end
      it 'should register :close event' do
        klass.on(:close) { 'test' }
        klass.events[:close].wont_be_empty
      end
    end

    describe 'Helpers' do
      let(:instance) { klass.new }

      describe '#channel_for' do
        it 'should default to all' do
          instance.channel_for.must_equal '*'
        end

        it 'should use the channel from options' do
          instance.channel_for(channel: 'lions').must_equal 'lions'
        end

        it 'should evaluate a block when provided' do
          instance.channel_for { 'tigers' }.must_equal 'tigers'
        end
      end

      describe '#trigger_event' do
        it 'should evaluate an event block' do
          message = nil
          klass.on(:open) { |arg| message = arg }
          instance.trigger_event(:open, 'yo')
          message.must_equal 'yo'
        end

        it 'should evalulate multiple event blocks in the order they\'re defined' do
          messages = []
          klass.on(:open) { |arg,_| messages << arg }
          klass.on(:open) { |_,arg| messages << arg }
          instance.trigger_event(:open, 'lion', 'tiger')
          messages.must_equal ['lion', 'tiger']
        end
      end

      describe '#subscribe_to' do
        let(:redis) { FakeRedis.new }

        before do
          Streaming.stubs(:hiredis).returns(redis)
        end

        it 'should push received data to out' do
          out = []
          instance.subscribe_to '*', out
          redis.publish 'ligers:create', 'lion + tiger'
          out.must_equal ["event: create\n", "data: lion + tiger\n\n"]
        end

        it 'should detect the correct event' do
          out = []
          instance.subscribe_to '*', out
          redis.publish 'liger:baby:make', 'lion + tiger'
          out.first.must_equal "event: make\n"
        end

        it 'should call the on :message trigger' do
          received = nil
          klass.on(:message) { |*args| received = args }
          instance.subscribe_to '*', []
          redis.publish 'ligers:create', 'i love ligers'
          expected_out = ["event: create\n", "data: i love ligers\n\n"]
          received.must_equal ['ligers:create', 'i love ligers', expected_out]
        end
      end
    end
  end
end
