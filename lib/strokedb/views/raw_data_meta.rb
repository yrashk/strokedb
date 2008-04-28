module StrokeDB
  
  RawData = Meta.new(:nsurl => STROKEDB_NSURL)

  def RawData(data)
    RawData.new(:data => data)
  end
  
end
