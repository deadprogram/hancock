class Hancock::User
  include DataMapper::Resource

  property :id,               Serial
  property :first_name,       String
  property :last_name,        String
  property :email,            String, :unique => true, :unique_index => true
  property :internal,         Boolean, :default => false

  property :salt,             String
  property :crypted_password, String

  property :enabled,          Boolean, :default => false
  property :access_token,     String

  attr_accessor :password, :password_confirmation

  def reset_access_token
    @access_token = Digest::SHA1.hexdigest(Guid.new.to_s)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def password_required?
    crypted_password.blank? || !password.blank?
  end

  def encrypt_password
    return if password.blank?
    @salt = Digest::SHA1.hexdigest("--#{Guid.new.to_s}}--email--") if new_record?
    @crypted_password = encrypt(password)
  end

  validates_present        :password, :if => proc{|m| m.password_required?}
  validates_is_confirmed   :password, :if => proc{|m| m.password_required?}

  before :save,   :encrypt_password
  before :save,   :reset_access_token

  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  def self.authenticate(email, password)
    u = first(:email => email)
    u && u.authenticated?(password) && u.enabled ? u : nil
  end
end
