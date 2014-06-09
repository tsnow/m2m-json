
=begin

M2m::Document.states do
 state.first_open "FIRST_OPEN", :ephemeral
 state.slider_off "SliderOff", :client
 state.slider_on  "SliderOn", :client
end

M2m::Document.states[:first_open] #=> "FIRST_OPEN"
M2m::Document.groups(:ephemeral) #=> {:first_open => "FIRST_OPEN"}
=end

module M2m
  class Document
    module DSL

      class State
        def initialize(acc)
          @acc =acc
        end
        def method_missing(*args,&block)
          key,name,rest = *args
          return @acc.add(:"#{key}", name,*rest) unless name.nil?
          super(*args,&block)
        end
      class StatesAccumulator
        def initialize
          @states = {}
          @groups = {}
        end
        def state
          State.new(self)
        end
        
        def [](key)
          @states[key]
        end
        def fetch(key,val,&block)
          return @states.fetch(key,val,&block) if block_given?
          @states.fetch(key,val)
        end
        def groups
          @groups
        end
        #private
        def add(key,val,group)
          @states[key] = val
          @groups[group] ||= {}
          @groups[group][key] = val
          self
        end
      end
    end
  end
end
