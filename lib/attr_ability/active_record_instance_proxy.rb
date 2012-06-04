module AttrAbility
  class ActiveRecordInstanceProxy
    instance_methods.each { |m| undef_method m unless m =~ /(^__|^send$|^object_id$)/ }

    def initialize(model, sanitizer)
      @model = model
      @sanitizer = sanitizer
    end

    protected

    def method_missing(name, *args, &block)
      @model.mass_assignment_sanitizer = @sanitizer
      @model.send(name, *args, &block)
    ensure
      @model.mass_assignment_sanitizer = nil
    end
  end
end
