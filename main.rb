#!/usr/bin/env ruby

require 'bundler/setup'
require 'rubygems'
require 'sinatra'
require 'json'
require 'logger'

CONFIG_LOCATION = '/etc/nagios/conf.d/'.freeze

# Initialize logger
class Mylog
  def self.log
    if @logger.nil?
      @logger = Logger.new STDOUT
      @logger.level = Logger::DEBUG
      @logger.datetime_format = '%Y-%m-%d %H:%M:%S '
    end
    @logger
  end
end

def build_host_config(config_parameters)
  "define host {\n"\
  '     address ' + config_parameters['ip'].to_s + "\n"\
  "     check_command check-host-alive\n"\
  '     host_name ' + config_parameters['hostname'].to_s + "\n"\
  '     hostgroups ' + config_parameters['hostgroups'].to_s + "\n"\
  "     max_check_attempts 5\n"\
  "     use generic-host\n"\
  "}\n"
end

def build_service_configs(config_parameters)
  service_config_string = ''
  config_parameters['services'].each do |service|
    service_config_string << "define service {\n"
    service_config_string << "     host_name #{config_parameters['hostname']}\n"
    service.each do |key, value|
      service_config_string << '     ' + key.to_s + ' ' + value.to_s + "\n"
    end
    service_config_string << "}\n"
  end
  service_config_string
end

def check_config
  `nagios -v /etc/nagios/nagios.cfg`
  $?
end

def restart_nagios
  `systemctl restart nagios`
  $?
end

delete '/:host' do
  config_filepath = "#{CONFIG_LOCATION}#{params[:host]}.cfg"
  if File.exist?(config_filepath)
    begin
      File.delete(config_filepath)
      if restart_nagios == 0
        status 200
        Mylog.log.info 'restart of nagios successful return 200'
      else
        status 500
        Mylog.log.error 'restart of nagios failed return 500'
      end
    rescue => e
      status 500
      Mylog.log.error "error deleting file, received exception #{e.message} return 500"
    end
  else
    status 404
    Mylog.log.info "config file #{config_filepath} does not exist, returning 404"
  end
end

post '/new' do
  config_parameters = JSON.parse(request.body.read)
  host_config_string = build_host_config(config_parameters)
  service_config_string = build_service_configs(config_parameters)
  config_filepath = "#{CONFIG_LOCATION}#{config_parameters['hostname']}.cfg"
  if File.exist?(config_filepath)
    status 409
    Mylog.log.info "config file #{config_filepath} already exist, returning 409"
  else
    begin
      config_file = File.new(config_filepath, 'w')
      config_file.puts(service_config_string)
      config_file.puts(host_config_string)
      config_file.close
    rescue => e
      status 500
      Mylog.log.error "error creating file, received exception #{e.message} return 500"
    end
    if check_config == 0
      Mylog.log.info 'config check passed, restarting nagios services'
      if restart_nagios == 0
        status 200
        Mylog.log.info 'restart of nagios successful return 200'
      else
        status 500
        Mylog.log.error 'restart of nagios failed return 500'
      end
    else
      status 400
      Mylog.log.error 'config check failed, did not restart nagios services return 400'
      File.delete(config_filepath)
    end
  end
end
