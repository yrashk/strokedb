module StrokeDB
  # Skiplist by its nature must be loaded into memory and dumped on a disk 
  # as a whole thing. Since it is a pretty slow operation, we use a WAL
  # (write ahead log) to keep skiplist in memory most of the time and put
  # all updates in the log. 
  # * When skiplist is dumped to the disk, new log is created. 
  # * When volume is opened, it loads a skiplist into the memory
  #   and applies the log to it.
  # * When log becomes too large, or #dump! is called explicitely 
  #   skiplist is safely dumped to the disk.
  #
  # DUMPING SAFETY 
  # 
  # 0) write something to the in-memory skiplist and a log
  #   (don't response while log is not updated)
  # 1) dump the skiplist to a temporary file
  # 2) atomically rename the tmpfile to the destination file
  # 3) atomically rename current log to some archive name
  # 4) remove archive log
  # 0) write something to the in-memory skiplist and a log
  #
  # Crash may happen after steps 0, 1, 2, 3, 4.
  # Let's analyze all the possible situations:
  # 0) Data is lost from the memory, but is stored in a log.
  #    On restart we just load an already dumped skiplist 
  #    and replay the log.
  # 1) Same as above, but we have a temporary dump file 
  #    (possibly, partially written) on a disk.
  #    On restart we just remove this file.
  # 2) Skiplist is successfully dumped, but the log contains
  #    operations to be applied on restart.
  #    It is not a problem, since log's data is just the same,
  #    as already stored, so we just replay it.
  # 3) Skiplist is dumped, log is renamed, but is stored on a disk.
  #    On restart we load the skiplist, remove stale logfile and open a new one.
  # 4) No stale files on the disk, log is empty, so the crash case is 
  #    just a regular "close" case. 
  # 
  # According to this, all we have to do is:
  # 1) Do the durable updates to the log before in-memory operations.
  # 2) Remove all the stale files on restart.
  # 3) Load the skiplist from the regular file.
  # 3) Replay the actual log on restart.
  # 
  class SkiplistVolume
    def initialize(params)
      @params = params.stringify_keys
      
    end
    
    # Skiplist interface
    def search(*args)
      @list.search(*args)
    end
    
    def find(key)
      @list.find(key)
    end
    
    def insert(key, value, __level = nil)
      @list.insert(key, value, __level)
    end
    
    def close!
      
    end
    
    def dump!
      
    end
        
  end
end
