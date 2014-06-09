require 'm2m/document/dsl'
require 'm2m/document/dsl/states_accumulator'

# A DSL for JSON document Generation.
module M2m
  class Document
    attr_accessor :transitions, :actions,:save
    include DSL #self.transition, self.storage(args)
    def initialize
      @transitions = []
      @actions = []
      @save = {}
    end
    def update_saves(args)
      return if args.empty?
      @save.merge!(args)
    end
    def new_transition(t)
      @transitions.push(t)
    end
    def new_action(a)
      @actions.push(a)
    end

    def self.states
      @states_accumulator ||= DSL::StatesAccumulator.new
      @states_accumulator
    end
  end


    
