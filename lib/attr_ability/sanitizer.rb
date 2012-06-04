module AttrAbility
  class Sanitizer
    def initialize(ability)
      @ability = ability
    end

    def sanitize(model, attributes)
      return {} unless @ability && attributes.present?
      sample = model.class.new
      sample.assign_attributes(model.attributes.merge(attributes), without_protection: true)
      authorized_attributes = model.class.attribute_abilities
        .map { |action, attributes| attributes if @ability.can?(action, sample) }
        .compact.flatten.uniq
      attributes.select { |attribute, value| authorized_attributes.include?(attribute) }
    end
  end

  class SystemSanitizer < Sanitizer
    def initialize
    end

    def sanitize(model, attributes)
      return attributes
    end
  end
end