require 'rubygems'
require 'typhoeus'
require 'json'


WORKER_ID = ENV['WORKER_ID']
raise "WORKER_ID not set" if WORKER_ID.to_i == 0

ECQ_ENDPOINT="http://localhost:4567"

APP_ENDPOINT="http://localhost:3000"

# APP_ENDPOINT_REDO_PREFIX=
# APP_ENDPOINT_REDO_MIDDIX=
# APP_ENDPOINT_REDO_SUFFIX=
# 
# def build_endpoint_url(node_id, transaction_id)
#   eval "APP_ENDPOINT=\"#{APP_ENDPOINT}\""
# end

def parse_response_body(r)
  if r.body == ""
    return nil
  else
    return JSON.parse(r.body)
  end
end

def reserve_work!
  while (true) do
    r = Typhoeus::Request.post("#{ECQ_ENDPOINT}/reserve/default/#{WORKER_ID}")  
    break if r.success?
    
    puts "Can not reserve work"
  end
  
  parse_response_body(r)
end

def complete_work!
  while (true) do
    d = Typhoeus::Request.delete("#{ECQ_ENDPOINT}/complete/#{WORKER_ID}")
    break if d.success?
    
    puts "Can not complete work"
  end
end

def check_existing_work
  while (true) do
    e = Typhoeus::Request.get("#{ECQ_ENDPOINT}/work/#{WORKER_ID}")
    break if e.success?
    
    puts "Can not check for existing work"
  end
  
  parse_response_body(e)
end

def commit!(work)
  while(true)
    u = Typhoeus::Request.post("#{APP_ENDPOINT}/tweets/#{work['node']}#{work['id']}/redo",
                                :params=>{:message=>work['message']})
    break if u.success?
    
    puts "Can not commit work"
  end
end

def undo!(work)
  while(true)
    u = Typhoeus::Request.post("#{APP_ENDPOINT}/tweets/#{work['node']}#{work['id']}/undo")
    break if u.success?
    
    puts "Can not undo work"
  end
  
  commit!(work)
  complete_work!
end


existing_work = check_existing_work

if existing_work
  undo!(existing_work)
end

while (true) do
  work = reserve_work!
  
  if work
    puts "Consuming work: #{work.inspect}"
    commit!(work)
    puts "Completing work: #{work}"
    complete_work!
    #undolog_notify!
    
  end
  
  sleep 1
end

