module D2D
  module Client
    # Mixin for responses
    module Response
      attr_reader :data

      # Check whether the response indicates a problem
      def problem?
        data.nil? || data.key?('Problem')
      end

      def error_message
        problem? ? data['Problem']['ErrorMessage'] : ''
      rescue StandardError
        'unknown error'
      end

      def camel_casify(key)
        key.gsub(/([a-z0-9])([A-Z])/, '\1_\2').downcase
      end

      def response
        raise UnimplementedError, "#{self.class} needs to implement #{response}"
      end
    end

    # Encapsulates requesting permissions for a patron
    class Permissions
      attr_reader :add_loan, :copy_request, :delivery_selection_change

      def initialize(loan, copy, deliv)
        @add_loan = loan
        @copy_request = copy
        @delivery_selection_change = deliv
      end
    end

    # Encapsulates information about a patron, which is most of what's in the
    # response to an Authentication request
    class Patron
      ATTRS = %i[
        aid group
        library
        lang_code
        first_name
        last_name
        type
        permission
      ].freeze
      attr_reader(*ATTRS)

      def initialize(options = {})
        options.each do |k, v|
          instance_variable_set("@#{k}", v)
        end
      end

      # Initalizes a patron object from deserialized JSON response
      # to Authentication request
      # rubocop:disable MethodLength
      def self.from_json(data)
        Patron.new(
          aid: data['AuthorizationId'],
          group: data['UserGroup'],
          library: data['LibrarySymbol'],
          lang_code: data['Iso639_2_LangCode'],
          first_name: data['FirstName'],
          last_name: data['LastName'],
          type: data['PatronType'],
          permission: Permissions.new(
            data.fetch('AllowLoanAddRequest', false),
            data.fetch('AllowCopyAddRequest', false),
            data.fetch('AllowSelDelivLoanChange', false)
          )
        )
      end
      # rubocop:enable MethodLength
    end

    # response to an "Authentication" request to the D2D API
    class AuthenticationResponse
      include Response
      attr_reader :aid, :library_symbol, :user_group, :patron

      def initialize(data)
        @data = data
        if data['AuthorizationState'] && !data['AuthorizationState']['State']
          data['Problem'] = { 'ErrorMessage' => 'Not authorized' }
        end
        @aid = data['AuthorizationId'] || ''
        @library_symbol = data['LibrarySymbol'] || ''
        @patron = Patron.from_json(data)
        @user_group = data['UserGroup'] || ''
      end
    end

    # represents a response to a FindItem request
    # @attr available [Bool] whether the patron who performed the query can
    # request the item via the API
    # @attr pickup_location [Hash] a (possibly empty) list of code:/desc:
    #  hashes indicating places where the item can be requested for pickup
    #  (code is the value used in the API, desc: is the description to be
    #  shown to the user)
    class FindItemResponse
      include Response
      ATTRS = %i[
        available
        search_term
        request_link
        num_records
        pickup_locations
      ].freeze
      attr_reader(*ATTRS)

      def initialize(data)
        @data = data
        @available = data['Available'] || false
        @search_term = data['SearchTerm'] || '[unknown]'
        @num_records = data['OrigNumberOfRecords'] || 0
        @request_link = Hash[data.fetch('RequestLink', {}).map do |k, v|
          [camel_casify(k), v]
        end]
        @pickup_locations = deserialize_pickup_locations(data)
      end

      def deserialize_pickup_locations(data)
        data.fetch('PickupLocation', []).map do |l|
          {
            code: l['PickupLocationCode'],
            desc: l['PickupLocationDescription']
          }
        end
      end
    end

    # Response to a RequestItem call against the D2D API
    class RequestItemResponse
      include Response
      attr_reader :available, :request_number, :request_message, :request_link

      def initialize(data)
        @data = data
        @request_number = data['RequestNumber'] || '[unknown]'
        @request_messsage = data['RequestMessage'] || ''
        @request_link = Hash[data.fetch('RequestLink', {}).map do |k, v|
          [camel_casify(k), v]
        end]
      end
    end
  end
end
