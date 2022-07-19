module D2D
  module Client
    unless const_defined? :VERSION
      VERSION = File.read("VERSION").strip.freeze
    end
  end
end
