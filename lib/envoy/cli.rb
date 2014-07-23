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
      check_requirements
      Envoy.start!
      sleep
    rescue Interrupt
      Envoy.shutdown!
      exit(0)
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

    def check_requirements
      errors, warnings = [], []
      warnings << '[WARNING] No queues defined' if Envoy.config.queues.count.zero?
      puts warnings.join("\n")
      unless errors.blank?
        puts errors.join("\n")
        exit(1)
      end
    end

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
      puts <<-EOL
                                                                                 @.               @f
                                                                                 8C             C8
                                                                                 @@,  C       .@
                                                                        @@@   t  8@    @     @         L        L
                                                                         ;    @  @@    @G  @@        @        @@
                                                                        @    @@@@@@@@@@@@@@@f   @  08       @@
                                                                     @G @@ @@@@@@@@@@@@@@@@@@@@@@@@
                                                                        @@@@@@@@@@@@@@@@@@@@@@@@@@@     ;@
                                                                   @@: .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8  @ :@
                                                               @.   C@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.    @@
                                                                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                           @@@@            t@@@;   @@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@:
                                            @@.                @@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@        .@@@@
      @@@1@@@@;;@@@@8   @@    f@@   @@@@@C  @@    @@@@@@        @@@@     L  t@   @@   @@@@  t@@@      @@@@@@0
      @@@@i8@@@@8i@@@@ 8@@@   @@@  @@@C@@@ C@@@ @@@@@@@@@      @@@L          @   @@   @@@    @     ,    @@0
      @@@   @@@@   @@@ 8@@@   @@@  @@@@@   C@@@ @@@           i@@@   G@@@    @   @@   @@@    f          @@@@@@@81
      @@@   @@@@   @@@ 8@@@   @@@    C@@@@,C@@@ @@@        8@. @@@   G@@@    @   @@   @@@    f         :@@t,              ,,;;;iiii
      @@@   @@@@   @@@  @@@@@@@@@ @@@@L@@@8C@@@ @@@@@@@@@  @@@@@@@;          @   @@          @          @@
      @@@    @@    @@@   @@@@@@G   @@@@@@   @@.   @@@@@@         @@@     .   @   @@@:      @@@@@       @@@@8
                                                         @@.,@@@@@    80    L@@@@@@@@@@@@@@@@@@@@@@@@@@@80@@
                                                                 @L        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                                                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@0
                                                               @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                                             @       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@0  @8
                                                                      0@@@@@@@@@@@@@@@@@@@@@@@@@@@@@f  @@@@    @@f
                                                                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@ ,@@.   .@@@     8@8
                                                                   1@C  @f f@@@@@@@ 8@@@@@@@@L  @@  @@L     @@@
                                                                       @@  8    0@       C  @;   8@   @@      @@,
                                                                           @                 @          @@      8@
                                                                               @                           @1
                                                                              G
                                                                                  1,
                                                                                @@@@@
                                                                                 @@@
      EOL
      puts 'Booting Envoy'
      puts "Running with Rails application #{Rails.application.class.parent_name} in #{Envoy.env}" if defined? Rails
      puts "Version: #{Envoy::VERSION} (Helpless Alpha)"
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
