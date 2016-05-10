require 'bundler'
Bundler.setup(:default)
require './main.rb'
run Sinatra::Application
