require 'bundler'
Bundler.require :default
require File.expand_path('../models/post', __FILE__)

class App < Sinatra::Base
  stream '/stream/posts'

  on :open do |channel, _|
    puts "[Stream] Client connected to #{channel}"
  end

  on :message do |channel, message, out|
    puts "[Stream] Received ##{JSON.parse(message)['id']} on #{channel}"
  end

  on :close do |channel|
    puts "[Stream] Client disconnected from #{channel}"
  end

  get '/' do
    File.read File.join(settings.root, 'public', 'index.html')
  end
end

App.run!
