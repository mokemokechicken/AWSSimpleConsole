class Ec2Cache < ActiveRecord::Base
  EXPIRE_SEC = 86400
  def self.fetch(ec2, cache_expire=nil)
    cache_expire ||= EXPIRE_SEC
    ec2_cache = Ec2Cache.where(:ec2_id => ec2.id).first
    if not ec2_cache
      ec2_cache = create_cache(ec2)
      ec2_cache.save
    elsif cache_expire < Time.now - ec2_cache.updated_at
      ec2_cache.sync(ec2)
    end
    ec2_cache
  end

  def self.create_cache(ec2)
    new(:ec2_id => ec2.id).sync(ec2)
  end

  def sync(ec2)
    self.tag_json = ec2.tags.to_h.to_json
    self.launch_time = ec2.launch_time
    self.instance_type = ec2.instance_type
    self.status = ec2.status
    self.public_ip = ec2.public_ip_address
    self.private_ip = ec2.private_ip_address
    save!
    self
  end

  def tags
    JSON.parse(tag_json)
  end

  def as_json(options)
    super(:methods => :tags, :except => :tag_json)
  end
end
