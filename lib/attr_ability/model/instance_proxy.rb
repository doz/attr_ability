module AttrAbility
  module Model
    module InstanceProxy
      @@initialization_mutex = Mutex.new

      def self.[](klass)
        @@initialization_mutex.synchronize do
          @_proxy_classes ||= {}
          @_proxy_classes[klass] ||= Class.new do
            include ProxyMethods
          end
        end
      end

      module ProxyMethods
        extend ActiveSupport::Concern

        included do
          alias __proxy_class__ class
          instance_methods.each { |m| undef_method m unless m =~ /(^__|^send$|^object_id$|^initialize$|^method_missing$)/ }
        end

        def initialize(model, sanitizer)
          @model = model
          @sanitizer = sanitizer
        end

        protected

        def method_missing(name, *args, &block)
          delegate_method(name)
          self.send(name, *args, &block)
        end

        private

        def delegate_method(name)
          __proxy_class__.class_eval <<-METHOD, __FILE__, __LINE__ + 1
            def #{name}(*args, &block)
              @model.mass_assignment_sanitizer = @sanitizer
              @model.#{name}(*args, &block)
            ensure
              @model.mass_assignment_sanitizer = nil
            end
          METHOD
        end
      end
    end
  end
end
