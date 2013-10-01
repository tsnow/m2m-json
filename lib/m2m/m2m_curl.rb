require 'net/http'
class M2MCurl

  # Supports an additional field, an unexpected response callback of
  # the form: "A b c d" => A.b(response,["c","d"])
  
  def self.call(form, unexpected_response_callback=nil)
    new(form,unexpected_response_callback).call
  end

  attr_accessor :delivery, :enctype, :form_method, :errors
  def initialize(form,unexpected_response_callback)
    @form = form
    @unexpected_response_callback = setup_callback(unexpected_response_callback)
    @delivery = form.strategy['delivery']
    @retry_count = form.strategy.fetch('retry_count',2).to_i
    @enctype = form.enctype
    @request_method = {"post" => Net::HTTP::Post, "get" => Net::HTTP::Get, }.fetch(form.form_method.to_s.downcase, Net::HTTP::Post)
  end
  def call
    return self.errors unless self.valid?
    uri = URI.parse(@form.uri)
    http = Net::HTTP.new(uri.host, uri.port);
    http.use_ssl = true if uri.scheme =~ /https/
    request = @request_method.new(uri.request_uri)
    request.set_content_type "application/json"
    request['Accept'] = "vnd.application/json+m2m, application/json, */*"
    request.body = JSON.generate(@form.fields)
    until self.retry_count == 0 || @response.kind_of?(Net::HTTPSuccess) 
      @response = http.request(request)
    end
    
    return ::M2m.interpret(JSON.parse(@response.body)) if successful? && @response['Content-type'] =~ %r{vnd.application/json+m2m}
    unexpected_response_callback[@response]
    return @response
  rescue => e
    e
  end
  
  def setup_callback(callback)
    klass, meth, rest = callback.split(" ")
    Proc.new{|response|
      const_get("::#{klass}").send(meth, response, rest)
    }
  end
  def successful?
    @response.kind_of?(Net::HTTPSuccess)
  end
  def valid?
    return @errors unless @errors.empty?
    @errors.push("must have enctype: 'application/json' or unspecified") unless !self.enctype || self.enctype =~ "application/json"
    @errors.push("must be on wifi to submit") if self.delivery == "wifi"
    @errors.empty?
  end
  def errors
    @errors
  end
end
