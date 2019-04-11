require './client/response/base.rb'

module Client
  module Response
    # Authenticate response
    class Authenticate < Base
      attr_accessor :token
    end
  end
end
