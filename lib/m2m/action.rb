module M2m
  class Form
    attr_accessor :strategy, :uri, :form_method, :enctype
    def initialize(action_json)
      @json = action_json
      self.uri = self['uri']
      self.strategy = self['strategy']
      self.form_method = self['method']
      self.enctype = self['enctype']
    end
    def [](field)
      @json[field]
    end
    def fields
      return @field_hash if @field_hash
      self.field_hash do |input|
        input['name'],  self.data(input['id']) || input['value']
      end
    end
    private
    def inputs
      return [] if self['inputs'].blank?
    end
    def data(id)
      return nil if id.nil?
      ::M2m.data[id]
    end
    def field_hash
      @field_hash = Hash[self.inputs.map{|i| key, value = yield i; [key,value] }]
    end
  end
end
