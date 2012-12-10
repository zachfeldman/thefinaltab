%w(
rubygems
sinatra
haml
net/https
mail
./controllers/sendmail ./controllers/calculate
will_paginate will_paginate/array ./will_paginate_sinatra_renderer
omniauth omniauth-twitter omniauth-facebook
dm-migrations dm-validations ./models/main
./helpers).each { |dependency| require dependency }

use OmniAuth::Strategies::Facebook, ENV['FACEBOOK_ID'], ENV['FACEBOOK_SECRET']
enable :sessions

#main routes
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

get '/home' do
  @user = current_user 
  haml :home
end

get '/email' do
  haml :email_welcome
end

#tab routes
get '/tabs' do
  @user = current_user
  haml :tabs
end

get '/tabs/create' do

	@user = current_user
	haml :tabs_create

end

post '/tabs/:id/users/add/:email' do
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

post '/tabs/:tabId/users/delete/:userId' do
  tab = Tab.first(:id => params[:tabId])
  user = User.first(:id => params[:userId])
  tab.bills(:user_id => user.id).destroy
  tab.users.delete(user)
  tab.users.save
  return true
end

get '/tabs/:id/users/modify' do
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

#auth routes
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