require "attr_ability/controller_resource"

module AttrAbility
  module ActionController
    def cancan_resource_class
      AttrAbility::ControllerResource
    end
  end
end