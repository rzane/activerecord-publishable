require 'spec_helper'

module Streaming
  describe 'Model' do
    let(:foo) { Foo.new name: 'foo' }
    let(:bar) { Bar.new name: 'bar' }

    describe '.stream' do
      before do
        Foo._commit_callbacks.clear
        Foo.must_have_commit_callbacks 0
      end

      it 'should define default after_commit callbacks' do
        Foo.streamable
        Foo.must_have_commit_callbacks 3
      end

      it 'should allow specifying :on action' do
        Foo.streamable on: [:create, :update]
        Foo.must_have_commit_callbacks 2
      end

      it 'should allow :on to be a symbol' do
        Foo.streamable on: :create
        Foo.must_have_commit_callbacks 1
      end

      it 'should accept :if option' do
        Foo.expects(:after_commit).with(on: :create, if: :something?)
        Foo.streamable on: :create, if: :something?
      end

      it 'should accept :unless option' do
        Foo.expects(:after_commit).with(on: :create, unless: :something?)
        Foo.streamable on: :create, unless: :something?
      end
    end

    describe '#publish_to_stream' do
      let(:channel) { foo.channel_for_streaming :create }
      let(:data)    { foo.serialize_for_streaming }

      it 'should publish the event and data' do
        Streaming.expects(:publish).with(channel, data.to_json)
        foo.publish_to_stream(:create)
      end

      it 'should pass :serialize option to #serialize_for_streaming' do
        Streaming.stubs :publish
        foo.expects(:serialize_for_streaming).with only: [:name]
        foo.publish_to_stream :create, serialize: { only: [:name] }
      end

      it 'should not do anything when disabled' do
        Streaming.stubs(:disabled?).returns(true)
        Streaming.expects(:redis).never
        foo.publish_to_stream :create
      end
    end

    describe '#serialize_for_streaming' do
      it 'should infer an active model serializer' do
        foo.serialize_for_streaming.must_be_instance_of FooSerializer
      end

      it 'should use serializer from :with option' do
        serialized = foo.serialize_for_streaming with: OtherFooSerializer
        serialized.must_be_instance_of OtherFooSerializer
      end

      it 'should default to root: false element' do
        FooSerializer.expects(:new).with foo, root: false
        foo.serialize_for_streaming
      end

      it 'should pass :serialize option to the serializer' do
        FooSerializer.expects(:new).with foo, root: 'foo', only: [:name]
        foo.serialize_for_streaming root: 'foo', only: [:name]
      end

      it 'should serialize with as_json when serializer not found' do
        bar.expects(:as_json).with root: false, only: [:name]
        bar.serialize_for_streaming root: false, only: [:name]
      end
    end

    describe '#channel_for_streaming' do
      it 'should infer a reasonable default' do
        foo.channel_for_streaming(:create).must_equal 'foos:create'
        foo.channel_for_streaming(:update).must_equal 'foos:update'
        foo.channel_for_streaming(:destroy).must_equal 'foos:destroy'
      end

      it 'should allow non-standard events' do
        foo.channel_for_streaming(:custom).must_equal 'foos:custom'
      end
    end
  end
end
