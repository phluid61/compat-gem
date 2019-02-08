
if RUBY_VERSION < '2.6'
  class Hash
  end

  module Kernel
    alias_method :then, :yield_self
  end

  class Enumerator
    class Chain
      include Enumerable

      ##
      # Generates an Enumerator::Chain object from the given
      # enumerable objects.
      #
      def initialize *enums
        @chain = enums
      end

      ##
      # Returns the total size of the enumerator chain calculated by
      # summing up the size of each enumerable in the chain.  If any of the
      # enumerables reports its size as nil or Float::INFINITY, that value
      # is returned as the total size.
      #
      def size
        total = 0
        @chain.each do |enum|
          size = enum.size
          return size if size.nil? || size == Float::INFINITY
          #return nil unless size.is_a? Integer
          total += size
        end
        total
      end

      ##
      # Iterates over the first enumerable by calling the "each" method on
      # it with the given arguments until it is exhausted, then proceeds to
      # the next enumerable, until all of the enumerables are exhausted.
      #
      # If no block is given, returns an enumerator.
      #
      def each *args, &block
        return enum_for(:each, *args) unless block_given?
        @chain.each do |enum|
          enum.each(*args, &block)
        end
        self
      end

      ##
      # Rewinds the enumerator chain by calling the "rewind" method on each
      # enumerable in reverse order.  Each call is performed only if the
      # enumerable responds to the method.
      #
      def rewind
        @chain.reverse_each do |enum|
          enum.rewind if enum.respond_to? :rewind
        end
      end

      ##
      # Returns a printable version of the enumerator chain.
      #
      def inspect
        "#<#{self.class.name}: ...>" #FIXME
      end
    end

    ##
    # Returns an Enumerator::Chain object generated from this enumerator
    # and given enumerables.
    #
    def chain(*enums)
      Enumerator::Chain.new(self, *enums)
    end

    ##
    # Returns an Enumerator::Chain object generated from this enumerator
    # and a given enumerable.
    #
    def +(enum)
      Enumerator::Chain.new(self, enum)
    end
  end

  class Proc
    ##
    # Returns a proc that is the composition of this proc and the given _g_.
    # The returned proc takes a variable number of arguments, calls _g_ with
    # them then calls this proc with the result.
    #
    def << g
      proc {|*args| call(g.call(*args)) }
    end

    ##
    # Returns a proc that is the composition of this proc and the given _g_.
    # The returned proc takes a variable number of arguments, calls this proc
    # with them then calls this _g_ with the result.
    #
    def >> g
      proc {|*args| g.call(call(*args)) }
    end
  end

  class Method
    ##
    # Returns a proc that is the composition of this method and the given _g_.
    # The returned proc takes a variable number of arguments, calls _g_ with
    # them then calls this method with the result.
    #
    def << g
      proc {|*args| call(g.call(*args)) }
    end

    ##
    # Returns a proc that is the composition of this method and the given _g_.
    # The returned proc takes a variable number of arguments, calls this method
    # with them then calls this _g_ with the result.
    #
    def >> g
      proc {|*args| g.call(call(*args)) }
    end
  end

  # TODO: Binding#source_location ?
  # TODO: add `exception:` to Kernel#system ?

  # (in stdlib)
  module FileUtils
    class <<self
      ##
      # Hard link +src+ to +dest+. If +src+ is a directory, this method links all
      # its contents recursively. If +dest+ is a directory, links +src+ to +dest/src+.
      #
      # +src+ can be a list of files.
      #
      def cp_lr src, dest, noop: nil, verbose : nil,
                dereference_root: true, remove_destination: false
        fu_output_message "cp -lr#{remove_destination ? ' --remove-destination' : ''} #{[src,dest].flatten.join ' '}" if verbose
        return if noop
        fu_each_src_dest(src, dest) do |s, d|
          link_entry s, d, dereference_root, remove_destination
        end
      end
    end
  end
end

