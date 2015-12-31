require "rack"
require "rack/reverse_proxy"
require "uri"

class Config
  attr_reader :uri, :basic_auth_username, :basic_auth_password, :delete_cache_headers

  def initialize
    @uri = get_uri_from_env
    @basic_auth_username, @basic_auth_password = get_basic_auth_from_env
    @delete_cache_headers = get_delete_cache_headers_from_env
  end

  def base_uri
    "#{uri.scheme}://#{uri.host}/"
  end

  def use_basic_auth?
    basic_auth_username != nil
  end

  def describe
    format_str = <<-END
Proxy URL:            %s
Basic auth:           %s
Delete cache headers: %s
    END
    sprintf(
      format_str,
      @uri,
      @basic_auth_username ? "#{@basic_auth_username}:#{@basic_auth_password}" : false,
      @delete_cache_headers)
  end

  private

  def get_uri_from_env
    URI.parse(ENV.fetch("RPROXY_URL", "https://dl.dropboxusercontent.com/u/1404049/"))
  end

  def get_basic_auth_from_env
    ENV.fetch("RPROXY_BASIC_AUTH", "uname:passwd").split(":", 2)
  end

  def get_delete_cache_headers_from_env
    !!(ENV["RPROXY_DELETE_CACHE_HEADERS"] =~ /1|(?:true)/)
  end
end

class DumpHeaders
  def initialize(app, options = {})
    @app = app
    @delete_cache_headers = options.fetch(:delete_cache_headers)
  end

  def call(env)
    dump_http_headers("> ", env.select { |key, _| key =~ /HTTP_/ })
    status, headers, response = @app.call(env)
    delete_cache_headers(headers) if @delete_cache_headers
    dump_http_headers("< ", headers)
    [status, headers, response]
  end

  def dump_http_headers(prefix, headers)
    headers.each do |key, value|
      puts "#{prefix}#{key}: #{value}"
    end
  end

  def delete_cache_headers(headers)
    headers.delete_if do |key, _|
      key =~ /^(?:etag|modified-since)/i
    end
  end
end

config = Config.new

$stdout.puts config.describe

app = ->(_) { [404, {'Content-Type' => 'text/plain'}, ["not reverse proxied"]] }

stack = Rack::Builder.new do
  use Rack::CommonLogger
  use DumpHeaders, delete_cache_headers: config.delete_cache_headers

  if config.use_basic_auth?
    use Rack::Auth::Basic, "RProxy Realm" do |username, password|
      username == config.basic_auth_username && password == config.basic_auth_password
    end
  end

  use Rack::ReverseProxy do
    reverse_proxy(config.uri.path, config.base_uri)
  end

  use Rack::ShowExceptions

  run app
end

Rack::Handler::WEBrick.run(stack, Port: 8080)
