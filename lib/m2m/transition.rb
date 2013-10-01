module M2m
  class Transition
    attr_accessor :when, :handler_name, :action_name
    def initialize(json)
      @json = json
      self.when = self['when']
      self.handler_name = self['handler']
      self.action_name= self['action']
    end
    def from
      self.when && self.when['from']
    end
    def to
      self.when && self.when['to']
    end
    def [](field)
      @json[field]
    end
    def handler_signature
      first, rest = self.handler_name.split(" ")
      HandlerSignature.new(first,rest)
    end
    class HandlerSignature < String
      attr_accessor :args
      def initialize(name,args)
        @args = args
        super(name)
      end
      def to_s
        @args.inspect
      end
      def inspect
        "#{name}:#{@args.inspect}"
      end
    end
    
    def get_handler
      first, rest = self.handler_name.split(" ")
      Proc.new{|form|
        const_get("::#{first}").call(form,*rest)
      }
    end
    def get_action
      ::M2m.actions[self.action_name]
    end
    def fire
      @result = self.get_handler[Form.new(self.get_action)]
      self
    end
    def result
      @result
    end
  end
end
