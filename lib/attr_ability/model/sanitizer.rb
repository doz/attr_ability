module AttrAbility
  module Model
    class Sanitizer
      def initialize(ability)
        @ability = ability
      end

      def sanitize(model, new_attributes)
        return {} unless @ability && new_attributes.present?
        attributes = new_attributes.stringify_keys
        authorized_attributes = authorized_attributes_for(model.class.new(model.attributes.merge(attributes), without_protection: true))
        attributes.select do |attribute, value|
          authorized_attributes[attribute] == true || authorized_attributes[attribute].include?(value)
        end
      end

      def authorized_attributes_for(model)
        Hash.new([]).tap do |authorized_attributes|
          model.class.attribute_abilities
            .map { |action, attributes| attributes if @ability.can?(action, model) }
            .compact.flatten.each do |attribute_or_hash|
              if attribute_or_hash.is_a?(Hash)
                attribute_or_hash.each do |attribute, values|
                  if authorized_attributes[attribute] != true
                    authorized_attributes[attribute.to_s] += Array(values)
                  end
                end
              else
                authorized_attributes[attribute_or_hash.to_s] = true
              end
            end
        end
      end
    end
  end
end