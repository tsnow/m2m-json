module M2m
  class Event
    def initialize(to_name,from_name)
      @transitions = ::M2m.transitions.select{|i| i.from == from_name && i.to == to_name}
    end
    def fire_transitions
      @transitions.map(&:fire)
    end
  end
end
