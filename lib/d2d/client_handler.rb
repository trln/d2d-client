require 'd2d/client'

require 'json'
require 'faraday'
require 'logger'
require 'date'
require 'yaml'

module D2D
  # Relais D2D Client Handler for console commands
  class ClientHandler
    # all supported attributes
    ATTRS = %i[
      cmd
      patron_id
      config_h
      client
    ].freeze

    attr_accessor(*ATTRS)

    # create a new configuration.
    # @param options [Hash] opts
    # @option opts [String] base_url: the base URL to the Relais D2D server
    # #
    def initialize(options = {})
      options.each do |opt, value|
        send "#{opt.to_sym}=", value.to_s if ATTRS.include?(opt.to_sym)
      end
      # pry
      yaml_config = YAML.load_file('config/.d2d.yml')
      # pry
      self.config_h = yaml_config if yaml_config
      pry
      D2D:Client.config(self.config_h)
      pry
    end

    def to_h
      @to_h ||= {
        cmd: cmd,
        patron_id: patron_id,
        config_h: config_h
      }
      # always return a copy
      Marshal.load(Marshal.dump(@to_h))
    end

    def response()
      puts "response goes"
      puts self.to_h

    end
  end
end
