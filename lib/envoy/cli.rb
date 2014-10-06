require_relative '../envoy'
require 'optparse'
require 'fileutils'

module Envoy
  class CLI
    def initialize(arguments)
      @arguments = arguments
    end

    def boot!
      parse_options
      run
    end

    def run
      %w(INT TERM).each do |signal|
        begin
          trap signal do
            handle_signal(signal)
          end
        rescue ArgumentError
          puts "Signal #{sig} not supported"
        end
      end
      include_external_environment
      print_banner
      Envoy.start
      sleep
    rescue Interrupt
      Envoy.stop
      exit 0
    end

    def include_external_environment
      if File.directory?(options[:require])
        require 'rails'
        require File.expand_path("#{options[:require]}/config/environment.rb")
        ::Rails.application.eager_load!
      else
        require options[:require]
      end
    end

    private

    def parse_options
      @opts = {
        require: ENV['PWD']
      }

      parser = OptionParser.new do |o|
        o.on '-r',
             '--require [PATH|DIR]',
             'Location of Rails application or file to require (defaults to current working directory)' do |arg|
          @opts[:require] = arg
        end
      end

      parser.banner = 'Envoy [options]'
      parser.on_tail '-h', '--help', 'Show help' do
        puts parser
        exit(1)
      end

      parser.parse!(@arguments)
      @opts
    end

    def options
      @opts ||= {}
    end

    def print_banner
      Celluloid.logger.info "Starting Envoy under #{Rails.env} environment: v#{Envoy::VERSION} (Reboot)"
    end

    def handle_signal(signal)
      case signal
      when 'INT'
        fail Interrupt
      when 'TERM'
        fail Interrupt
      end
    end
  end
end
