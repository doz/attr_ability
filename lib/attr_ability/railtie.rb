
module AttrAbility
  class Railtie < Rails::Railtie
    initializer "attr_ability.active_record" do |app|
      require "attr_ability/active_record"
      ActiveSupport.on_load :active_record do
        include AttrAbility::ActiveRecord
      end
    end

    initializer "attr_ability.active_record" do |app|
      require 'attr_ability/action_controller'
      ActiveSupport.on_load :action_controller do
        extend AttrAbility::ActionController
      end
    end
  end
end
