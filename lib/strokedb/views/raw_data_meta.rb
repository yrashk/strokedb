module StrokeDB
  
  def RawData(data)
    RawData.new(:data => data)
  end
  
  RawData = Meta.new(:nsurl => STROKEDB_NSURL) do
  end
end
