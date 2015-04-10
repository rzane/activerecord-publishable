require 'spec_helper'
require_relative './support/server_manager'

# Redis will need to be running in order to run this test
describe 'Integration' do
  before do
    Foo.delete_all
    Foo.streamable
    @server = ServerManager.new(5000)
    @server.run
  end

  after { @server.kill }

  it 'should push data on create' do
    foo = nil
    chunks = subscribed_to_stream { foo = Foo.create name: 'Yo' }

    create = "event: create\ndata: {\"id\":#{foo.id},\"name\":\"Yo\"}\n\n"
    chunks.first.gsub("\0", '').must_equal create
  end

  it 'should push data on update' do
    foo = Foo.create name: 'Yo'
    chunks = subscribed_to_stream { foo.update name: 'Dawg' }

    update = "event: update\ndata: {\"id\":#{foo.id},\"name\":\"Dawg\"}\n\n"
    chunks.first.gsub("\0", '').must_equal update
  end

  it 'should push data on destroy' do
    foo = Foo.create name: 'Yo'
    chunks = subscribed_to_stream { foo.destroy }

    destroy = "event: destroy\ndata: {\"id\":#{foo.id},\"name\":\"Yo\"}\n\n"
    chunks.first.gsub("\0", '').must_equal destroy
  end

  it 'should push data by calling Model#push_data_to_stream' do
    foo = Foo.new name: 'Yo'
    chunks = subscribed_to_stream { foo.publish_to_stream 'ligers-are-real' }

    ligers_are_real = "event: ligers-are-real\ndata: {\"id\":null,\"name\":\"Yo\"}\n\n"
    chunks.first.gsub("\0", '').must_equal ligers_are_real
  end

  private

  def subscribed_to_stream(&block)
    [].tap do |chunks|
      Timeout.timeout 3 do
        Thread.new { sleep 1; yield }

        @server.get_stream do |chunk|
          chunks << chunk unless chunk.empty?
        end
      end rescue nil
    end
  end
end
