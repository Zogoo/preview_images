module Client
  module Error
    class InvalidResponseContent < StandardError; end
    class InvalidResponse < StandardError; end
    class WrongInput < StandardError; end
  end
end
