require 'net-ldap'
require 'config'

def ldap_auth(user, password)
  config = EnvConfig.new
  ldap = config["ldap"]
  return false if password.to_s.empty?
  conn = Net::LDAP.new :host => ldap["host"], :port => ldap["port"], :base => ldap["base"],
                       :auth => {:username => "#{user}@#{ldap["domain"]}", :password => password.to_s, :method => :simple}
  return conn.bind
end
