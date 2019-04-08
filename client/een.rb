require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
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

    def get_images(image_count, camera_id, timestamp = 'now', asset_class = 'pre')
      responses = get_multiple(IMAGE_PATH, image_count, {
        id: camera_id,
        timestamp: timestamp,
        asset_class: asset_class
      })
      responses.each do |rsp|
        next unless rsp.success?
        begin
          file = File.open("output/#{camera_id}-image-#{Time.now.to_f}.jpeg", "wb")
          file.write(rsp.body)
        rescue IOError => e
          'Could not write into file'
        ensure
          file.close unless file.nil?
        end
      end
    end

    # GET request with api key
    def get(end_point, params = nil)
      response = connection.get do |req|
        req.url end_point
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authentication'] = ENV['API_KEY'] unless ENV['API_KEY'].nil?
        req.headers['Cookie'] = cookie
        req.params = params unless params.nil?
      end
      raise Client::Error::InvalidResponse, "Error code with :  #{response.status}" unless response.success?

      validate_as_json(response.body)
    end

    # POST request with api key
    def post(end_point, body = nil)
      response = connection.post do |req|
        req.url end_point
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authentication'] = ENV['API_KEY'] unless ENV['API_KEY'].nil?
        req.body = body&.to_json
      end
      self.cookie = response.headers['set-cookie'] unless response.headers['set-cookie'].nil?
      raise Client::Error::InvalidResponse, "Error code with :  #{response.status}" unless response.success?

      validate_as_json(response.body)
    end

    # Get multiple request as concurrently
    def get_multiple(end_point, req_number, params = nil)
      switch_concurrent_connection
      responses = []
      connection.in_parallel do
        req_number.times do |n_req|
          responses << connection.get do |req|
            req.url end_point
            req.headers['Authentication'] = ENV['API_KEY'] unless ENV['API_KEY'].nil?
            req.headers['Cookie'] = cookie
            req.params = params unless params.nil?
          end
        end
      end
      responses
    end

    def switch_concurrent_connection
      manager = Typhoeus::Hydra.new(:max_concurrency => ENV['CONCURENCY_LIMIT'].to_i)
      self.connection = Faraday.new(url: branding_subdomain, :parallel_manager => manager) do |faraday|
        faraday.adapter :typhoeus
        faraday.request  :url_encoded
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
