require 'bundler'
Bundler.require :default
require File.expand_path('../models/post', __FILE__)

# Running this file will create/update/delete records for demonstration purposess.

module Changer
  extend self

  def change action = nil
    @index = index + 1
    send action || [:create, :update, :destroy].sample
  end

  def create
    post = Post.create content: "Post ##{index}"
    puts "[Model]  Created ##{post.id}"
  end

  def update
    with_random_post 'Updated' do |post|
      post.increment! :update_count
    end
  end

  def destroy
    with_random_post('Deleted') { |post| post.destroy }
  end

  private

  def index; @index || 0 end

  def with_random_post action
    if post = Post.offset(rand(Post.count)).first
      yield post
      puts "[Model]  #{action} ##{post.id}"
    end
  end
end

Post.delete_all
5.times { Changer.change :create }
loop    { Changer.change; sleep 1 }
