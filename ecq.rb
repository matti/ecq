require 'rubygems'
require 'sinatra'
require 'redis'
require 'json'

configure do
  REDIS = Redis.new
  NODE = "a"
end

helpers do
end

#jokaisella pitää olla oma id, itemit on tällöin numeroit
#ecqid-vapaastikasvava, jolloin worker voi lentää mille milloinki ja olla dummy



post '/queue/:name' do
  queue_name = params[:name]
  
  REDIS.lpush queue_name, params[:message]
end

def work_in_queue?(worker_queue)
  REDIS.llen(worker_queue) > 0
end

def current_id(worker_queue)
  REDIS.get("#{worker_queue}-id") 
end

get '/work/:worker_id' do
  worker_id = params[:worker_id]  
  worker_queue = "w#{worker_id}"
  
  if work_in_queue?(worker_queue)
    response = build_response(current_id(worker_queue), worker_queue)
  end

  response ? response.to_json : nil
end


#  queue    w1     w2
#    a      
#    b
#           c

# 1. Hae itemi <-- reserve
# --- BUM ----
# 2. Poista itemi  <-- item



post '/reserve/:name/:worker_id' do
  queue_name = params[:name]
  worker_id = params[:worker_id]  
  worker_queue = "w#{worker_id}"

  work_in_queue = work_in_queue?(worker_queue)

  unless work_in_queue
    work_in_queue = REDIS.rpoplpush(queue_name, worker_queue)
  end
  
  id = current_id(worker_queue)
  
  unless work_in_queue && id
    id = REDIS.incr "id"
    REDIS.set "#{worker_queue}-id", id
  end
  
  if work_in_queue && id
    response = build_response(id, worker_queue)
  end
  
  response ? response.to_json : nil
end

delete '/complete/:worker_id' do
  queue_name = params[:name]
  worker_id = params[:worker_id]
  
  worker_queue = "w#{worker_id}"

  REDIS.multi do
    REDIS.lpop worker_queue
    REDIS.del "#{worker_queue}-id"
  end

  ''
end

private

def build_response(id, worker_queue)
  response = {:node => NODE,
              :id => id,
              :message => REDIS.lindex(worker_queue, 0)}
end
