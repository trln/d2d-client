# D2D::Client

A ruby gem that encapsulates the Relais D2D API for interlibrary loan among
members of a borrowing consortium.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'd2d-client',  git: 'https://github.com/trln/d2d-client'
```

And then execute:

    $ bundle

To run tests:

    $ bundle exec rspec

Or install it yourself as:

    $ bundle exec rake install


## Usage

The D2D API is organized around the idea that queries are always being made on
behalf of a patron.  After an initial 'authentication' request that establishes
the patron's identity and permissions, subsequent requests use a temporary
authorization ID.  This has been encapsulated in this gem as a
`D2D::Client::Session` object, which can be used to make multiple requests on a
patron's behalf.

In the context of a Rails application, where objects in a Rails session may be
serialized, you'll need to take some extra steps to serialize and deserialize
the D2D session in the Rails session.  To serialize, call `.to_json` on a live
Session object, and call
`D2D::Client::Session.from_json(JSON.parse(serialized_session_object))` to
deserialize.

Since one primary use case for this gem is within a long-running, multi-user
application such as Rails, we have further broken out a separate
`D2D::Client::Configuration` class and provided a way to initialize a template
configuration to be used as needed to create new `Session` objects.  Here is a
sample usage:

```ruby
# in config/initializers/d2d_client.rb

require 'd2d/client'

D2D:Client.configure do |c|
  c.api_key = # institutional API key
  c.library_symbol = # institutional library identifier
  c.partnership_id = 'TRLN' # e.g.
  c.base_url = 'https://some-relais.server.com'
end

# in some rails controller, where you know the patron ID and are making a
request on their behalf; note assumes we've require'd the gem already

d2d_session = D2D::Client::Session.new(patron_id: patron_id)
result = d2d_session.find_item(isbn: 'foo')
# is the patron able to request the item with the supplied ISBN from a 
# TRLN library *other than their own?* 

render :ill_not_available unless result.available?
```

All methods on the `D2D::Client::Session` instances (`find_item` and
`request_item` being the most prominent) that make a request to the D2D API
accept a block, to which they yield the appropriate `D2D::Client::Response`
instance.  All response objects support a `problem?` method, which echoes the
`Problem` key that is returned by responses from the D2D API itself that
indicate the request could not be
completed.  In this case, usually the `error_message` method will return the
error message. 

## D2D API and TRLN Direct

When providing parameters to a 'FindItem' or 'RequestItem' request, according
to the best information we currently have, D2D can only match on the ISBN.  You
may specify more than one value for the `:isbn` parameter, and D2D will match
by `OR`-ing them.  This means you should probably exercise some caution when
making requests or checking availability, depending on how confident you are
that the ISBNs you use to make the request match the ISBNs of the items you
want to request.

As of 2018-12-16, with TRLN Direct, the `:oclc` parameter used in `find_item` and `make_request` calls does not appear to match at all, and we did no testing with `:issn` (which is not relevant for our use case anyhow) or `:lccn`.  Pending further investigation, use `isbn:` exclusively.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 

Rubocop enforcment is in place, so please run `rubocop` and address any issues
it raises over the directory before pushing any commits.

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags.

(once we have it set up) 
you may push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/trln/d2d-client.

This gem is not endorsed by Relais International, or OCLC.
