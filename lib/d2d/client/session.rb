module D2D
  module Client
    # Primary class for interacting with Relais D2D API.
    # Typically one will be instantiated on behalf of a patron,
    # based on a Configuration that has already been created with
    class Session
      attr_accessor :client

      attr_reader :patron

      # Makes a request to authenicate the current patron.
      # This will be a no-op if the patron is already authenticated.
      def authenticate
        return @patron if @patron
        req = D2D::Client::Authentication.new(@config.to_h)
        resp = make_request(req)
        raise resp.error_message if resp.problem?
        resp.patron
      end

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
      # @param config [Configuration] the configuration to use
      # for the session.  If not provided, the default configuraiton
      # will be used.
      # @param options [Hash<String,Object] set of options to be passed
      # to customize the configuration
      #
      # # Example (in application initializer)
      # D2D::Client.configure do |c|
      #    c.base_url = 'https://relais.example.com'
      #    c.library_symbol = 'NCSU'
      #    c.api_key = 'my_api_key'
      # end
      # ...
      #
      # \#we now have a base configuration we can use as a template for
      # individual patrons.
      #
      # patron_session = D2D:Session.new(nil, patron_id: 'a_patron_id')
      # result = patron_session.find_item(isbn: '89047987378') # e.g.
      def initialize(config = nil, options = {})
        @config = if config.nil? || config == 'DEFAULT'
                    D2D::Client.configuration.update(options)
                  else
                    config.update(options)
                  end
        @client = options[:client] if options[:client]
        @patron = authenticate
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
      # rubocop:disable AbcSize
      def make_request(request)
        body = request.body
        resp = client.post do |req|
          req.url request.path
          req.headers['Content-Type'] = 'application/json'
          req.body = body.respond_to?(:each) ? body.to_json : body
        end
        return request.response.new(JSON.parse(resp.body)) if resp.status == 200
        raise "Request failed: #{resp.reason_phrase} : #{resp.body}"
      end
      # rubocop:enable AbcSize

      private

      # simple client open
      def build_client
        Faraday.new(url: @config.base_url)
      end
    end
  end
end
