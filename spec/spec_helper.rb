require 'active_record'
require 'action_controller'
require 'cancan'
require 'with_model'
require 'attr_ability/model_additions'
require 'attr_ability/controller_additions'

RSpec.configure do |config|
  config.extend WithModel

  ActiveRecord::Base.send :include, AttrAbility::ModelAdditions
  ActionController::Base.send :include, AttrAbility::ControllerAdditions

  ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
end
