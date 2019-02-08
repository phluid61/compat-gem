if RUBY_VERSION < '2.5'
  class Array
    alias append push
    alias prepend unshift
  end

  class <<Dir
    ##
    # Calls the block once for each entry except for “.” and “..” in the named directory, passing the filename of each entry as a parameter to the block.
    #
    # If no block is given, an enumerator is returned instead.
    #
    def each_child dirname, **encoding
      return enum_for(:each_child, dirname, **encoding) unless block_given?
      open(dirname, **encoding) do |dh|
        dh.each do |child|
          yield child unless child == '.' || child == '..'
        end
      end
    end

    ##
    # Returns an array containing all of the filenames except for “.” and “..” in the given directory. Will raise a +SystemCallError+ if the named directory doesn't exist.
    #
    # The optional _encoding_ keyword argument specifies the encoding of the directory. If not specified, the filesystem encoding is used.
    #
    def children dirname, **encoding
      each_child(dirname, **encoding).to_a
    end
  end

  class Exception
    def __summary highlight
      if highlight
        if message.nil? || message.empty?
          "\e[1;4munhandled exception\e[0m"
        else
          "\e[1m#{message} (\e[4m#{self.class.name}\e[24m)\e[0m"
        end
      else
        if message.nil? || message.empty?
          "unhandled exception"
        else
          "#{message} (#{self.class.name})"
        end
      end
    end

    def __full_message_bottom highlight
      bt = backtrace.dup
      main_line = bt.shift + ': ' + __summary(highlight)

      length = Math.log10(bt.length+1).ceil
      ary = bt.each_with_index.reverse_each.map{|line, i| "\t%#{length}d: from %s" % [i+1, line] }
      if respond_to?(:cause) && cause
        ary = cause.__full_message_bottom(highlight) + ary
      end
      ary.push main_line
      ary
    end

    def __full_message_top highlight
      bt = backtrace.dup
      main_line = bt.shift + ': ' + __summary(highlight)

      ary = bt.map{|line| "\tfrom #{line}" }
      ary.unshift main_line
      if respond_to?(:cause) && cause
        ary += cause.__full_message_top(highlight)
      end
      ary
    end

    ##
    # Returns formatted string of exception. The returned string is formatted using the same format that Ruby uses when printing an uncaught exceptions to stderr.
    #
    # If highlight is true the default error handler will send the messages to a tty.
    #
    # order must be either of :top or :bottom, and places the error message and the innermost backtrace come at the top or the bottom.
    #
    # The default values of these options depend on $stderr and its tty? at the timing of a call.
    #
    def full_message highlight: true, order: :bottom
      case order
      when :top
        ary = __full_message_top(highlight)
        ary
      when :bottom
        if highlight
          bottom_header = "\e[1mTraceback\e[0m"
        else
          bottom_header = "Traceback"
        end
        ary = __full_message_bottom(highlight)
        ary.unshift "#{bottom_header} (most recent call last):"
        ary
      else
        raise ArgumentError, "expected :top or :bottom as order: #{order.inspect}"
      end
    end
  end

  # TODO: File.lutime ??

  class Hash
    ##
    # Returns a hash containing only the given keys and their values.
    def slice *keys
      keys.each_with_object({}) do |key, hsh|
        next unless key? key
        hsh[key] = self[key]
      end
    end

    ##
    # Returns a new hash with the results of running the block once for every key. This method does not change the values.
    #
    # If no block is given, an enumerator is returned instead.
    #
    def transform_keys &_block # :yields: key
      return enum_for(:transform_keys) unless block_given?
      hsh = {}
      each do |k, v|
        hsh[ yield k ] = v
      end
      hsh
    end

    ##
    # Invokes the given block once for each key in hsh, replacing it with the new key returned by the block, and then returns hsh. This method does not change the values.
    #
    # If no block is given, an enumerator is returned instead.
    #
    def transform_keys! &block # :yields: key
      return enum_for(:transform_keys!) unless block_given?
      replace transform_keys(&block)
    end
  end

  # TODO: IO#pread, #pwrite

  class Integer
    ##
    # Returns +true+ if all bits of +int & mask+ are +1+.
    def allbits? mask
      (self & mask) == mask
    end

    ##
    # Returns +true+ if any bits of +int & mask+ are +1+.
    def anybits? mask
      (self & mask) != 0
    end

    ##
    # Returns +true+ if no bits of +int & mask+ are +1+.
    def nobits? mask
      (self & mask) == 0
    end

    ##
    # Returns (modular) exponentiation as:
    #
    #    a.pow(b)     #=> same as a**b
    #    a.pow(b, m)  #=> same as (a**b) % m, but avoids huge temporary values
    #
    # FIXME: avoid huge temporary variables
    #
    def pow b, *m
      raise ArgumentError if m.length > 1
      if m.empty?
        self ** b
      else
        raise ArgumentError, 'Integer#pow() 2nd argument not allowed unless a 1st argument is integer' unless b.is_a? Integer
        raise ArgumentError, 'Integer#pow() 1st argument cannot be negative when 2nd argument specified' if b < 0
        raise ArgumentError, 'Integer#pow() 2nd argument not allowed unless all arguments are integers' unless m[0].is_a? Integer
        (self ** b) % m[0]
      end
    end
  end

  class <<Integer
    ##
    # Returns the integer square root of the non-negative integer +n+, i.e. the largest non-negative integer less than or equal to the square root of +n+.
    #
    # Equivalent to +Math.sqrt(n).floor+, except that the result of the latter code may differ from the true value due to the limited precision of floating point arithmetic.
    #
    # If +n+ is not an Integer, it is converted to an Integer first. If +n+ is negative, a Math::DomainError is raised.
    #
    def sqrt n
      n = n.to_i
      raise Math::DomainError if n < 0
      Math.sqrt(n).floor
    end
  end

  class IPAddr
    ##
    # Returns true if the ipaddr is a link-local address. IPv4 addresses in 169.254.0.0/16 reserved by RFC 3927
    # and Link-Local IPv6 Unicast Addresses in fe80::/10 reserved by RFC 4291 are considered link-local.
    #
    def link_local?
      case @family
      when Socket::AF_INET
        @addr & 0xffff0000 == 0xa9fe0000 # 169.254.0.0/16
      when Socket::AF_INET6
        @addr & 0xffc0_0000_0000_0000_0000_0000_0000_0000 == 0xfe80_0000_0000_0000_0000_0000_0000_0000
      else
        raise AddressFamilyError, 'unsupported address family'
      end
    end

    ##
    # Returns true if the ipaddr is a loopback address.
    #
    def loopback?
      case @family
      when Socket::AF_INET
        @addr & 0xff000000 == 0x7f000000
      when Socket::AF_INET6
        @addr == 1
      else
        raise AddressFamilyError, 'unsupported address family'
      end
    end
  end

  module Kernel
    ##
    # Yields self to the block and returns the result of the block.
    def yield_self
      return enum_for(:yield_self) { 1 } unless block_given?
      yield self
    end
  end

  class Method
    ##
    # Invokes the block with +obj+ as the proc's parameter like Proc#call. It is
    # to allow a proc object to be a target of +when+ clause in a case statement.
    def === obj
      call(obj)
    end
  end

  class Module
    public :attr, :attr_reader, :attr_writer
  end

  class Pathname
    def glob p1, *p2
      dest = (self + p1).to_s
      if block_given?
        Dir.glob(dest, *p2){|fn| yield (self + fn) }
      else
        Dir.glob(dest, *p2).map{|fn| self + fn }
      end
    end
  end

  class <<Process
    ##
    # Returns the status of the last executed child process in the current thread.
    #
    # If no child process has ever been executed in the current thread, this returns +nil+.
    #
    def last_status
      $?
    end
  end

  class <<Random
    alias urandom raw_seed
  end

  module Random::Formatter
    # SecureRandom.choose generates a string that randomly draws from a
    # source array of characters.
    #
    # The argument _source_ specifies the array of characters from which
    # to generate the string.
    # The argument _n_ specifies the length, in characters, of the string to be
    # generated.
    #
    # The result may contain whatever characters are in the source array.
    #
    #   require 'securerandom'
    #
    #   SecureRandom.choose([*'l'..'r'], 16) #=> "lmrqpoonmmlqlron"
    #   SecureRandom.choose([*'0'..'9'], 5)  #=> "27309"
    #
    # If a secure random number generator is not available,
    # +NotImplementedError+ is raised.
    private def choose(source, n)
      size = source.size
      m = 1
      limit = size
      while limit * size <= 0x100000000
        limit *= size
        m += 1
      end
      result = ''.dup
      while m <= n
        rs = random_number(limit)
        is = rs.digits(size)
        (m-is.length).times { is << 0 }
        result << source.values_at(*is).join('')
        n -= m
      end
      if 0 < n
        rs = random_number(limit)
        is = rs.digits(size)
        if is.length < n
          (n-is.length).times { is << 0 }
        else
          is.pop while n < is.length
        end
        result.concat source.values_at(*is).join('')
      end
      result
    end

    ALPHANUMERIC = [*'A'..'Z', *'a'..'z', *'0'..'9']
    # SecureRandom.alphanumeric generates a random alphanumeric string.
    #
    # The argument _n_ specifies the length, in characters, of the alphanumeric
    # string to be generated.
    #
    # If _n_ is not specified or is nil, 16 is assumed.
    # It may be larger in the future.
    #
    # The result may contain A-Z, a-z and 0-9.
    #
    #   require 'securerandom'
    #
    #   SecureRandom.alphanumeric     #=> "2BuBuLf3WfSKyQbR"
    #   SecureRandom.alphanumeric(10) #=> "i6K93NdqiH"
    #
    # If a secure random number generator is not available,
    # +NotImplementedError+ is raised.
    def alphanumeric(n=nil)
      n = 16 if n.nil?
      choose(ALPHANUMERIC, n)
    end
  end

  class Set
    def === other
      include? other
    end

    ##
    # Resets the internal state after modification to existing elements and returns self.
    #
    # Elements will be reindexed and deduplicated.
    #
    def reset
      if @hash.respond_to? :rehash
        @hash.rehash
      else
        raise "can't modify frozen #{self.class.name}" if frozen?
      end
      self
    end
  end

  class String
    alias __old_casecmp casecmp
    def casecmp other_str
      return unless other_str.respond_to? :to_str
      __old_casecmp other_str
    end

    alias __old_casecmp? casecmp?
    def casecmp? other_str
      return unless other_str.respond_to? :to_str
      __old_casecmp? other_str
    end

    ##
    # Returns a copy of _str_ with leading +prefix+ deleted.
    def delete_prefix prefix
      return dup unless start_with? prefix
      return dup if prefix.empty?
      self[prefix.length..-1]
    end

    ##
    # Deletes leading +prefix+ from _str_, returning +nil+ if no change was made.
    def delete_prefix! prefix
      return unless start_with? prefix
      return if prefix.empty?
      self[0...prefix.length] = ''
      self
    end
  end

  # TODO: String#each_grapheme_cluster, #grapheme_clusters
  # TODO: String#undump

  class Thread
    def fetch sym, *default
      raise ArgumentError if default.length > 1
      return self[sym] if key? sym
      return default.first if default.length > 0
      return yield(sym) if block_given?
      raise KeyError
    end
  end
end

