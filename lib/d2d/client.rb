require 'd2d/client/version'
require 'd2d/client/session'
require 'd2d/client/response'
require 'd2d/client/request'

require 'json'
require 'faraday'

module D2D
  # Relais D2D Client
  module Client
    # A client configuration, which includes URIs, API keys, and other
    # identifiying information
    # @!attribute [rw] base_url
    #   @return [String] the URL of the Relais D2D server to use.
    # @!attribute  [rw] partnership_id
    #   @return [String] the Relais-assigned partnership ID.
    # @!attribute [rw] api_key
    #   @return [String] the (base 64 encoded?) D2D API key.
    # @!attribute [rw] library_symbol
    #   @return [String] the library symbol for your library
    # @!attribute [rw] patron_id
    #   @return [String] the ID of the patron making requests during this
    #   session. This parameter is optional when using #configure
    class Configuration
      # all supported attributes
      ATTRS = %i[
        base_url
        partnership_id
        api_key
        library_symbol
        patron_id
      ].freeze

      # supported attributes that are not required for a base configuration
      OPTIONAL_ATTRS = %i[patron_id].freeze

      attr_accessor(*ATTRS)

      # create a new configuration.
      # @param options [Hash] opts
      # @option opts [String] base_url: the base URL to the Relais D2D server
      # #
      def initialize(options = {})
        options.each do |opt, value|
          send "#{opt.to_sym}=", value.to_s if ATTRS.include?(opt.to_sym)
        end
      end

      # check that all required attribues have been set on this object
      # this object.
      # @see ATTRS
      # @see OPTIONAL_ATTRS
      def complete?
        find_missing.empty?
      end

      # gets a configuration based on this one,
      # overlaying supplied options
      # useful for, e.g. getting patron-based sessions from
      # a shared base configuration
      def update(options = {})
        Configuration.new(to_h.merge(options))
      end

      # Outputs the configuration as a hash.  Useful for creating multiple
      # similar configurations for different borrowing consortia.
      # @return[Hash<Symbol, String] the attributes of this configuration
      # as a hash.
      def to_h
        @to_h ||= {
          api_key: api_key,
          partnership_id: partnership_id,
          base_url: base_url,
          library_symbol: library_symbol,
          patron_id: patron_id
        }
        # always return a copy
        Marshal.load(Marshal.dump(@to_h))
      end

      def find_missing
        (ATTRS - OPTIONAL_ATTRS).select do |attr|
          res = send attr
          res.nil?
        end
      end
    end

    # The default configuration.
    # @see D2D::Client::Session
    def self.configuration
      @configuration ||= Configuration.new
    end

    # Create a base configuration that willbbe used as the default
    # template.  This will throw an ArgumentError unless the block
    # leaves the configuration in a "complete enough" state.
    # @yield the default configuration
    def self.configure
      config = Configuration.new
      yield config
      unless config.complete?
        msg = 'D2D Client configuration is incomplete, missing'
        config.find_missing { |a| msg << "\t#{a}" }
        raise ArgumentError, msg
      end
      @configuration = config
    end
  end
end
