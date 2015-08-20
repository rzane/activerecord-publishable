require 'spec_helper'

module ActiveRecord
  describe Publishable do
    describe '.disable!' do
      after { Publishable.enable! }

      it 'can be disabled' do
        Publishable.enable!
        Publishable.disable!
        Publishable.disabled?.must_equal true
      end
    end

    describe '.enable!' do
      it 'can be re-enabled' do
        Publishable.disable!
        Publishable.enable!
        Publishable.disabled?.must_equal false
      end
    end

    describe '.redis=' do
      it 'can be assigned' do
        Publishable.redis = 'fake'
        Publishable.redis.must_equal 'fake'
      end
    end

    describe '.publish' do
      let(:redis) { mock('Redis') }

      before { Publishable.redis = redis }
      after  { Publishable.enable! }

      it 'provides a convience publish method' do
        redis.expects(:publish).at_least_once
        Publishable.publish('channel', msg: 'yo')
      end

      it 'does nothing when Publishable.disabled?' do
        Publishable.disable!

        redis.expects(:publish).times(0)
        Publishable.publish('channel', msg: 'yo')
      end
    end

    describe 'ClassMethods' do
      describe '.publishable' do
        before do
          Foo._commit_callbacks.clear
          Foo.must_have_commit_callbacks 0
        end

        it 'should define default after_commit callbacks' do
          Foo.publishable
          Foo.must_have_commit_callbacks 3
        end

        it 'should allow specifying :on action' do
          Foo.publishable on: [:create, :update]
          Foo.must_have_commit_callbacks 2
        end

        it 'should allow :on to be a symbol' do
          Foo.publishable on: :create
          Foo.must_have_commit_callbacks 1
        end

        it 'should accept :if option' do
          Foo.expects(:after_commit).with(on: :create, if: :something?)
          Foo.publishable on: :create, if: :something?
        end

        it 'should accept :unless option' do
          Foo.expects(:after_commit).with(on: :create, unless: :something?)
          Foo.publishable on: :create, unless: :something?
        end
      end
    end

    let(:foo) { Foo.new name: 'foo' }
    let(:bar) { Bar.new name: 'bar' }

    describe '#publish_action' do
      let(:channel) { foo.channel_for_publishing :create }
      let(:data)    { foo.serialize_for_publishing }

      it 'should publish the event and data' do
        Publishable.expects(:publish).with(channel, data.to_json)
        foo.publish_action(:create)
      end

      it 'should pass :serialize option to #serialize_for_publishing' do
        Publishable.stubs :publish
        foo.expects(:serialize_for_publishing).with only: [:name]
        foo.publish_action :create, serialize: { only: [:name] }
      end

      it 'should not do anything when disabled' do
        Publishable.stubs(:disabled?).returns(true)
        Publishable.expects(:redis).never
        foo.publish_action :create
      end
    end

    describe '#serialize_for_publishing' do
      it 'should infer an active model serializer' do
        foo.serialize_for_publishing.must_be_instance_of FooSerializer
      end

      it 'should use serializer from :with option' do
        serialized = foo.serialize_for_publishing with: OtherFooSerializer
        serialized.must_be_instance_of OtherFooSerializer
      end

      it 'should default to root: false element' do
        FooSerializer.expects(:new).with foo, root: false
        foo.serialize_for_publishing
      end

      it 'should pass :serialize option to the serializer' do
        FooSerializer.expects(:new).with foo, root: 'foo', only: [:name]
        foo.serialize_for_publishing root: 'foo', only: [:name]
      end

      it 'should serialize with as_json when serializer not found' do
        bar.expects(:as_json).with root: false, only: [:name]
        bar.serialize_for_publishing root: false, only: [:name]
      end
    end

    describe '#channel_for_publishing' do
      it 'should infer a reasonable default' do
        foo.channel_for_publishing(:create).must_equal 'foos:create'
        foo.channel_for_publishing(:update).must_equal 'foos:update'
        foo.channel_for_publishing(:destroy).must_equal 'foos:destroy'
      end

      it 'should allow non-standard events' do
        foo.channel_for_publishing(:custom).must_equal 'foos:custom'
      end
    end
  end
end
