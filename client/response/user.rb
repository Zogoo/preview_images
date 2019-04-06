module Client
  module Response
    # Authorize response
    class User < Base
      attr_accessor :email, :camera_access, :active_brand_subdomain
    end
  end
end
