$:.push File.expand_path('../lib', __FILE__)
require 'riak-syslog/version'

Gem::Specification.new do |gem|
  # Meta
  gem.name = "riak-syslog"
  gem.version = Riaksyslog::VERSION
  gem.summary = %Q{riak-syslog is a syslogging system using riak, the distributed database by Basho }
  gem.email = ["john@brightbox.co.uk"]
  gem.homepage = "http://github.com/johnl/riak-syslog"
  gem.authors = ["John Leach"]

  # Deps
  gem.add_dependency "riak-client", "~> 1.0.3"
	gem.add_dependency "gli"
	gem.add_dependency "hirb"
	gem.add_dependency "chronic"

  # Files
  ignores = File.read(".gitignore").split(/\r?\n/).reject{ |f| f =~ /^(#.+|\s*)$/ }.map {|f| Dir[f] }.flatten
  gem.files         = (Dir['**/*','.gitignore'] - ignores).reject {|f| !File.file?(f) }
  gem.test_files    = (Dir['spec/**/*','.gitignore'] - ignores).reject {|f| !File.file?(f) }
  gem.executables   = Dir['bin/*'].map { |f| File.basename(f) }
  gem.require_paths = ['lib']
end
