require 'thin'
require 'streaming'

class App < Sinatra::Base
  set :port, 5000

  stream '/stream'

  get '/ping' do
    'pong'
  end
end

Rack::Handler::Thin.run App, Port: 5000
