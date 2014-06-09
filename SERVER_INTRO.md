## Server Intro and Tutorial

## Client Tutorial and Explanation

Let's say you have an iPhone application, with a main page which has on it a slider.

Sliding the slider to the "ON" state should change the color of the background to green,
sliding the slider to the "OFF" state should change the color of the background back to white.

You'd like the app to show a popup on start, with a welcome message, and a link to your website.

_See Client Tutorial for client side coding_.

Picking up where the client left off:

So you build a webservice, and have the app make a webservice call on startup.

``` ruby
#test/api_test.rb
require 'test/unit'

class ApiTest < Test::Unit::TestCase
  def test_welcome
    json = nil
    assert_no_raise do
     json = JSON.parse(Net::Http.get("http://sliderapp.com/welcome").body)
    end
    assert_equal [false, "Congratulations, on your first resourceful JSON request."],[json.nil?, json && json['message']]
  end
end

#server.rb
require 'sinatra'
get '/welcome' do
  JSON.generate("message" => "Congratulations, on your first resourceful JSON request.")
end
```

Next you'd like to change the background color for some of the apps, so you extend the webservice to do that too, 
on both the client and the server.

``` ruby
#server.rb
require 'sinatra'
get '/welcome' do
  #JSON.generate("message" => "Congratulations, on your first resourceful JSON request.")
  resp = {
    "message" => "Congratulations, on your first resourceful JSON request.",
    "color" => "blue",
  }
  JSON.generate(resp)
end
```

Then you decide that when they click the link, they should be shown a thank you popup.

So you think: "Wait a second. Some times when I want to change the behaviour of my app, 
I have to change the application code. I can fix that by following good coding practices and
making flexible interfaces ahead of time. 
For instance, I could have had some sort of application state
repository, 



like a more general form of the ColorState class, from the start. 
I could then update that with my webservice calls, and pull configuration from it in my Application code.

But everytime I want to specify something new via the server, I'd still need to change BOTH the server code, 
AND my webservice client code to add new communication behaviour, even though sometimes, like for the DisplayPopup case,
I don't have to change any of my App-tier code.

I need to make the _client-server_ interface itself more flexible."

So you do something new:

You introduce an application-wide data store, which is open to both the webservice, and your application.


``` ruby
#server.rb
gem 'sinatra'
gem 'm2m-json'
require 'sinatra'
require 'm2m/document'

configure do
 mime_type :m2m, "vnd.application/json+m2m"
 mime_type :json, "application/json"
end

helpers do
 def old_welcome_json
  #JSON.generate("message" => "Congratulations, on your first resourceful JSON request.")
  resp = {
    "message" => "Congratulations, on your first resourceful JSON request.",
    "color" => "blue",
  }
  JSON.generate(resp)
 end
end

M2m::Document.states do
 state.first_open "FIRST_OPEN", :ephemeral
 state.slider_off "SliderOff", :client
 state.slider_on  "SliderOn", :client
end


class M2m::Stdlib::StateTransitionAction
  def initialize(state_name)
     @state = M2m.known_states[state_name]
  end
  def update_m2m_action(action)
     action.uri = "state://#{@state}"
  end
end

class ToggleBackgroundColorAction
      def initialize(color_name)
        @color_name = color_name
      end
      def update_m2m_action(action)
        action.input("background.color", :value => @color_name.to_s)
      end
end

class PopupAction 
      include M2m::Stdlib::Template
      def initialize(*message)
        @message = templatize(message)
      end
      def update_m2m_action(action)
        action.input("message", :value => @message)
      end
end

class WelcomeM2m
  def initialize(m2m = M2m::Document.new)
    @m2m = m2m
    @m2m.transition.now["FirstOpen"]=M2m::Stdlib::StateTransitionAction.new(:first_open)
    @m2m.transition.to(:first_open)["PopupWelcome"]=
              PopupAction.new("Congratulations, ", :'user.name', " on your first M2M Api request.")
    @m2m.transition.to(:slider_on)["BackgroundGreen"]=ToggleBackgroundColorAction.new(:green) 
    @m2m.transition.to(:slider_off)["BackgroundWhite"]=ToggleBackgroundColorAction.new(:white) 
    @m2m.storage(:'user.id' => '10', :'user.name' => "Dave Wehadababyistaboy")
  end
  def to_json
    JSON.generate(@m2m)
  end
end

get '/welcome' do
  if request.accept?("vnd.application/json+m2m")
     content_type :m2m
     WelcomeM2m.new.to_json
  else
     content_type :json
     old_welcome_json
  end
end
```


