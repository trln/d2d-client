module D2D
  module Client
    # Base class for requests to D2D API
    module Request
      attr_reader :options, :body, :path

      def init(params = {})
        @path = self.class::PATH
        @path += "?aid=#{params[:aid]}" unless params[:authing]
        @body = { PartnershipId: params[:partnership_id],
                  LibrarySymbol: params[:library_symbol] }
        @body
      end
    end

    module SearchRequest
      include Request
      EXACT_TERMS = %i[isbn issn lccn oclc].freeze

      FILTER_FIELDS = %i[pubdate format].freeze

      def search_options(options)
        if exact_search?(options)
          prepare_exact_search(options)
        else
          prepare_bib_search(options)
        end
      end

      def exact_search?(options)
        EXACT_TERMS.any? { |term| options.include? term }
      end

      def prepare_exact_search(options)
        term = EXACT_TERMS.first { |t| options.include? t }
        { ExactSearch:
            arrayify(options[term]).map do |value|
              { Type: term.to_s.upcase, Value: value }
            end }
      end

      # Prepares a bibliogtraphic search
      def prepare_bib_search(options)
        return {} if exact_search?(options)
        unless options[:title]
          msg = 'ExactSearch not specified and :title not provided'
          raise ArgumentError, msg
        end
        query = { Title: options[:title] }
        query << { Author: arrayify(options[:author]) } if options[:author]
        filters = create_filters(options)
        query.update(ResultFilter: filters) unless filters.empty?
        { BibSearch: query }
      end

      def create_filters(options)
        filters = {}
        filters[:Include] = build_filter(options[:include]) if options[:include]
        filters[:Exclude] = build_filter(options[:exclude]) if options[:exclude]
        filters
      end

      def build_filter(params)
        Hash[
          params.select { |f| FILTER_FIELDS.include?(f) }.map do |f, v|
            if f == :pubdate
              [:PublicationDate, arrayify(v)]
            elsif f == :format
              [:Format, arrayify(v)]
            end
          end
        ]
      end

      def arrayify(value)
        value.respond_to?(:each) ? value.map(&:to_s) : [value.to_s]
      end
    end

    # Encapsulates a "FindItem" request
    class FindItem
      include SearchRequest
      PATH = '/dws/item/available'.freeze

      # Creates a FindItem request.  Typically this is invoked by an active
      # Session object.
      # @param [Hash] opts the options for the request
      # @option opts [String, Array<String>] isbn: the ISBN(s) to be queried
      # @option opts [String, Array<String>] issn: the ISSN(s) to be queried
      # @option opts [String, Array<String>] lccn: the LCCN(s) to be queried
      # @option opts [String, Array<String>] oclc: the OCLC number(s) to be
      # queried.
      # @option opts [String] title: the title to be searched for
      # @options opts [String] author: the author to be searched for
      # @options opts [Hash] include: 'include' filters to be applied to any
      # results
      # @options opts [Hash] exclude: 'exclude' filters to be applied to any
      # results
      #
      # If any identifiers (ISSN, ISBN, OCLC, LCCN) are provided, an
      # "ExactSearch" will be performed, even if title and/or author are
      # supplied.
      #
      # If no identifiers are supplied, a "BibSearch" will be performed.
      # If we are performing a BibSearch, title is required.
      # Filters:
      # Filters are specified as hashes whose keys may include pubDate: and/or
      # format: -- the values are always arrays of values (e.g. for 2001-2009,
      # `include: { pubdate: 2001.upto(2009).map(&:to_s) }`
      #
      # NOTE: this query returns at most one item, and if
      # the supplied criteria match any item held at the patron's home
      # institution, the 'avaialble' attribute on the response will be
      # `false.`
      def initialize(options = {})
        req = init(options)
        req.update(_search_options(options))
        @body = req
      end

      # the class of the response
      def response
        FindItemResponse
      end

      def exact_search?(options)
        EXACT_TERMS.any? { |term| options.include? term }
      end

      def prepare_exact_search(options)
        term = EXACT_TERMS.first { |t| options.include? t }
        { ExactSearch:
            arrayify(options[term]).map do |value|
              { Type: term.to_s.upcase, Value: value }
            end }
      end

      # Prepares a bibliogtraphic search
      def prepare_bib_search(options)
        return {} if exact_search?(options)
        unless options[:title]
          msg = 'ExactSearch not specified and :title not provided'
          raise ArgumentError, msg
        end
        query = { Title: options[:title] }
        query << { Author: arrayify(options[:author]) } if options[:author]
        filters = create_filters(options)
        query.update(ResultFilter: filters) unless filters.empty?
        { BibSearch: query }
      end
    end

    # Request an Item.
    class RequestItem
      include SearchRequest
      PATH = '/dws/item/add'.freeze

      def initialize(options = {})
        req = init(options)
        req.update(search_options(options))
        req[:PickupLocation] = options[:pickup_location]
        req[:Notes] = options[:note] if options[:note]
        @body = req
      end

      def response
        RequestItemResponse
      end
    end

    # An authentication request, make one of these at the beginning of a
    # session.
    class Authentication
      include Request
      PATH = '/portal-service/user/authentication'.freeze

      def initialize(options = {})
        @body = init(options.merge(authing: true))

        @body.update(
          ApiKey: options[:api_key],
          UserGroup: 'patron'
        )
        @body[:PatronId] = options[:patron_id] if options[:patron_id]
      end

      def response
        AuthenticationResponse
      end
    end
  end
end
