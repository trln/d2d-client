require 'json'
require 'stringio'

module Helpers
  def capture_stdout
    prev_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = prev_stdout
  end

  def capture_stderr
    prev_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = prev_stderr
  end

  def load_data(path)
    filename = File.expand_path(File.join('data', path), __dir__)
    raise StandardError, "#{filename} not found in spec/data" unless File.file?(filename)

    File.open(filename) { |f| yield f } if block_given?
    return File.read(filename) unless block_given?

    filename
  end

  def self.auth_success_response
    {
      'AuthorizationId' => '__authorization_id__',
      'LibrarySymbol' => 'TRLN',
      'Iso639_2_LangCode' => 'en_US',
      'FirstName' => 'Sample',
      'LastName' => 'User',
      'AllowLoandAddRequest' => true,
      'AllowCopyAddRequest' => false,
      'AllowSelDelivLoanChange' => true,
      'AllowSelDelivCopyChange' => true
    }
  end

  # replaces placeholder values in a hash (recursively)
  # any values in hash (or in values of nested hashes of `hash`
  # of the form `__[something]__` will be replaced by the value
  # of the `something` key from `replacements`.
  # This allows creating template JSON responses that can be reused
  # for different tests.
  # @param hash [Hash] the hash to be (destructively) filled out.
  # @param replacements[Hash] a hash of keys with replacement values
  # @param rekey [Bool] whether the values in the'replacements' hash
  #    have already been transformed with leading and trailing double
  #    underscores.
  # @example Single level replacement
  #   "orig = { foo: '__bar__' }"
  #   "repl = { bar: 'This will be in the result' }"
  #   "hash_fill!(orig, repl) => { foo: 'This will be in the result' }""
  #
  # @example nested replacement
  #    "orig = { foo: { bar: '__baz__' } }"
  #    "repl = "{ baz: 'Bazzzzz!' }"
  #    "hash_fill!(orig,repl)) => { foo: { bar: 'Bazzzzz! } }"
  def self.hash_fill!(hash, replacements, rekey = true)
    repl = Hash[replacements.map do |k, v|
      [rekey ? "__#{k}__" : k, v]
    end]
    hash.each do |k, v|
      if v.is_a?(Array)
        hash[k] = v.map { |x| repl.key?(x) ? repl[x] : x }
      elsif v.is_a?(Hash)
        hash[k] = hash_fill!(v, repl, false)
      elsif repl.key?(v)
        hash[k] = repl[v]
      end
    end
    hash
  end

  def load_json(filename)
    JSON.parse(load_data("#{filename}.json"))
  end

  class MockRequest
    attr_accessor :headers, :body, :path
    def initialize
      @url = ''
      @headers = {}
      @body = ''
    end

    def url(path)
      @path = path
    end
  end

  class MockResponse
    attr_reader :status, :body
    def initialize(content, status = 200)
      @status = status
      @body = content.to_json
    end

    def problem?
      @status != 200
    end
  end

  # a mock client, which always produces a successful
  # response to an 'authenticate' request and a user-supplied
  # response to any other query.
  class MockClient
    def initialize(response)
      @response = response
    end

    # simulate Faraday request custommization
    # HTTP request is yielded to block, where URL, headers, and
    # body are set on 
    def post
      req = MockRequest.new
      yield req
      if req.path == D2D::Client::Authentication::PATH
        repl = { authorization_id: 'n0b4dg3s' }
        content = Helpers.hash_fill!(Helpers.auth_success_response, repl)
        return MockResponse.new(content)
      end
      @response
    end
  end
end
