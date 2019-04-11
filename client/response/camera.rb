require './client/response/base.rb'

module Client
  module Response
    # Single camera model for camera list
    class Camera < Base
      attr_accessor :account_id, :camera_id, :name, :type, :serial_number

      def define_methods(fields)
        super({
          'account_id': fields[0],
          'camera_id': fields[1],
          'name': fields[2],
          'type': fields[3],
          'serial_number': fields[9]
        })
      end
    end
  end
end
