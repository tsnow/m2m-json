# M2m::Json

A JSON API Spec for controlling state on the client, from any call to
the server.

## Installation

Add this line to your application's Gemfile:

    gem 'm2m-json'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install m2m-json

## Usage

``` ruby
require 'm2m';

include M2m::Browser

# Define some Handlers
module Popup  
  def self.call(form, *args)
    @old_message = Display.message
    Display.message =  form.fields['message']
    Display.redisplay
  end 
  def self.ok
    Display.message = @old_message
    Display.redisplay
  end
end 

module ToggleBackgroundColor
   def self.call(form,*args)
     Display.color = form.fields['background.color']
     Display.redisplay
   end
end

# Store Some App State
module Display
 class << self
   attr_accessor :color, :message
 end
 self.message = "Slide the slider to change the text color"
 def self.color=(color_name)
   @color= {"white" => "0;30", "green" => "0;32", }[color_name] || "0;30"
 end
 self.color = "white"
 def self.redisplay
      puts "\e[#{@color}#{@message}\e[m"
 end
end  

# And provide some user actions
def slide_to_on
 m2m_event "SliderOn"
end

def slide_to_off
 m2m_event "SliderOff"
end

# Initialize App
m2m_interpret(JSON.parse("./examples/start.m2m.json"))

# User Actions
Popup.ok
slide_to_on
slide_to_off

# Introspect the m2m layer
m2m_known_events
m2m_known_inputs
m2m_registered_handlers
m2m_data
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
