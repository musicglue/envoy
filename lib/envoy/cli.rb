require_relative '../envoy'

module Envoy
  class CLI
    def initialize(arguments)
      @arguments = arguments
    end

    def setup
      run
    end

    def run
      puts 'Booting AssetRefinery'
      %w(INT TERM).each do |signal|
        begin
          trap signal do
            handle_signal(signal)
          end
        rescue ArgumentError
          puts "Signal #{sig} not supported"
        end
      end
      include_rails if rails_env?
      Envoy.start!
    end

    def rails_env?

    end

    private

    def handle_signal(signal)
      case signal
      when 'INT'
        Envoy.shutdown!
        fail Interrupt
      when 'TERM'
        Envoy.shutdown!
        fail Interrupt
      end
    end
  end
end
