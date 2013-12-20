require 'net-ldap'

conn = Net::LDAP.new :host => 'redsox.ad.yume.mi', :port => 389, :base => 'cn=LDAPAdmins,cn=Users,dc=ad,dc=yume,dc=mi',
                     :auth => {:username => "#{user}@#{yumemi.co.jp}", :password => pass, :method => :simple}

if !pass.to_s.empty? && conn.bind
  # 認証OK
else
  # 認証失敗
end

