### Example Responses:

``` log
> GET /
> Accept: vnd.application/json+m2m, application/json, */*
> Content-type: application/json
>
< Status: 200
< Content-type: vnd.application/json+m2m
< 
``` 
``` json
{"m2m": 
    {
      "transitions": [
          
         {"when": { "to": "FIRST_OPEN"},
          "action":"PopupWelcome",
          "handler":"Popup"},

         {"when":"now",
          "action":"FirstOpen",
          "handler":"StateTransition"},

         {"when": { "to": "SliderOn" },
          "action":"BackgroundGreen",
          "handler":"ToggleBackgroundColor"},

         {"when": { "to": "SliderOff" },
          "action":"BackgroundWhite",
          "handler":"ToggleBackgroundColor"}
        ],
      "actions":[
         {"id": "FirstOpen",
          "uri" : "state://FIRST_OPEN", 
         },
         {"id": "PopupWelcome",
          "inputs" : [
                      {
                       "name":"message",
                       "value": "<p>Congratulations, $user.name$ on your first M2M Api request.</p>"}, 
                     ]
         },
         {"id": "BackgroundGreen",
          "inputs": [
                     {"name": "background.color",
                      "value" : "green"}
                      ]
         },
         {"id": "BackgroundWhite",
          "inputs": [
                     {"name": "background.color",
                      "value" : "white"}
                      ]
         }
        ],
      "save":{ // The datastore is available to the outside
               // application to query.
        "user.id": "10",
        "user.name" : "Dave Wehadababyitsaboy"
      }
    }
  }
```

### Definitions: Handlers, Events, Transitions, and Actions

Handlers and events are the interface for the outside world. To use a
Web analogy, Handlers are the application code inside javascript event
callbacks.

- Events are simple strings and fire Transitions when they occur. In
  the
web, these would be mouse clicks.
- Actions are a flexible data format for defining parameters to
Handlers. They are an extension to HTML / Pim Forms style forms.
- Transitions are descriptions of what callbacks to run at what times
Handlers are application-specific pieces of code or scripts which
  dictate how
Actions are taken when a Transition occurs.
- Action Cache, Transition Cache: These are analogous to the DOM,
  while the
Data Cache is analogous to the knowledge inside the user's head - the
entire m2m.json script set is a combination of the user's hands and
  the browser.
- The additional_fields are like hidden inputs in HTML forms, they
  allow
the server to specify data that it or the Handlers will need for
future actions. 

For instance, a Curl handler would interpret the form data and make a
request to a server, using the curl command line utility. Some
possible action forms used by a curl handler might be "Synced" or
"UploadLogs"; while a RipsPayment handler might understand a
"CardPayment" action. 


`m2m_event.sh` is an example implementation of the event firing
system.

Some example handlers are included. See `Popup.sh`,
`StateTransition.sh`, `RemoteSync.sh`, and `Curl.sh`.

Handlers are passed the completed form, which will then have an
additional `.fields` section, with the data from `.inputs`
macro-expanded and filled out with
the current values matching the `.id`s from the Data Store.

For instance:
``` js
// Handler 
"Curl"

// action
{
 "uri":
 "https://$restfulServer$/pim_api/v1/driver_authentications?pim_id=$pim.id$",
 "enctype": "application/json",
 "method": "POST",
 "inputs":[
   {"name":"driver_code", "id":"driver.code"},
   {"name":"pin", "id":"driver.pin"},
   {"name":"snowman", "value":"☃"},
   {"name":"nothing", "id": "no.match"},
 ]
}

// data store
{
 "restfulserver": "rips.ridecharge.com",
 "driver.pin" : "1245",
 "driver.code" : "AYC234",
 "pim.id": "34555"
}
```

would have the following effect:

``` json
//> echo > /tmp/form
{
 "uri":
 "https://rips.ridecharge.com/pim_api/v1/driver_authentications?pim_id=34555",
 "enctype": "application/json",
 "method": "POST",
 "fields":{
   "driver_code" : "AYC234",
   "pin" : "1245",
   "snowman": "☃",
   "nothing": "",
 }
}
// ^D
//> Curl.sh /tmp/form; rm /tmp/form
```

