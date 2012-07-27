module AttrAbility
  class Attributes
    attr_reader :attributes

    def initialize
      @attributes = Hash.new([])
    end

    def add(attributes)
      normalized = attributes.is_a?(AttrAbility::Attributes) ? attributes.attributes : normalize(attributes)
      normalized.each do |attribute, values|
        if @attributes[attribute] != true
          if values == true
            @attributes[attribute] = true
          else
            @attributes[attribute] = (@attributes[attribute] + values).uniq
          end
        end
      end
    end

    def allow?(attribute, value)
      @attributes[attribute.to_s] == true || @attributes[attribute.to_s].include?(value.to_s)
    end

    private

    def normalize(attributes)
      Hash[
        attributes.map do |attribute_or_hash|
          if attribute_or_hash.is_a?(Hash)
            attribute_or_hash.map do |attribute, values|
              [attribute.to_s, Array(values).map(&:to_s)]
            end
          else
            [[attribute_or_hash.to_s, true]]
          end
        end.flatten(1)
      ]
    end
  end
end