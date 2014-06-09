=begin

@m2m.transition.now["FirstOpen"]=M2m::Stdlib::StateTransitionAction.new(:first_open)
    #=> jq: .transitions + ([{when: "now", action: "FirstOpen", handler: "StateTransition"}])
    #=> jq: .actions + ([{id: "FirstOpen"} | (#See action.rb for Action output)])

@m2m.transition.to(:first_open)["PopupWelcome"]=
              PopupAction.new("Congratulations, ", :'user.name', " on your first M2M Api request.")
    #=> jq: .transitions + ([{when: {to: "FIRST_OPEN", action: "PopupWelcome", handler: "Popup"}])
    #=> jq: .actions + ([{id: "PopupWelcome"} | (#See action.rb for Action output)])
=end

module DSL
      class Transition
        def initialize(document)
          @document=document
          @when ={}
          @action_name = ""
          @action=nil
          @transition_name = ""
        end
        def to(state_name)
          @when = {}
          @when['to']=case state_name
                      when String then
                        state_name
                      when Symbol then
                        ::M2m::Document.states[state_name]
                      else
                        raise ArgumentError, "Transition#to(#{state_name.inspect}) only accepts strings and symbols"
                      end
          self
        end
        def now
          @when = "now"
          self
        end
        def []=(action_name, action)
          @action_name=action_name.to_s
          @action = action
          update_m2m_document(@document)
          self
        end
        ## private
        def handler_name
          return @action.handler_name if @action.respond_to?(:handler_name)
          @action.class.to_s.split("::").last.sub(/Action$/,'')
        end
        def update_m2m_document(document)
          document.new_transition("when" => @when, "action" => @action_name, "handler" => self.handler_name)
          Action.new(@action_name,@action).update_m2m_document(document)
        end
      end
    end
  end
end
