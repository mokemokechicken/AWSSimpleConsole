require 'json'

CONFIG_JSON_PATH = File.expand_path('../../../config/env.json', __FILE__)
SITE_CONFIG_JSON_PATH = File.expand_path('../../../config/env-site.json', __FILE__)

class EnvConfig
  def initialize
    @data = JSON.parse(File.read(CONFIG_JSON_PATH))
    if File.exists?(SITE_CONFIG_JSON_PATH)
      site_config = JSON.parse(File.read(SITE_CONFIG_JSON_PATH))
      @data.update(site_config)
    end
  end

  def [](key)
    get(key)
  end

  def get(key, df=nil)
    if @data.has_key?(key)
      @data[key]
    else
      df
    end
  end
end
