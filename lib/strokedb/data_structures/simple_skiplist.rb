require 'thread'
require File.expand_path(File.dirname(__FILE__) + '/../util/class_optimization')

module StrokeDB
  class SimpleSkiplist
    include Enumerable
    
    DEFAULT_MAXLEVEL     = 32
    DEFAULT_PROBABILITY  = 1/Math::E
    
    attr_accessor :maxlevel, :probability
    
    def initialize(options = {})
      options = options.stringify_keys
      @maxlevel    = options['maxlevel']    || DEFAULT_MAXLEVEL
      @probability = options['probability'] || DEFAULT_PROBABILITY
      @head, @tail = new_anchors(@maxlevel)
      @mutex       = Mutex.new
    end
    
    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} items: #{to_a.inspect}, maxlevel: #{@maxlevel}, probability: #{@probability}>"
    end
    
    def dump
      Marshal.dump({
        :maxlevel    => @maxlevel,
        :probability => @probability,
        :arr         => to_a
      })
    end
    
    def self.load(dumped)
      hash = Marshal.load(dumped)
      arr = hash.delete(:arr)
      from_a(arr, hash)
    end
    
    # Tests whether skiplist is empty.
    #
    def empty?
      node_next(@head, 0) == @tail
    end
    
    # Smart prefix search algorithm.
    # Algorithm is two-step: find the first matching key,
    # then collect all the values.
    # 
    # 1) Define a direction of search using <tt>reverse</tt>.
    # 2) Find the first node in the range <tt>start_key..end_key</tt>.
    # 3) Skip a given number of nodes (<tt>offset</tt>).
    # 4) Collect nodes while <tt>end_key</tt> prefix matches and <tt>limit</tt>
    #    is not exceeded.
    # <tt>reverse</tt> option specifies a direction of search, the meaning of 
    # the <tt>start_key</tt> remains: it is the key to start search with.
    #
    # Note 1: search from "a" to "b" returns nothing if <tt>reverse</tt> is true.
    #         Use "b".."a" to get interesting results in a reversed order.
    # Note 2: search from "ab" to "a" (in any order) means the following:
    #         Find the first "ab" key and move on while "a" is the prefix.
    # 
    def search(start_key, end_key, limit, offset, reverse, with_keys)
      offset ||= 0
      
      start_node = find_by_prefix(start_key, reverse)
      !start_node and return []
      
      start_node = skip_nodes(start_node, offset, reverse)
      !start_node and return []
    
      collect_values(start_node, end_key, limit, reverse, with_keys)
    end
    
    # TODO: add C routines for this to optimize performance
    #
    def find_by_prefix(start_key, reverse)
      dir = dir_for_reverse(reverse)
      x = anchor(reverse)
      # if no prefix given, just return a first node
      !start_key and return node_next(x, 0, dir)
      
      level = node_level(x)
      while level > 0
        level -= 1
        xnext = node_next(x, level, dir)
        if reverse
          # Note: correct key CAN be greater than start_key in this case 
          # (like "bb" > "b", but "b" is a valid prefix for "bb")
          while node_compare2(xnext, start_key) > 0
            x = xnext
            xnext = node_next(x, level, dir)
          end
        else
          while node_compare(xnext, start_key) < 0
            x = xnext
            xnext = node_next(x, level, dir)
          end
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
      tail = anchor(!reverse)
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
        if reverse
          node_key(x)[0, pfx_size] < end_prefix and return values
        else
          node_key(x)[0, pfx_size] > end_prefix and return values
        end
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
    
    # Insert a key-value pair. If the key already exists,
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
  	
  	# Remove a key-value pair. If the key does not exist,
    # no action is performed.
    #
    #  <d> is a node to be removed
    #  <M> is a marked node in a update_list
    #  <N> is next node to <M> which reference must be updated. 
    #
    #  M-----------------> d <---------------- N ...
    #  o ------> M ------> d <------ N ... 
    #  o -> o -> o -> M -> d <- N ....
    #
    def delete(key)
      @mutex.synchronize do
        x = anchor
        level = node_level(x)
        update = Array.new(level)
        x = find_with_update(x, level, key, update)
        
        # remove existing key
  	    if node_compare(x, key) == 0
  	      level = node_level(x)
  	      while level > 0
  	        level -= 1
  	        node_delete_after!(x, update[level], level)
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
    
    declare_optimized_methods(:C, :find_nearest_node, :find_with_update) do
      require 'rubygems'
      require 'inline'
      inline(:C) do |builder|
        builder.prefix %{
          static ID i_anchor, i_node_level, i_at_head, i_at_tail;
          #define SS_NODE_NEXT(x, level) (rb_ary_entry(rb_ary_entry(x, 0), level))
          static int ss_node_compare(VALUE head, VALUE tail, VALUE x, VALUE key)
          {
            if (x == tail) return 1; 
            if (x == head) return -1;
            VALUE key1 = rb_ary_entry(x, 1);
            return rb_str_cmp(key1, key);
          }
        }
        builder.add_to_init %{
          i_anchor     = rb_intern("anchor");
          i_node_level = rb_intern("node_level");
          i_at_head    = rb_intern("@head");
          i_at_tail    = rb_intern("@tail");
          
        }
        builder.c %{
          VALUE find_nearest_node_C(VALUE key) 
          {
            VALUE head = rb_ivar_get(self, i_at_head);
            VALUE tail = rb_ivar_get(self, i_at_tail);
            VALUE x = head;
            long level = FIX2LONG(rb_funcall(self, i_node_level, 1, x));
            VALUE xnext;
            while (level-- > 0)
            {
              xnext = SS_NODE_NEXT(x, level);
              while (ss_node_compare(head, tail, xnext, key) <= 0)
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
            VALUE head = rb_ivar_get(self, i_at_head);
            VALUE tail = rb_ivar_get(self, i_at_tail);
            while (level-- > 0)
            {
              xnext = SS_NODE_NEXT(x, level);
              while (ss_node_compare(head, tail, xnext, key) < 0)
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
      sl = new(options)
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

    def node_compare2(x, key)
      return  1 if x == @tail # tail
      return -1 if x == @head # head
      x[1][0, key.size] <=> key
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
    
    # before: 
    #   prev -> x -> next
    #   prev <- x -> next
    #
    # after:
    #
    #  prev -> next
    #  prev <- next
    #
    def node_delete_after!(x, prev, level)
      netx = node_next(x, level)  # 'next' is a reserved word in ruby
      
      # forward links
      prev[0][level] = netx
      
      # backward links
      netx[3][level] = prev
    end
    
    def new_node(level, key, value)
      [ 
        [nil]*level, 
        key, 
        value, 
        [nil]*level 
      ]
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