``` ruby
require 'm2m'
m2m_set_data( 'background.color' => 'green', 'background.off.color' => 'white')
#ColorState = {:on_color => "green"}
```

You introduce an event callback system, so that events can be triggered by either user input, or the webservice.
``` ruby
def slide_to_on
  m2m_event "SliderOn"
end

def slide_to_off
  m2m_event "SliderOff"
end

def popup_closed
  m2m_event "PopupClosed"
end

def click_link
  m2m_event "WelcomeLinkClicked"
end

M2m.events["SliderOn"] = [Proc.new{ SliderApp::Display.change_color(m2m_data 'background.color')}]
M2m.events["SliderOff"] = [Proc.new{ SliderApp::Display.change_color(m2m_data 'background.off.color')}]

```

And you come up with a json representation for representing events, callbacks, and key-value data; 
so that you can drive as much of the application state as you'd like from the webservice.

You make a new media type for it, so your old apps in the field, who haven't updated yet, won't recieve the new format.

``` ruby
def webservice_json
  begin
   json = JSON.parse(Net::Http.get("http://sliderapp.com/welcome",{},{'Content-type' => "vnd.application/json+m2m"}).body)
   #message = json['message']
   #ColorState[:on_color] = json['color']
  rescue Exception => e
   STDERR.puts e.class, e.message, e.backtrace
  end
end
```

To let the server specify specific data for specific callbacks without having to have a different 
json schema for each callback, you copy HTML's forms concept, as a way of templating application calls.

To do that, you've got to make adapters for the actions, with the names the server can know:

``` ruby
M2m.register_handler("Popup") do |form,*args|
    SliderApp::DisplayPopup.show_message(form.fields['message'])
end
M2m.register_handler("StateTransition") do |form,*args|
    m2m_event form.uri.sub("state://","")
end
M2m.register_handler("ToggleBackgroundColor") do |form,*args|
     SliderApp::Display.change_color(form.fields['background.color'])
end
```

And you write a client library which can interpret that json format to fire off events, 
register callbacks which will fire your new handlers, and store the key value data in the datastore.

``` ruby
include M2m::Browser #provides m2m_event m2m_interpret, etc.
m2m_interpret webservice_json # See examples/start.m2m.json

=begin
   what happens in m2m_interpret for start.m2m.json (pseudo code):
   
   M2m.data.merge!("user.name" => "Bob Wehadababyitsaboy", 
                   "user.id" => "10")
   M2m.events["FIRST_OPEN"].push_listener("Popup" 
         {fields: {message: 
           "Congratulations, #{m2m_data['user.name']} 
            on your first M2M Api request."}}
         )
   M2m.events["SliderOn"].push_listener("ToggleBackgroundColor",
         {fields: 
            {'background.color': "green"}}
         )
   M2m.events["SliderOff"].push_listener("ToggleBackgroundColor",
         {fields: 
           {'background.color': "white"}
        )
   StateTransition.call({uri:"state://FIRST_OPEN"})
      #=> m2m_event "FIRST_OPEN"
         #=> M2m.events["FIRST_OPEN"].map(&:call)
           #=> Popup.call({fields: {message: "Congratulations, Bob Wehadababyitsaboy on your first M2M Api request."}})
               #=> App start popup shown. Determined entirely by the json as to when and where its opened.
=end
```

And some tools so you can inspect the state of this new system:

```
# Introspect the m2m layer
m2m_subscribed_events #=> ["FIRST_OPEN", "SliderOn", "SliderOff"]
m2m_known_inputs #=> ["user.name", "user.id"] # can be altered by the App.
m2m_registered_handlers #=> ["Popup","StateTransition","ToggleBackgroundColor"]
m2m_data #=> {"user.name" => "Bob Wehadababyitsaboy", "user.id" => "10"}
```

