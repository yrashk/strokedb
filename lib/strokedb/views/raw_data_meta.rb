module StrokeDB
  
  RawData = Meta.new

  def RawData(data)
    RawData.new(:data => data)
  end
  
end
