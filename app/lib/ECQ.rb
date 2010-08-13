class ECQ
  attr_reader :endpoint
  
  def initialize(endpoint)
    endpoint = endpoint
  end
  
  def defer(message)    
    request = Typhoeus::Request.post("http://localhost:4567/queue/default", :params=>{:message=>message})

    
  end
  
end