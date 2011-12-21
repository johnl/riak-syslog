require 'riak-syslog'
require 'riak-syslog/version'
require 'gli'
require 'gli_version'
require 'riak-syslog/tables'
require 'chronic'

include GLI
include Riaksyslog

version Riaksyslog::VERSION

Hirb.enable
Hirb::View.resize

pre do |global_options,command,options,args|
  Riaksyslog.read_config
end

on_error do |e|
  if ENV['DEBUG']
    raise e
  end
  true
end
