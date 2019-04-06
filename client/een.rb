require 'faraday'
require 'json'
require 'dotenv/load'
require 'logger'
require 'byebug'

module Client
  # Eagle eye rest api client
  class Een
    attr_accessor :connection, :token, :subdomain, :cookie

    DEFAULT_HOST = "#{ENV['PROTOCOL']}://#{ENV['DEFAULT_SUBDOMAIN']}.#{ENV['HOST']}".freeze
    AUTHENTICATE_PATH = '/g/aaa/authenticate'.freeze
    AUTHORIZE_PATH = '/g/aaa/authorize'.freeze
    CAMERA_LIST_PATH = '/g/device/list'.freeze
    IMAGE_PATH = '/asset/asset/image.jpeg'.freeze

    def initialize
      log = Logger.new(ENV['LOG_FILE_NAME'])
      log.level = Logger::DEBUG

      self.connection = Faraday.new(url: DEFAULT_HOST) do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger, log
        faraday.adapter  Faraday.default_adapter
      end
    end

    def authenticate
      resp = post(AUTHENTICATE_PATH, username: ENV['USER_NAME'], password: ENV['PASSWORD'])
      obj = Response::Authenticate.load_dynamically(resp)
      self.token = obj.token
      obj
    end

    def authorize
      rsp = post(AUTHORIZE_PATH, token: token)
      obj = Response::User.load_dynamically(rsp)
      self.subdomain = obj.active_brand_subdomain
      obj
    end

    def camera_list
      rsp = get(CAMERA_LIST_PATH)
      rsp.map do |rs|
        Response::Camera.load_dynamically(rs)
      end
    end

    def get_image(camera_id, timestamp = 'now', asset_class = 'pre')
      rsp = get(IMAGE_PATH, id: camera_id, timestamp: timestamp, asset_class: asset_class)
      File.open("output/#{camera_id}-image-#{Time.now}.jpeg", 'wb') { |fp| fp.write(rsp.body) }
    end

    # GET request with api key
    def get(end_point, options = nil)
      response = connection.get do |req|
        req.url end_point
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authentication'] = ENV['API_KEY'] unless ENV['API_KEY'].nil?
        req.headers['Cookie'] = cookie
        req.body = options
      end
      raise Client::Error::InvalidResponse, "Error code with :  #{response.status}" unless response.success?

      validate_as_json(response.body)
    end

    # POST request with api key
    def post(end_point, options = nil)
      response = connection.post do |req|
        req.url end_point
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authentication'] = ENV['API_KEY'] unless ENV['API_KEY'].nil?
        req.body = options.to_json
      end
      self.cookie = response.headers['set-cookie'] unless response.headers['set-cookie'].nil?
      raise Client::Error::InvalidResponse, "Error code with :  #{response.status}" unless response.success?

      validate_as_json(response.body)
    end

    def subdomain_connection
      self.connection = Faraday.new(url: branding_subdomain) do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger, log
        faraday.adapter  Faraday.default_adapter
      end
    end

    def branding_subdomain
      "#{ENV['PROTOCOL']}://#{subdomain}.#{ENV['HOST']}"
    end

    # Not fail with library error
    def validate_as_json(response)
      JSON.parse(response)
    rescue JSON::NestingError
      raise Client::Error::InvalidResponseContent, 'Too deep response'
    rescue JSON::ParserError
      raise Client::Error::InvalidResponseContent, 'Unexpected response'
    rescue JSON::MissingUnicodeSupport
      raise Client::Error::InvalidResponseContent, 'Invalid character in response'
    rescue JSON::UnparserError
      raise Client::Error::InvalidResponseContent, 'Unable to parse response'
    rescue JSON::JSONError
      raise Client::Error::InvalidResponseContent, 'Invalid response'
    end
  end
end
