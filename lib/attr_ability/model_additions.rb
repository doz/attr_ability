require "attr_ability/model/instance_proxy"
require "attr_ability/model/class_proxy"
require "attr_ability/model/sanitizer"

module AttrAbility
  module ModelAdditions
    def self.included(base)
      base.class_eval do
        class_attribute :attribute_abilities
        class_attribute :mass_assignment_sanitizer
        attr_accessor :mass_assignment_sanitizer
        extend ClassMethods

        alias_method :original_assign_attributes, :assign_attributes
        alias_method :original_sanitize_for_mass_assignment, :sanitize_for_mass_assignment

        def assign_attributes(attributes, options = {})
          original_assign_attributes(attributes, options.reverse_merge(sanitizer: mass_assignment_sanitizer))
        end

        protected

        def sanitize_for_mass_assignment(attributes, role = :default)
          sanitizer = mass_assignment_options[:sanitizer]
          if self.class.attribute_abilities || sanitizer.is_a?(AttrAbility::Model::SystemSanitizer)
            sanitizer ? sanitizer.sanitize(self, attributes) : {}
          else
            original_sanitize_for_mass_assignment(attributes, role)
          end
        end
      end unless base.method_defined?(:attribute_abilities)
    end

    module ClassMethods
      def as(ability)
        AttrAbility::Model::ClassProxy.new(self, build_sanitizer(ability))
      end

      def as_system
        as(:system)
      end

      def build_sanitizer(ability)
        if ability.is_a?(AttrAbility::Model::Sanitizer)
          ability
        elsif ability == :system
          AttrAbility::Model::SystemSanitizer.new
        else
          AttrAbility::Model::Sanitizer.new(ability)
        end
      end

      protected

      def ability(action, attributes)
        (self.attribute_abilities ||= {})[action] = attributes.map(&:to_s)
      end
    end

    def as(ability)
      AttrAbility::Model::InstanceProxy.new(self, self.class.build_sanitizer(ability))
    end

    def as_system
      as(:system)
    end
  end
end
