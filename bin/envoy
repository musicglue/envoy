#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

$:.unshift File.expand_path('../../lib', __FILE__)
require 'envoy/cli'

cli = Envoy::CLI.new(ARGV)
cli.boot
