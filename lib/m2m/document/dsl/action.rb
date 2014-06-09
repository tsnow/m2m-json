=begin
class ToggleBackgroundColorAction #=> document.transitions[]["handler"] = "ToggleBackgroundColor"
      def initialize(color_name)
        @color_name = color_name
      end
      def update_m2m_action(action)
        action.input("background.color", :value => @color_name.to_s)
        #=> jq: .actions + ([{} | .inputs + [ { name : "background.color", value : "#{@color_name.to_s}"}]])
      end
end
=end
module M2m
  class Document
    module DSL
      class Action
        def initialize(name,helper)
          @json = {"id" => name}
          @helper = helper
        end
        def inputs
          @json["inputs"] ||= []
          @json["inputs"]
        end
        def input(field_name, args={})
          inputs.push({"name" => field_name}).merge(args.stringify_keys)
        end
        def uri=(uri)
          @json["uri"] = uri
        end
        #private
        def update_m2m_document(document)
          @helper.update_m2m_action(self)
          document.new_action(@json)
        end
      end
    end
  end
end
