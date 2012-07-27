require "attr_ability/attributes"

module AttrAbility
  module Model
    class Sanitizer
      def initialize(ability)
        @ability = ability
      end

      def sanitize(model, new_attributes)
        return {} unless @ability && new_attributes.present?
        attributes = new_attributes.stringify_keys
        temp_model = model.class.new
        model.attributes.each do |attr, value|
          temp_model[attr] = value unless attributes.include?(attr)
        end
        temp_model.assign_attributes(attributes, without_protection: true)
        authorized_attributes = authorized_attributes_for(temp_model)
        attributes.select { |attribute, value| authorized_attributes.allow?(attribute, value) }
      end

      def authorized_attributes_for(model)
        authorized_attributes = AttrAbility::Attributes.new
        model.class.attribute_abilities.each do |action, attributes|
          authorized_attributes.add(attributes) if @ability.can?(action, model)
        end
        authorized_attributes
      end
    end
  end
end