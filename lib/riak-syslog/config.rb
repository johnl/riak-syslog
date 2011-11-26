module Riaksyslog
  CONFIG_FILES = ["riak-syslog.yml", "/etc/riak-syslog.yml", "~/.riak-syslog.yml"]

  def self.read_config
    CONFIG_FILES.find do |f|
      f = File.expand_path(f)
      if File.exists? f
        config = YAML::load_file(f)
        Riaksyslog::Record.config = config
      else
        nil
      end
    end
  end
end
