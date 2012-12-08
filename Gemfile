source 'http://rubygems.org'

gem 'sinatra'
gem 'haml'

gem 'carrierwave-datamapper'
gem 'heroku'
gem 'data_mapper'

group :development, :test do
 gem 'debugger', :require => 'debugger'
 gem "do_sqlite3", "~> 0.10.8"
 gem 'sqlite3'
 gem 'dm-sqlite-adapter', :require => 'dm-sqlite-adapter'
end

group :production do
  gem 'pg' # this gem is required to use postgres on Heroku
  gem 'dm-postgres-adapter'
end

gem 'omniauth-twitter'
gem 'omniauth-facebook', '1.4.0'
gem 'dm-core'
gem 'dm-migrations'

gem 'mail'

gem 'will_paginate'
