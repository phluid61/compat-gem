if RUBY_VERSION < '2.4'
  module Comparable
    ##
    # Returns +min+ if +obj+ <=> +min+ is less than zero, +max+ if +obj+ <=> +max+ is greater than zero and +obj+ otherwise.
    def clamp min, max
      raise ArgumentError, "min argument must be smaller than max argument" if (min <=> max) > 0
      c = (self <=> min)
      return self if c == 0
      return min if c < 0
      c = (self <=> max)
      return max if c > 0
      self
    end
  end

  class <<Dir
    ##
    # Returns +true+ if the named file is an empty directory, false if it is not a directory or non-empty.
    def empty? path_name
      entries(path_name).reject('.').reject('..').empty? rescue false
    end
  end

  module Enumerable
    ##
    # Returns the sum of elements in an Enumerable.
    #
    # If a block is given, the block is applied to each element before addition.
    #
    # If +enum+ is empty, it returns +init+.
    #
    def sum init=0
      if block_given?
        each{|v| init += yield(v) }
      else
        each{|v| init += v }
      end
      init
    end

    ##
    # Returns a new array by removing duplicate values in +self+.
    #
    # See also Array#uniq.
    #
    def uniq
      hsh = {}
      if block_given?
        each{|v| hsh[yield(v)] = 1 }
      else
        each{|v| hsh[v] = 1 }
      end
      hsh.keys
    end
  end

  # TODO: Enumerator::Lazy#chunk_while
  # TODO: Enumerator::Lazy#uniq

  class <<File
    alias_method :empty?, :zero?
  end

  class Hash
    ##
    # Returns a new hash with the nil values/key pairs removed
    def compact
      hsh = {}
      each do |k, v|
        hsh[k] = v unless v.nil?
      end
      hsh
    end

    ##
    # Removes all nil values from the hash. Returns nil if no changes were made, otherwise returns the hash.
    def compact!
      hsh = {}
      any = false
      each do |k, v|
        if v.nil?
          any = true
        else
          hsh[k] = v
        end
      end
      return unless any
      replace hsh
      self
    end

    ##
    # Returns a new hash with the results of running the block once for every value. This method does not change the keys.
    #
    # If no block is given, an enumerator is returned instead.
    #
    def transform_values &_block # :yields: value
      return enum_for(:transform_values) unless block_given?
      hsh = {}
      each do |k, v|
        hsh[k] = yield v
      end
      hsh
    end

    ##
    # Invokes the given block once for each value in _hsh_, replacing it with the new value returned by the block, and then returns _hsh_. This method does not change the keys.
    #
    # If no block is given, an enumerator is returned instead.
    #
    def transform_values! &block # :yields: value
      return enum_for(:transform_values!) unless block_given?
      each do |k, v|
        store k, (yield v)
      end
      self
    end
  end

  class Integer
    ##
    # Returns the digits of +int+'s place-value representation with radix +base+ (default: +10+). The digits are returned as an array with the least significant digit as the first array element.
    #
    # +base+ must be greater than or equal to 2.
    #
    def digits base=10
      raise ArgumentError, "invalid radix #{base.inspect}" unless base >= 2
      to_s(base).reverse.each_char.map{|c| c.to_i(base) }
    end
  end

  class MatchData
    ##
    # Returns a Hash using named capture.
    #
    # A key of the hash is a name of the named captures. A value of the hash is a string of last successful capture of corresponding group.
    #
    def named_captures
      names.each_with_object({}){|n,h| h[n] = self[n] }
    end
  end

  class Numeric
    ##
    # Returns true if num is a finite number, otherwise returns false.
    def finite?
      true
    end

    ##
    # Returns +nil+, +-1+, or +1+ depending on whether the value is finite, +-Infinity+, or +\+Infinity+.
    def infinite?
      nil
    end
  end

  class Pathname
    ##
    # Tests the file is empty.
    #
    # See Dir#empty? and FileTest.empty?.
    #
    def empty?
      if directory?
        Dir.empty? to_s
      else
        File.empty? to_s
      end
    end
  end

  class Regexp
    ##
    # Returns a +true+ or +false+ indicates whether the regexp is matched or not ~~without updating +$~+ and
    # other related variables.~~ If the second parameter is present, it specifies the position in the string
    # to begin the search.
    #
    def match? str, *pos
      raise "wrong number of arguments (#{args.length} for 1..2)" if pos.length > 1
      match(str, *pos) ? true : false
    end
  end

  class Set
    ##
    # Makes the set compare its elements by their identity and returns self. This method may not be supported by all subclasses of Set.
    #
    def compare_by_identity
      if @hash.respond_to?(:compare_by_identity)
        @hash.compare_by_identity
        self
      else
        raise NotImplementedError, "#{self.class.name}\##{__method__} is not implemented"
      end
    end
  end

  class String
    ##
    # Returns +true+ if +str+ and +other_str+ are equal after Unicode case folding, +false+ if they are not equal.
    #
    # +nil+ is returned if the two strings have incompatible encodings, or if +other_str+ is not a string.
    #
    def casecmp? other_str
      return unless other_str.respond_to? :to_str
      result = casecmp(other_str)
      return unless result
      result == 0
    end

    ##
    # Converts _pattern_ to a Regexp (if it isn't already one), then returns a +true+ or +false+ indicates
    # whether the regexp is matched _str_ or not ~~without updating +$~+ and other related variables.~~ If
    # the second parameter is present, it specifies the position in the string to begin the search.
    #
    def match? pattern, *pos
      raise "wrong number of arguments (#{args.length} for 1..2)" if pos.length > 1
      match(pattern, *pos) ? true : false
    end

    ##
    # Decodes _str_ (which may contain binary data) according to the format string, returning the first value extracted. See also String#unpack, Array#pack.
    def unpack1 format
      unpack(format).first
    end
  end

  class Symbol
    def casecmp? other_symbol
      return unless other_symbol.is_a? Symbol
      to_s.casecmp? other_symbol.to_s
    end

    def match? pattern, *pos
      to_s.match? pattern, *pos
    end
  end

  # TODO: Thread.report_on_exception ??

  module Warning
    def warn msg
      warn msg
      nil
    end
  end
end

