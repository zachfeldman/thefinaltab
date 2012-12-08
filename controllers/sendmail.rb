def send_invite(email, fname)

  html = "<h1>" + fname + " wants you to use The Final Tab to split the bills.</h1>
	Your friend has invited you to use The Final Tab to make it easy to split your bills. <a href='http://thefinaltab.com'>
	Sign up today</a> for your free account to get started.<br/><br/><div style='font-size: 9px'>Sent this e-mail in error? <a href='http://thefinaltab.com'>Click here</a> to unsubscribe.</div>"

  Mail.defaults do
    delivery_method :smtp, { :address   => "smtp.sendgrid.net",
                             :port      => 587,
                             :domain    => "thefinaltab.com",
                             :user_name => ENV['SENDGRID_USERNAME'],
                             :password  => ENV['SENDGRID_PASSWORD'],
                             :authentication => 'plain',
                             :enable_starttls_auto => true }
  end

  mail = Mail.deliver do
    to email
    from 'The Final Tab <info@thefinaltab.com>'
    subject "Your friend #{fname} wants to settle your tab"
    text_part do
      body html
    end
    html_part do
      content_type 'text/html; charset=UTF-8'
      body html
    end
  end


end
