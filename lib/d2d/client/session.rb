module D2D
  module Client
    # Primary class for interacting with Relais D2D API.
    # Typically one will be instantiated on behalf of a patron,
    # based on a Configuration that has already been created with
    #
    # @attr_reader [D2D::Client::Patron] patron D2D API-specific information
    # about the patron derived from creating a session for them with the D2D
    # API.
    # @attr_writer [Faraday::Client] an HTTP client implementation to be
    # used when making requests to D2D.  Instances of this class will
    # create their own unless this is set.
    class Session
      attr_writer :client

      attr_reader :patron

      attr_accessor :logger

      # Creates a new instance of this class from JSON data created
      # by `instance.to_json`
      # @param json_data [Hash|String] the serialized data representing
      # and instnace of this class. If a `String`, JSON.parse will be invoked,
      # and the result of that is expected to be a `Hash`.
      # @see #to_json
      def self.from_json(json_data)
        json_data = JSON.parse(json_data) if json_data.is_a?(String)
        raise(StandardError, "Cannot deserialize session from #{json_data.class}") unless json_data.is_a?(Hash)

        options = Hash[json_data.map { |k, v| [k.to_sym, v] }]
        options[:patron] = Patron.from_h(options[:patron]) if options[:patron]
        Session.new(options)
      end

      # Get a representation of this instance as a Hash.
      def to_h
        {
          'patron_id' => @config.patron_id,
          'patron' => @patron.to_h
        }
      end

      # Serialize this instance to JSON for storage in a Rails session.
      # @see D2D::Client::Session#from_json
      def to_json
        to_h.to_json
      end

      # Authenticaties the user (based on the `patron_id`
      # parameter in the constructor) against the D2D web service.
      #
      # This will be a no-op if the patron is already authenticated.
      # @see D2D::Client::Patron
      def authenticate!(force = false)
        return @patron if @patron && !force

        anon = @config.patron_id.gsub(/.(?=\d{4})/, '#')
        req = D2D::Client::Authentication.new(@config.to_h)
        begin
          resp = make_request(req)
        rescue StandardError => e
          @logger.warn("Unable to complete authentication request for patron #{anon}: #{e}")
          raise e
        end

        @logger.warn("Unable to create D2D session for #{anon}: #{resp.error_message || '(unknown)'}")
        raise(StandardError, resp.error_message) if resp.problem?

        @patron = resp.patron
      end

      # extract base options from configuration and patron
      def base_options
        aid = @patron && @patron.aid
        keepers = %i[library_symbol partnership_id]
        # .slice is available in 2.5, but ...
        @config.to_h.select { |k, _| keepers.include?(k) }
               .merge(aid: aid)
      end

      # Executes a FindItem for the current user based on the current set of
      # parameters.
      # @see D2D::Client:FindItem
      def find_item(params = {})
        req = FindItem.new(base_options.merge(params))
        res = make_request(req)
        yield res if block_given?
        res
      end

      def request_item(params = {})
        req = RequestItem.new(base_options.merge(params))
        res = make_request(req)
        yield res if block_given?
        res
      end

      # Creates a new session, using configuration options
      # @param [Hash] options the options to create the session with
      # @option options [String] :patron_id the ID of the patron on whose
      # behalf the session is being created.  Normally this is the only
      # parameter requried to initiate a session.
      # @option options [D2D::Client::Configuration] :config the configuration
      # to use with this session.  Defaults to global default configuration
      # if not supplied.
      # @option options [Hash] :patron a hash representing a `D2D::Client::Patron`
      # instance that has perviously been authenticated.  Usually used when
      # deserializing an instance of this class that was previously serialized.
      #
      # A Note about logging: if the configuration contains a logger, that's
      # what will be used to log details from operations of this class.
      # If running inside the Rails environment, the Rails.logger will be used.
      # Otherwise, a standard Logger to `$stderr` set at `FATAL` level is
      # what will be used.
      # @see D2D::Client
      # @see D2D::Client::Patron
      def initialize(options = {})
        config = options.fetch(:config, D2D::Client.configuration)
        @config = config.update(options)
        @logger = find_logger(config)
        @patron = options[:patron] || authenticate!(options.fetch(:reauth, false))
        @client = options[:client] if options[:client]
      end

      # gets the client in use for this session
      def client
        @client || build_client
      end

      def close
        @client && @client.close
      end

      # makes the request to the Relais endpoint and retrieves the response
      # if the endpoint responds with a non-200 status code, raises
      # an exception.
      # @param [Request] request to be executed.
      def make_request(request)
        body = request.body
        resp = client.post do |req|
          req.url request.path
          req.headers['Content-Type'] = 'application/json'
          req.body = body.respond_to?(:each) ? body.to_json : body
        end
        @logger.debug(resp.body)
        request.response.new(JSON.parse(resp.body))
      end

      private

      # Looks up the appropriate logger.  In order of preference
      # 1. logger from configuration (if present)
      # 2. `Rails.logger if defined? Rails`
      # 3. New Logger($stderr, FATAL)
      def find_logger(config)
        if config.logger
          config.logger
        elsif defined? Rails
          Rails.logger
        else
          logger = Logger.new($stderr)
          logger.level = Logger::FATAL
          logger
        end
      end

      # simple client open
      def build_client
        Faraday.new(url: @config.base_url)
      end
    end
  end
end
