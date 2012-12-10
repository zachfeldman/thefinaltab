require 'rubygems'
require 'sinatra'
require 'haml'
require 'net/https'
require 'mail'
require './controllers/sendmail'
require './controllers/calculate'
require 'will_paginate'
require 'will_paginate/array'
require './will_paginate_sinatra_renderer'

%w(omniauth omniauth-twitter omniauth-facebook dm-migrations dm-validations).each { |dependency| require dependency }
DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/database.db")
class User
  include DataMapper::Resource
  property :id,         Serial
  property :uid,        String
  property :name,       String
  property :nickname,   String
  property :picture,    Text, :lazy => false, :default => "/images/defaultprofile.png"
	property :f_url,			String
	property :location,   String
	property :email,			String
	property :email_sent,	Integer
	property :created_at, DateTime
	
	def fname

		self.name.split[0]

	end

	has n, :tabs, :through => Resource
	has n, :bills
end

class Tab
	include DataMapper::Resource
	property :id,				Serial
	property :name,			String
	property :notes,		Text

	has n, :bills
	has n, :users, :through => Resource
end

class Bill
  include DataMapper::Resource
    property :id,   Serial
    property :name, Text 
    property :amount, Float
    property :notes, Text

    belongs_to :user
		belongs_to :tab
end

DataMapper.finalize
DataMapper.auto_upgrade!

use OmniAuth::Strategies::Facebook, ENV['FACEBOOK_ID'], ENV['FACEBOOK_SECRET']
enable :sessions

helpers do
  def current_user
    @current_user ||= User.get(session[:user_id]) if session[:user_id]
  end
	def partial(page, options={})
		haml page, options.merge!(:layout => false)
	end
  def picture(userPicture)
    if(userPicture == nil)
      return "/images/defaultprofile.png"
    else
      return userPicture
    end
  end
  def deleteAllowed(sessionUserId, theUserId)
    if(sessionUserId == theUserId)
      return ""
    else
      return "userDeleteButton"
    end
  end
  def nameOrEmail(billUser)
    if(billUser.name == nil)
      return billUser.email
    else
      return billUser.name
    end
  end
end

get '/' do
	puts current_user
  if current_user
  	@user = current_user
		haml :home
	else
    @user = current_user
  	haml :welcome
	end
end

get '/tabs/create' do

	@user = current_user
	haml :tabs_create

end

get '/tabs' do
  @user = current_user
  haml :tabs
end

post '/tabs/:id/adduser/:email' do
	email = params[:email]
	user = User.first_or_create(:email => email)
  tab = Tab.first(:id => params[:id])
	if user.email_sent == nil
		send_invite(email, current_user.fname)
		user.update(:email_sent => 1)
    user.tabs << tab  
    user.save
		@user = user
    return partial :users
	elsif user.email_sent == 1
    user.tabs << tab  
    user.save
		@user = user
    return partial :users
	else
		@user = user
		return partial :users
	end
end

post '/tabs/:tabId/deleteuser/:userId' do
  tab = Tab.first(:id => params[:tabId])
  user = User.first(:id => params[:userId])
  tab.bills(:user_id => user.id).destroy
  tab.users.delete(user)
  tab.users.save
  return true
end

get '/tabs/:id/add' do
  @tab = Tab.first(:id => params[:id])
  @user = session[:user_id]
  return haml :tab_modify_users
end

get '/tabs/process' do
	tab = current_user.tabs.first(:name => params[:tabName], :notes => params[:tabNotes]) 
	if(tab == nil)		
		tab = Tab.create(:name => params[:tabName], :notes => params[:tabNotes])
		user = current_user
		user.tabs << tab
		user.save
		@tab = tab
		haml :tabs_success
	else
		@tab = tab
		haml :tab_exists
	end
end

get '/tabs/:id' do
	id = params[:id]
	tab = Tab.first(:id => id)
	@tab = tab
	@bills = tab.bills.paginate(:page => params[:page], :per_page => 3)
	haml :tab_view
end

get '/tabs/:id/settle' do
  @debts = calculate_owed(params[:id])
  haml :tab_settle
end

post '/bills/new' do
	name = params[:billName]
	amount = params[:billAmount]
	notes = params[:billNotes]
	userID = params[:billUser]
	tabID = params[:billTab]
	tab = current_user.tabs.first(:id => tabID)
	bill = Bill.first(:name => name, :amount => amount)
	user = User.first(:id => userID)
	if(bill == nil)
		bill = Bill.new(:name => name, :amount => amount, :notes => notes, :tab => tab, :user => user)
		bill.save
		bill.errors.each do |e|
			puts e
		end
		tab.bills << bill
		tab.save
		@bill = bill
		return partial :bill_item
	else
		return "e"
	end
end

get '/auth/:name/callback' do
  auth = request.env["omniauth.auth"]
  user = User.first_or_create({:email => auth["info"]["email"], :name => auth["info"]["name"]},{
    :uid => auth["uid"],
    :nickname => auth["info"]["nickname"], 
    :name => auth["info"]["name"],
    :picture => auth["info"]["image"],
		:f_url => auth["info"]["urls"]["Facebook"],
		:location => auth["info"]["urls"]["location"],
		:email => auth["info"]["email"],
		:email_sent => 0,
		:created_at => Time.now,
 		:tabs => [],
		:bills => []	})
		session[:user_id] = user.id
  redirect '/home'
end

get '/home' do
	@user = current_user 
	haml :home
end

get '/email' do
  haml :email_welcome
end

["/sign_in/?", "/signin/?", "/log_in/?", "/login/?", "/sign_up/?", "/signup/?"].each do |path|
  get path do
    redirect '/auth/facebook'
  end
end

["/sign_out/?", "/signout/?", "/log_out/?", "/logout/?"].each do |path|
  get path do
    session[:user_id] = nil
    redirect '/'
  end
end
