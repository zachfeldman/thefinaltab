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