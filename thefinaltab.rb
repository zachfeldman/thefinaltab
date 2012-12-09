require 'rubygems'
require 'sinatra'
require 'haml'
require 'net/https'
require 'mail'
require 'debugger'
require './controllers/sendmail'
require './controllers/calculate'
require 'will_paginate'
require 'will_paginate/array'
require './will_paginate_sinatra_renderer'

https = Net::HTTP.new('encrypted.google.com', 443)
https.use_ssl = true
https.verify_mode = OpenSSL::SSL::VERIFY_PEER
https.ca_path = '/etc/ssl/certs' if File.exists?('/etc/ssl/certs') # Ubuntu
https.ca_file = '/opt/local/share/curl/curl-ca-bundle.crt' if File.exists?('/opt/local/share/curl/curl-ca-bundle.crt') # Mac OS X
https.request_get('/')


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

# You'll need to customize the following line. Replace the CONSUMER_KEY 
#   and CONSUMER_SECRET with the values you got from Twitter 
#   (https://dev.twitter.com/apps/new).
#use OmniAuth::Strategies::Twitter, 'E8K6s1icpzo2a2ZEjkwnzw', 'dcbsffTJNyKIQA8xxWqLW5UMKF8yVF7gpCdMBmMrtTo'
use OmniAuth::Strategies::Facebook, ENV['FACEBOOK_ID'], ENV['FACEBOOK_SECRET']
enable :sessions

helpers do
  def current_user
    @current_user ||= User.get(session[:user_id]) if session[:user_id]
  end
	def partial(page, options={})
		haml page, options.merge!(:layout => false)
	end
end

get '/' do
	puts current_user
  if current_user
  	@user = current_user
		haml :home
	else
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
  return true
end

get '/tabs/:id/add' do
  @tab = Tab.first(:id => params[:id])
  return haml :tab_add_user
end

get '/tabs/process' do
	tab = current_user.tabs.first(:name => params[:tabName], :notes => params[:tabNotes], :amount => params[:tabAmount]) 
	if(tab == nil)		
		tab = Tab.create(:name => params[:tabName], :notes => params[:tabNotes])
		users = params[:tabUsers]
		users.split(',').each do |email|
			user = User.first(:email => email)
			user.tabs << tab	
			user.save
		end
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
	puts current_user
	@user = current_user 
	haml :home
end

# any of the following routes should work to sign the user in: 
#   /sign_up, /signup, /sign_in, /signin, /log_in, /login
["/sign_in/?", "/signin/?", "/log_in/?", "/login/?", "/sign_up/?", "/signup/?"].each do |path|
  get path do
    redirect '/auth/facebook'
  end
end

# either /log_out, /logout, /sign_out, or /signout will end the session and log the user out
["/sign_out/?", "/signout/?", "/log_out/?", "/logout/?"].each do |path|
  get path do
    session[:user_id] = nil
    redirect '/'
  end
end
