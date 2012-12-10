DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/database.db")
class User
  include DataMapper::Resource
  property :id,         Serial
  property :uid,        String
  property :name,       String
  property :nickname,   String
  property :picture,    Text, :lazy => false, :default => "/images/defaultprofile.png"
  property :f_url,      String
  property :location,   String
  property :email,      String
  property :email_sent, Integer
  property :created_at, DateTime
  
  def fname

    self.name.split[0]

  end

  has n, :tabs, :through => Resource
  has n, :bills
end

class Tab
  include DataMapper::Resource
  property :id,       Serial
  property :name,     String
  property :notes,    Text

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
#DataMapper.auto_upgrade!