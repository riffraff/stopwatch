class WelcomeController < ApplicationController
  @@counter=0
  def index
  end

  def access_db
    Item.create!(:name => params[:name])
    render :nothing => true
  end

  def javascript_test
    headers['Content-Type'] = 'application/x-javascript'
    render :file => "#{Rails.root}/public/javascripts/test.js", :layout => false
  end
end