### 'now'

There is a special type of transition for actions that should only be
done once, for just the current m2m.json document, rather than
descriptively for all possible actions of that type in the future
(the descriptive kind is the default.)

These transitions will not be added to the Transition Cache, and will
fire after the m2m.json document has been interpreted.


### Macros

Much like the PIM Forms, the m2m.json system should provide macro
expansion, to be filled in with data from the Data Cache. Macros in
.transitions and .additional_fields will be expanded when the m2m.json
file is interpreted, macros in .actions will be expanded when the
transition occurs which uses those actions.



### Scripts

An example implementation in bash (with the jq utility, a C library
with few dependencies) is
included. Here's a short explanation of the scripts:

``` bash
m2m_interpret.sh m2m.json
```

This will use m2m_set_data.sh to set any additional_fields supplied,
and `m2m_set_action.sh` and `m2m_add_transition.sh` to register any
provided actions and
transitions, respectively.

``` bash
m2m_event.sh [to STATE_CARD_SWIPED] [from STATE_BOUNCE_PAYMENT]
```

Will trigger the transitions registered for the provided events.

``` bash
m2m_reset.sh [start.m2m.json]
```

Will reset the actions, transitions, and data stores to an empty or
baseline state, depending on whether the optional m2m.json is
specified.

``` bash
m2m_get_data.sh key
```

Will return the stored data at `key`.

``` bash
m2m_set_data.sh key value
```

Will store the `value` to be retrieved by `key`.

Internal tools:

- `m2m_interpret.sh` uses: `m2m_add_transition.sh 'transition_json'`,
  `m2m_set_action.sh action_name 'action_json'`, `m2m_rm_transition.sh
  'transition_json'`, `m2m_fire_transition.sh 'transition_json'` and
  will eventually use m2m_apply_macros.sh                                                                                         
- `m2m_eval_form.sh` uses m2m_fill_form.sh to turn actions into forms
  for handlers. m2m_fill_form.sh uses m2m_update_form.sh to update
  each field. m2m_update_form.sh will eventually use
  m2m_apply_macros.sh.                                                                                             
- `m2m_event.sh` uses `m2m_fire_transition.sh 'transition_json'`.
- `m2m_fire_transition.sh` uses `m2m_get_action.sh 'action_name'` and
  `m2m_get_handler.sh 'handler'.                                                                                                                                                                                      
- `m2m_transition.sh 'handler' 'action'` is a convenience method for
  testing handlers via just their name and an associated action, so
  you don't have to write json on the command line.
- `Curl.sh` would be like a stdlib package. It submits the given form
  as a JSON POST, and interprets and vnd.application/json+m2m
  responses it gets back.

### Proposed JSON schema: * (see current below)

``` ruby
Header["Content-type"]=vnd.application/json+m2m
m2m.save? # see Field Storage
           .{field_id}=unset_sentinel or value_template

m2m.transitions?[]
           .when= now or
               .to?=state_name
               .from?=state_name
           .action=action_name
           .handler=unset_sentinel or handler_name # GenericJSONAPI or
                                                   # "ChargeAPI retry 2 delivery immediate" 
                                                   # or "Receipt" or "Popup", etc
m2m.actions?[]
           .uri?=uri-template
           .enctype?=enctype # currently application/json or application/x-www-form-urlencoded
                             # for the Curl handler, optional for others

           .id=action_name
           .strategy?=strategy
           .method?=method #POST or GET
           .inputs?[]
               .id?=field_id
               .name=field_name
               .value?=value_template
               .type?=type_name # For static clients, by handler,  "char", "short", "int", "long",
                                # "timestamp","float", "double", "cstring" or "string"
                                # default is 'string'
```

### Field Storage:
 One addition this proposal includes is a persistent,
 server-configurable key value store. The Additional Fields section of
 the Result dictates the values which should be set in future
 actions. 
value_ and uri_templates should always act as though the current value
 of their variables are the current values of those field_ids in the
 key value store.

See `m2m_get_data.sh` and `m2m_set_data.sh` for an example
implementation.
