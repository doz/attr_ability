module AttrAbility
  class Railtie < Rails::Railtie
    initializer "attr_ability.model_additions" do |app|
      require "attr_ability/model_additions"
      ActiveSupport.on_load :active_record do
        include AttrAbility::ModelAdditions
      end
    end

    initializer "attr_ability.controller_additions" do |app|
      require 'attr_ability/controller_additions'
      ActiveSupport.on_load :action_controller do
        extend AttrAbility::ControllerAdditions
      end
    end
  end
end
