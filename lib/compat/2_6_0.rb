
if RUBY_VERSION < '2.6'
  class Hash
  end

  module Kernel
    alias_method :then, :yield_self
  end
end

