require 'cancan'

module AttrAbility
  class ControllerResource < CanCan::ControllerResource
    def resource_base
      super.as(current_ability)
    end

    def load_resource_instance
      super.as(current_ability)
    end
  end
end