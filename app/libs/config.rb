require 'json'

CONFIG_JSON_PATH = File.expand_path('../../../config/env.json', __FILE__)

class EnvConfig
  def initialize
    @data = JSON.parse(File.read(CONFIG_JSON_PATH))
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
