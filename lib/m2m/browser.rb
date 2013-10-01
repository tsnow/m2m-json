module M2m
  module Browser
    def m2m_known_events
      ::M2m.transitions.map{|i| [i.from, i.to]}.flatten.compact.sort.uniq
    end
    def m2m_known_inputs
      ::M2m.data.keys + (::M2m.actions.values.map{|i| i['inputs'] && i['inputs']['id'] || nil}.flatten)
    end
    def m2m_registered_handlers
      ::M2m.transitions.map{|i| i.handler_signature}.group_by{|i| i.name}
    end
    def m2m_event(from,to=nil)
      ::M2m.event(from,to)
    end
    def m2m_reset(json=nil)
      ::M2m.reset(json)
    end
    def m2m_interpret(json)
      ::M2m.interpret(json)
    end
    def m2m_data
      ::M2m.data
    end
  end
end
