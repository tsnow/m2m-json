require 'm2m/document/dsl/action'
require 'm2m/document/dsl/transition'

module M2m
  class Document
    module DSL

      # See dsl/transition.rb for example
      def transition
        DSL::Transition.new(self)
      end

      # Example:
      # M2m::Document.new.storage("rocket" => "lift_off")
      # => jq: .save + { rocket: "lift_off"})
      def storage(args)
        self.update_saves(args)
      end
    end
  end
end
