module StrokeDB
  class FixedLengthSkiplistVolume < SimpleSkiplist

    def initialize(options = {})
      @options = options.stringify_keys
      @volume = MapVolume.new(:record_size => (@options['maxlevel']||DEFAULT_MAXLEVEL * 4) + 1 +
      @options['key_length'] + @options['value_length'], :path => @options['path'], :capacity => @options['capacity'])
      @nodes = {}
      super(nil,:maxlevel => @options['maxlevel'], :probability => @options['probability'])
    end

    def key_length
      @options['key_length']
    end

    def value_length
      @options['value_length']
    end

    def capacity
      @options['capacity']
    end

    def path
      @options['path']
    end

    def close!
      @volume.close!
    end

    def inspect
      "#<StrokeDB::FixedLengthSkiplistVolume:0x#{object_id.to_s(16)} path: #{path} key_length: #{key_length} value_length: #{value_length} capacity: #{capacity}"
    end

    private

    # SimpleSkiplist overrides

    def node_next(x, level)
      if node = x[0][level]
        read_node(node[-1])
      else
        nil
      end
    end

    def node_set_value!(x, value)
      x[-2] = value
      save_node!(x)
    end

    def node_insert_after!(x, prev, level)
      x[0][level] = prev[0][level]
      prev[0][level] = save_node!(x)
      save_node!(prev)
    end

    def new_node(level, key, value, __pos = -1)
      [
        [nil]*level,
        key,
        value,
        __pos
      ]
    end

    def new_head
      unless @volume.available?(0)
        read_node(0)
      else
        _head = new_node(@maxlevel, "\x00" * key_length, "\x00" * value_length)
        save_node!(_head)
      end
    end

    def save_node!(node)
      node_levels = node[0]
      node_levels = node_levels.map{|v| v.nil? ? -1 : v[-1]}
      packed = (node[-1,1]+node_levels).pack("CN#{node_levels.size}")
      if (szd = maxlevel - node_levels.size) > 0
        packed += "\xff\xff\xff\xff"*szd
      end
      if node[-1] == -1 # unsaved
        node[-1] = @volume.insert!(packed + node[-3] + node[-2])
      else
        @volume.write!(node[-1],packed + node[-3] + node[-2])
      end
      if node[-1] == 0
        @head = node
      end
      node
    end

    def read_node(position)
      _node = @volume.read(position)
      level = _node[0,1].unpack('C')[0]
      node = [
        LazyMappingArray.new(_node[1,maxlevel*4].unpack("N#{level}")).map_with{|v| v == 4294967295 ? nil : read_node(v)},
        (key = _node[maxlevel*4 + 1,key_length]) == "\x00" * key_length ? nil : key,
        _node[maxlevel*4 + 1 + key_length, value_length],
        position
      ]
    end


  end
end