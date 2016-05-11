#!/usr/bin/env ruby

require 'bundler/setup'
require 'rubygems'
require 'sinatra'
require 'json'
require 'logger'


enable :logging

before do
  logger.level = Logger::DEBUG
end

def buildHostConfig(config_parameters)
  hostConfigString = "define host {\n"\
    "     address " + config_parameters["ip"].to_s + "\n"\
    "     check_command check-host-alive\n"\
    "     host_name " + config_parameters["hostname"].to_s + "\n"\
    "     hostgroups " + config_parameters["hostgroups"].to_s + "\n"\
    "     max_check_attempts 5\n"\
    "     use generic-host\n"\
  "}\n"
  return hostConfigString
end

def buildServiceConfigs(config_parameters)
  serviceConfigString = ""
  config_parameters.each do |key, value|
    if key.start_with?("service")
      serviceConfigString << "define service {\n"
      serviceConfigString << "     host_name " + config_parameters['hostname'] + "\n"
      value.each do |name, setting|
        serviceConfigString << "     " + name.to_s + " " + setting.to_s + "\n"
      end
      serviceConfigString << "}\n"
    end
  end
  return serviceConfigString
end

def checkConfig()
  status = `nagios -v /etc/nagios/nagios.cfg`
  return $?
end

def restartNagios()
  status = `systemctl restart nagios`
  return $?
end

delete '/:host' do
  config_filepath = "/etc/nagios/conf.d/#{params[:host]}.cfg"
  if File.exist?("#{config_filepath}")
    begin
      File.delete("#{config_filepath}")
      if restartNagios() == 0
        logger.info "restart of nagios successful return 200"
        status 200
      else
        logger.error "restart of nagios failed return 500"
        status 500
      end
    rescue => e
      logger.error "error deleting file, received exception #{e.message} return 500"
      status 500
    end
  else
    status 404
    logger.info "config file #{config_filepath} does not exist, returning 404"
  end
end

post '/new' do
  config_parameters = JSON.parse(request.body.read)
  hostConfigString = buildHostConfig(config_parameters)
  serviceConfigString = buildServiceConfigs(config_parameters)
  config_filepath = "/etc/nagios/conf.d/#{config_parameters['hostname']}.cfg"
  unless File.exist?("#{config_filepath}")
    begin
      config_file = File.new("#{config_filepath}", "w")
      config_file.puts(serviceConfigString)
      config_file.puts(hostConfigString)
      config_file.close
    rescue => e
      logger.error "error creating file, received exception #{e.message} return 500"
      status 500
    end
    if checkConfig() == 0
      logger.info "config check passed, restarting nagios services"
      if restartNagios() == 0
        logger.info "restart of nagios successful return 200"
        status 200
      else
        logger.error "restart of nagios failed return 500"
        status 500
      end
    else
      logger.error "config check failed, did not restart nagios services return 400"
      status 400
      File.delete("#{config_filepath}")
    end
  else
    status 409
    logger.info "config file #{config_filepath} already exist, returning 409"
  end
end
