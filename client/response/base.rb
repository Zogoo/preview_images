module Client
  module Response
    # Base model for response
    class Base
      def define_methods(fields)
        fields.each do |name, value|
          define_singleton_method(name) do
            instance_variable_get("@#{name}")
          end
          define_singleton_method("#{name}=") do |val|
            instance_variable_set("@#{name}", val)
          end
          assign_value(name, value)
        end
      end

      def assign_value(name, value)
        send "#{name}=", value
      end

      def self.load_dynamically(json)
        obj = new
        obj.define_methods(json)
        obj
      end
    end
  end
end
