#lib = File.expand_path('../lib', __FILE__)
#$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
#require 'd2d/client/version'

Gem::Specification.new do |spec|
  spec.name          = 'd2d-client'
  spec.version       = File.read('VERSION')
  spec.authors       = ['Adam Constabaris']
  spec.email         = ['adjam@noreply.github.com']

  spec.summary       = %q{A wrapper that handles making calls to the Relais D2D API.}
  spec.description   = %q{I am supposed to get more specific and nlongwinded here I guess.}
  spec.homepage      = 'https://github.com/trln/d2d-client'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the
  # 'allowed_push_host' to allow pushing to a single host or delete this
  # section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday'

  spec.add_development_dependency 'bundler', '> 2.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3'
end
