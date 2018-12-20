module D2D
  module Client
    # Logger implementation that logs nothing
    class NullLogger
      no_log = ->(msg) {}
      not_enabled = -> { false }
      %i[debug info warn error fatal unknown].each do |lvl|
        define_method(lvl, &no_log)
        define_method("#{lvl}?".to_sym,  &not_enabled)
      end
    end
  end
end
