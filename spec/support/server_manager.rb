require 'rbconfig'
require 'open-uri'
require 'net/http'
require 'timeout'

class ServerManager # Kindly "borrowed" from the Sinatra folks
  attr_accessor :port, :pipe

  def app_file
    File.expand_path('../app.rb', __FILE__)
  end

  def initialize(port)
    @pipe, @port = nil, port
  end

  def run
    kill
    @log     = ""
    @pipe    = IO.popen(command)
    @started = Time.now
    puts "Server up and running" if ping
    at_exit { kill }
  end

  def ping(timeout = 30)
    loop do
      return if alive?
      if Time.now - @started > timeout
        $stderr.puts command
        fail "timeout"
      else
        sleep 0.1
      end
    end
  end

  def alive?
    3.times { get('/ping') }
    true
  rescue Errno::ECONNREFUSED, Errno::ECONNRESET, EOFError, SystemCallError, OpenURI::HTTPError, Timeout::Error
    false
  end

  def get_stream(url = "/stream", &block)
    Net::HTTP.start '127.0.0.1', port do |http|
      request = Net::HTTP::Get.new url
      http.request request do |response|
        response.read_body(&block)
      end
    end
  end

  def get(url)
    Timeout.timeout(1) { open("http://127.0.0.1:#{port}#{url}").read }
  end

  def command
    @command ||= begin
      cmd = ["exec", RbConfig.ruby.inspect]
      cmd << "-I" << File.expand_path('../../lib', __FILE__).inspect
      cmd << app_file.inspect << '-o' << '127.0.0.1' << '-p' << port << '2>&1'
      cmd.join " "
    end
  end

  def kill
    return unless pipe
    Process.kill("KILL", pipe.pid)
  rescue NotImplementedError
    system "kill -9 #{pipe.pid}"
  rescue Errno::ESRCH
  end
end
