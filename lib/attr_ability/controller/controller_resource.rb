require 'cancan'

module AttrAbility
  module Controller
    class ControllerResource < CanCan::ControllerResource
      def load_resource_instance
        super.as(current_ability)
      end

      protected

      def build_resource
        resource = resource_base.new.as(current_ability)
        resource.send("#{parent_name}=", parent_resource) if @options[:singleton] && parent_resource
        initial_attributes.each do |attr_name, value|
          resource.send("#{attr_name}=", value)
        end
        resource.attributes = @params[name] if @params[name].present?
        resource
      end
    end
  end
end