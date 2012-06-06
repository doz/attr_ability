require "attr_ability/controller/controller_resource"

module AttrAbility
  module ControllerAdditions
    def cancan_resource_class
      AttrAbility::Controller::ControllerResource
    end
  end
end