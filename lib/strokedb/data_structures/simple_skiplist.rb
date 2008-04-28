require 'thread'
require File.expand_path(File.dirname(__FILE__) + '/../util/class_optimization')

module StrokeDB
  # Implements a thread-safe skiplist structure.
  # Doesn't yield new skiplists
  class SimpleSkiplist
    include Enumerable
    
    DEFAULT_MAXLEVEL     = 32
    DEFAULT_PROBABILITY  = 1/Math::E
    
    attr_accessor :maxlevel, :probability
    
    def initialize(raw_list = nil, options = {})
      @maxlevel    = options[:maxlevel]    || DEFAULT_MAXLEVEL
      @probability = options[:probability] || DEFAULT_PROBABILITY
      @head, @tail = new_anchors(@maxlevel)
      if raw_list
        @head, @tail = unserialize_list!(raw_list)
      end
      @mutex       = Mutex.new
    end
    
    # Marshal API
    def marshal_dump
      raw_list = serialize_list(@head)
      {
        :options => {
          :maxlevel    => @maxlevel,
          :probability => @probability
          },
        :raw_list => raw_list
      }
    end
    
    def marshal_load(dumped)
      initialize(dumped[:raw_list], dumped[:options])
      self
    end
    
    # Tests whether skiplist is empty.
    #
    def empty?
      node_next(@head, 0) == @tail
    end
    
    # Complicated search algorithm
    # TODO: add reverse support
    # 
    def search(start_key, end_key, limit, offset, reverse, with_keys)
      offset ||= 0
      
      start_node = find_by_prefix(start_key, reverse)
      !start_node and return []
      
      start_node = skip_nodes(start_node, offset, reverse)
      !start_node and return []
    
      collect_values(start_node, end_key, limit, reverse, with_keys)
    end
    
    # 
    #
    def find_by_prefix(start_key, reverse)
      # TODO: add reverse support
      dir = dir_for_reverse(reverse)
      x = anchor(reverse) # head [FIXME: change method name]
      # if no prefix given, just return a first node
      !start_key and return node_next(x, 0, dir)
      
      level = node_level(x)
      while level > 0
        level -= 1
        xnext = node_next(x, level, dir)
        while node_compare(xnext, start_key) < 0
          x = xnext
          xnext = node_next(x, level, dir)
        end
      end
      xnext == anchor(!reverse) and return nil
      node_key(xnext)[0, start_key.size] != start_key and return nil
      xnext
    end
    
    # 
    # 
    def skip_nodes(node, offset, reverse)
      dir = dir_for_reverse(reverse)
      tail = @tail
      while offset > 0 && node != tail
        node = node_next(node, 0, dir)
        offset -= 1
      end
      offset <= 0 ? node : nil
    end
    
    # 
    #
    def collect_values(x, end_prefix, limit, reverse, with_keys)
      dir = dir_for_reverse(reverse)
      values = []
      meth = method(with_keys ? :node_pair : :node_value)
      tail = anchor(!reverse)
      limit ||= Float::MAX
      end_prefix ||= ""
      pfx_size = end_prefix.size
      while x != tail
        node_key(x)[0, pfx_size] > end_prefix and return values
        values.size >= limit and return values
        values << meth.call(x).freeze
        x = node_next(x, 0, dir)
      end
      values
    end
    
    # First key of a non-empty skiplist (nil for empty one)
    #
    def first_key
      first = node_next(@head, 0)
      return first ? first[1] : nil
    end
    
    # Insert a key-value pair. If key already exists,
    # value will be overwritten.
    #
    #  <i> is a new node
    #  <M> is a marked node in a update_list
    #  <N> is next node to <M> which reference must be updated. 
    #
    #  M-----------------> i <---------------- N ...
    #  o ------> M ------> i <------ N ... 
    #  o -> o -> o -> M -> i <- N ....
    #
    def insert(key, value, __level = nil)
      @mutex.synchronize do
        newlevel = __level || random_level
        x = anchor
        level = node_level(x)
        update = Array.new(level)
        x = find_with_update(x, level, key, update)
        
        # rewrite existing key
  	    if node_compare(x, key) == 0
  	      node_set_value!(x, value)
    	  # insert in a middle
    	  else
    	    level = newlevel
    	    newx = new_node(newlevel, key, value)
  	      while level > 0
  	        level -= 1
  	        node_insert_after!(newx, update[level], level)
          end
    	  end
      end
    	self
  	end
  	
  	def find_with_update(x, level, key, update) #:nodoc:
  	  while level > 0
        level -= 1
        xnext = node_next(x, level)
        while node_compare(xnext, key) < 0
          x = xnext
          xnext = node_next(x, level)
        end
        update[level] = x
      end
      xnext
	  end
  	
    # Find is thread-safe and requires no mutexes locking.
    def find_nearest_node(key) #:nodoc:
      x = anchor
      level = node_level(x)
      while level > 0
        level -= 1
        xnext = node_next(x, level)
        while node_compare(xnext, key) <= 0
          x = xnext
          xnext = node_next(x, level)
        end
      end
      x
    end
    
    declare_optimized_methods(:Java) do
      # Temporary off due to:
      # ./vendor/java_inline.rb:19: cannot load Java class javax.tools.ToolProvider (NameError)
      #
      # require 'vendor/java_inline'
      # inline(:Java) do |builder|
      #   builder.package "org.jruby.strokedb"
      #   builder.import  "java.lang.reflect.*"
      #   builder.java %{
      #     public static Object find_Java(String key)
      #     {
      #       Object o = new Object();
      #       return o;
      #     /*Class[] param_types = new Class[1];
      #       param_types[0] = String;
      #       Method method = this.getClass().getMethod("find", param_types);
      #       Object[] invokeParam = new Object[1];
      #       invokeParam[0] = key;
      # 
      #       return method.invoke(this, invokeParam);
      #     */
      #     }
      #   }
      # end
    end
    declare_optimized_methods(:C) do
    end
    
    declare_optimized_methods(:X, :find_nearest_node, :find_with_update) do
      require 'rubygems'
      require 'inline'
      inline(:C) do |builder|
        builder.prefix %{
          static ID i_anchor, i_node_level;
          #define SS_NODE_NEXT(x, level) (rb_ary_entry(rb_ary_entry(x, 0), level))
          static int ss_node_compare(VALUE x, VALUE key)
          {
            if (x == Qnil) return 1;          /* tail */
            VALUE key1 = rb_ary_entry(x, 1);
            if (key1 == Qnil) return -1;      /* head */
            return rb_str_cmp(key1, key);
          }
        }
        builder.add_to_init %{
          i_anchor    = rb_intern("anchor");
          i_node_level    = rb_intern("node_level");
        }
        builder.c %{
          VALUE find_nearest_node_C(VALUE key) 
          {
            VALUE x = rb_funcall(self, i_anchor, 0);
            long level = FIX2LONG(rb_funcall(self, i_node_level, 1, x));
            VALUE xnext;
            while (level-- > 0)
            {
              xnext = SS_NODE_NEXT(x, level);
              while (ss_node_compare(xnext, key) <= 0)
              {
                x = xnext;
                xnext = SS_NODE_NEXT(x, level);
              }
            }
            return x;
          }
        }
        builder.c %{
          static VALUE find_with_update_C(VALUE x, VALUE rlevel, VALUE key, VALUE update)
          {
            long level = FIX2LONG(rlevel);
            VALUE xnext;
            while (level-- > 0)
            {
              xnext = SS_NODE_NEXT(x, level);
              while (ss_node_compare(xnext, key) < 0)
              {
                x = xnext;
                xnext = SS_NODE_NEXT(x, level);
              }
              rb_ary_store(update, level, x);
            }
            return xnext;
          }
        }
      end
    end

    # Finds a value with a nearest key to given key (from the left).
    # For a set of keys [b, d, f], query "a" will return nil and query "c"
    # will return a value under "b" key.
    #
    def find_nearest(key)
      node_value(find_nearest_node(key))
    end
        
    # Returns value, associated with key. nil if key is not found.
    #
    def find(key)
      x = find_nearest_node(key)
      return node_value(x) if node_compare(x, key) == 0
      nil # nothing found
    end

    def each_node #:nodoc:
      x = node_next(anchor, 0)
      tail = @tail
      while x != tail
        yield(x)
        x = node_next(x, 0)
      end
      self
    end
    
    # Iterates over skiplist kay-value pairs
    #
    def each
      each_node do |node|
        yield(node_key(node), node_value(node))
      end 
    end

    # Constructs a skiplist from a hash values.
    #
    def self.from_hash(hash, options = {})
      from_a(hash.to_a, options)
    end
    
    # Constructs a skiplist from an array of key-value tuples (arrays).
    #
    def self.from_a(ary, options = {})
      sl = new(nil, options)
      ary.each do |kv|
        sl.insert(kv[0], kv[1])
      end
      sl
    end
    
    # Converts skiplist to an array of key-value pairs.
    #    
    def to_a
      inject([]) do |arr, pair|
        arr << pair
        arr
      end
    end
    
  private

    def serialize_list(head)
      head           = anchor.dup
      head[0]        = [ nil  ] * node_level(head)
      raw_list       = [ head ]
      prev_by_levels = [ head ] * node_level(head)
      x = node_next(head, 0)
      i = 1
      while x
        l = node_level(x)
        nx = node_next(x, 0)
        x  = x.dup                  # make modification-safe copy of node
        forwards = x[0]
        while l > 0                 # for each node level update forwards
          l -= 1
          prev_by_levels[l][l] = i  # set raw_list's index as a forward ref
          forwards[l] = nil         # nullify forward pointer (point to tail)
          prev_by_levels[l] = x     # set in a previous stack
        end
        raw_list << x               # store serialized node in an array
        x = nx                      # step to next node
        i += 1                      # increment index in a raw_list array
      end
      raw_list
    end
    
    # Returns head & tail of an imported skiplist. 
    # Caution: raw_list is modified (thus the bang). 
    # Pass dup-ed value if you need.
    #
    # TODO: add double-linking!
    #
    def unserialize_list!(raw_list)
      x = raw_list[0]
      while x != nil
        forwards = x[0]
        forwards.each_with_index do |rawindex, i|
          forwards[i] = rawindex ? raw_list[rawindex] : nil
        end
        # go next node
        x = forwards[0]
      end
      # return anchors (head, tail)
      [raw_list[0], new_anchor]  # <- FIXME: normal tail anchor needed
    end
      
    # C-style API for node operations    
    def anchor(reverse = false)
      reverse ? @tail : @head
    end
    
    def node_level(x)
      x[0].size
    end
    
    def node_next(x, level, dir = 0)
      x[dir][level]
    end
      
    def node_compare(x, key)
      return  1 if x == @tail # tail
      return -1 if x == @head # head
      x[1] <=> key
    end
    
    def node_pair(x)
      x[1,2]
    end
    
    def node_key(x)
      x[1]
    end
    
    def node_value(x)
      x[2]
    end
    
    def node_set_value!(x, value)
      x[2] = value
    end
    
    # before: 
    #   prev -> next
    #   prev <- next
    #
    # after:
    #
    #  prev -> new -> next
    #  prev <- new <- next
    #
    def node_insert_after!(x, prev, level)
      netx = node_next(prev, level)  # 'next' is a reserved word in ruby
      
      # forward links
      x[0][level] = netx
      prev[0][level] = x
      
      # backward links
      x[3][level] = prev
      netx[3][level] = x
    end
    
    def new_node(level, key, value)
      [ 
        [nil]*level, 
        key, 
        value, 
        [nil]*level 
      ]
    end
    
    # TODO: drop this after serialization routines updated
    def new_anchor
      new_node(@maxlevel, nil, nil)
    end
    
    def new_anchors(level)
      h = new_node(level, nil, nil)
      t = new_node(level, nil, nil)
      level.times do |i|
        h[0][i] = t
        t[3][i] = h
      end
      [h, t]
    end
    
    def dir_for_reverse(reverse)
      reverse ? 3 : 0
    end
    
  	def random_level
  	  p = @probability
  	  m = @maxlevel
  		l = 1
  		l += 1 while rand < p && l < m
  		return l
  	end
    
  end
end
