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
          if sanitizer == :system
            # System access - do not filter anything regardless of protection in use
            attributes
          elsif self.class.attribute_abilities
            # At least one ability is defined for the model - sanitize with AttrAbility
            sanitizer ? sanitizer.sanitize(self, attributes) : {}
          else
            # No abilities defined - failback to attr_accessible
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
        if ability.is_a?(AttrAbility::Model::Sanitizer) || ability == :system
          ability
        else
          AttrAbility::Model::Sanitizer.new(ability)
        end
      end

      protected

      def ability(action, attributes)
        (self.attribute_abilities ||= {})[action] = attributes
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
