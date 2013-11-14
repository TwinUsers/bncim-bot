#!/usr/bin/env ruby
####
## bnc.im administration bot
##
## Copyright (c) 2013 Andrew Northall
##
## MIT License
## See LICENSE file for details.
####

$:.unshift File.dirname(__FILE__)

require 'cinch'
require 'yaml'
require 'lib/requests'
require 'lib/logger'

$config = YAML.load_file("config/config.yaml")
$bots = Hash.new
$threads = Array.new

# Set up a bot for each server
$config["servers"].each do |name, server|
  bot = Cinch::Bot.new do
    configure do |c|
      c.nick = $config["bot"]["nick"]
      c.user = $config["bot"]["user"]
      c.realname = $config["bot"]["realname"]
      c.server = server["server"]
      c.ssl.use = server["ssl"]
      c.sasl.username = $config["bot"]["saslname"]
      c.sasl.password = $config["bot"]["saslpass"]
      c.port = server["port"]
      c.channels = $config["bot"]["channels"].map {|c| c = "#" + c}
      c.plugins.plugins = [RequestPlugin]
    end
  end
	bot.loggers.clear
  bot.loggers << BNCLogger.new(name, File.open("log/#{name}.log", "a"))
	bot.loggers << BNCLogger.new(name, STDOUT)
  bot.loggers.level = :info
  $bots[name] = bot
end

# Initialize the RequestDB
RequestDB.load($config["requestdb"])

# Start the bots
$bots.each do |key, bot|
  $threads << Thread.new { bot.start }
end

$threads.each { |t| t.join } # wait for other threads
