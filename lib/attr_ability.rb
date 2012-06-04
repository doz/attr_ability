require "attr_ability/version"

module AttrAbility
end

if defined?(Rails::Railtie)
  require "attr_ability/railtie"
elsif defined?(Rails::Initializer)
  raise "Sorry, attr_ability is not compatible with Rails 2.3 or older"
end
