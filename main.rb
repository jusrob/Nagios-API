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
    "  address " + config_parameters["ip"].to_s + "\n"\
    "  check_command check-host-alive\n"\
    "  host_name " + config_parameters["hostname"].to_s + "\n"\
    "  hostgroups " + config_parameters["hostgroups"].to_s + "\n"\
    "  max_check_attemps 5\n"\
    "  use generic-host\n"\
  "}\n"
  return hostConfigString
end

def buildServiceConfigs(config_parameters)
  serviceConfigString = ""
  config_parameters.each do |key, value|
    if key.start_with?("servicecmd")
      serviceNumber = key.split("servicecmd")[1]
      if config_parameters["serviceuse#{serviceNumber}"].to_s != ""
        serviceUse = config_parameters["serviceuse#{serviceNumber}"]
      else
        serviceUse = "generic-service"
      end
      serviceConfigString << "define service {\n" \
        "  check_command " + config_parameters["servicecmd#{serviceNumber}"].to_s + "\n"\
        "  host_name " + config_parameters["hostname"].to_s + "\n"\
        "  service_description " + config_parameters["servicedesc#{serviceNumber}"].to_s + "\n"\
        "  use " + serviceUse.to_s + "\n"\
        "}\n\n"
    end
  end
  return serviceConfigString
end

delete '/:host' do
  config_filepath = "#{params[:host]}.cfg"
  if File.exist?("#{config_filepath}")
    begin
      File.delete("#{config_filepath}")
      `service nagios restart`
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
  config_filepath = "#{config_parameters['hostname']}.cfg"
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
  else
    status 409
    logger.info "config file #{config_filepath} already exist, returning 409"
  end
end
