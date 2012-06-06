module AttrAbility
  module Model
    class ClassProxy
      instance_methods.each { |m| undef_method m unless m =~ /(^__|^send$|^object_id$)/ }

      def initialize(klass, sanitizer)
        @klass = klass
        @sanitizer = sanitizer
      end

      def new(attributes = nil, options = {})
        @klass.new.as(@sanitizer).tap do |object|
          object.assign_attributes(attributes, options) if attributes
          yield(object) if block_given?
        end
      end

      def create(attributes = nil, options = {}, &block)
        if attributes.is_a?(Array)
          attributes.collect { |attr| create(attr, options, &block) }
        else
          new(attributes, options).tap do |object|
            yield(object) if block_given?
            object.save
          end
        end
      end

      def create!(attributes = nil, options = {}, &block)
        if attributes.is_a?(Array)
          attributes.collect { |attr| create(attr, options, &block) }
        else
          new(attributes, options).tap do |object|
            yield(object) if block_given?
            object.save!
          end
        end
      end

      protected

      def method_missing(name, *args, &block)
        @klass.send(name, *args, &block)
      end
    end
  end
end