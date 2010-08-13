class TweetsController < ApplicationController

  skip_before_filter :verify_authenticity_token


  def index
    @tweets = Tweet.all

    @tweet = Tweet.new
  end
  
  
  def create
    @tweet = Tweet.new params[:tweet]

    E.defer(@tweet.message)
    
    sleep 2
    redirect_to tweets_url
  end
  
  def undo
    u = UndoLog.find_by_identifier(params[:id])
    
    if u
      Tweet.transaction do
        t = Tweet.find(u.undoable_id)
        t.delete
        u.delete
      end
    end
    
    render :nothing => true
  end
  
  def redo
    Tweet.transaction do
      t = Tweet.create! :message => params[:message]
      UndoLog.create! :undoable_type => "tweet", :undoable_id => t.id, :identifier => params[:id]
    end
    
    render :nothing => true
  end
end
