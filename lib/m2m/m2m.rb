module M2m
  def self.event(to_name, from_name=nil)
    M2m::Event.new(to_name,from_name).fire_transitions
  end
  class << self
    attr_accessor :transitions
    attr_accessor :actions
    attr_accessor :data
  end
  def self.reset(json=nil)
    self.transitions = []
    self.actions={}
    self.data={}
    interpret(json) if json
  end
  self.reset
  
  def self.interpret(json)
    jq=JsonQuery.new(json)
    jq.transitions(:unset => true).each do |i|
      self.transitions.reject!{|j| j['when'] == i['when'] && j['action'] == i['action']}
    end
    jq.transitions.each do |i|
      self.transitions.push(Transition.new(i))
    end

    jq.actions.each do |i|
      self.actions[i['id']] = i
    end
    
    self.data.merge!(jq.data)
    
    jq.transitions(:now => true) do |i|
      Transition.new(i).fire
    end
    json
  end
  
  private
  class JsonQuery
    def initialize(json)
      @json = json['m2m'] || {}
    end
    def transitions(opts={})
      opts = {:now => false, :unset => false}.merge(opts)
      return [] if json['transitions'].blank?
      if now
        json['transitions'].select{|i| i['when'] == 'now'}
      else
        json['transitions'].reject{|i| i['when'] == 'now'}
      end
    end
    def actions
      return [] if json['actions'].blank?
      json['actions'].select{|i| i['id']}
    end
    def data
      return {} if json['data'].blank?
      json['data']
    end
  end
  
end
