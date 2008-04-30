require File.dirname(__FILE__) + '/spec_helper'

describe "Playlist.has_many :songs association" do

  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const,'Playlist') if defined?(Playlist)
    Object.send!(:remove_const,'Song') if defined?(Song)
    Playlist = Meta.new do
      has_many :songs
    end
    Song = Meta.new
  end

  it "should convert :songs to Song and Playlist to playlist to compute foreign reference slot name" do
    playlist = Playlist.create!
    song = Song.create!(:playlist => playlist)
    playlist.songs.should == [song]
  end

  it "should convert :songs to Song and Playlist to playlist to compute foreign reference slot name for multple songs" do
    playlist = Playlist.create!
    song = Song.create!(:playlist => playlist)
    song1 = Song.create!(:playlist => playlist)
    playlist.songs.to_set.should == [song,song1].to_set
  end

  it "should not fail if Song document has no :playlist slot" do
    playlist = Playlist.create!
    song = Song.create!
    playlist.songs.should be_empty
  end

  it "should have association owner defined" do
    playlist = Playlist.create!
    song = Song.create!
    playlist.songs.association_owner.should == playlist
  end

  it "should work well with multiple metas" do
    Object.send!(:remove_const,'RockPlaylist') if defined?(RockPlaylist)
    RockPlaylist = Meta.new do
      has_many :rock_songs, :through => :songs, :conditions => { :genre => 'Rock' }, :foreign_reference => :playlist
    end
    playlist = Playlist.new
    playlist.metas << RockPlaylist
    playlist.save!
    rock_song = Song.new(:genre => 'Rock')
    playlist.songs << rock_song
    playlist.songs.should == [rock_song]
    playlist.rock_songs.should == [rock_song]
  end

  it "should fetch head versions of associated documents if association owner is a head" do
    playlist = Playlist.create!
    playlist.should be_head
    song = Song.create!(:playlist => playlist)
    song.name = "My song"
    song.save!
    playlist.songs.should == [song]
    playlist.songs.each do |s| 
      s.should be_head 
      s.should_not be_a_kind_of(VersionedDocument) 
      s.should have_slot(:name) 
    end
  end

  it "should fetch specific versions of associated documents if association owner is a not a head" do
    pending do
      playlist = Playlist.create!
      song = Song.create!(:playlist => playlist)
      playlist.name = "My playlist"
      playlist.save!
      playlist = playlist.versions.previous
      playlist.should_not be_head
      song.name = "My song"
      song.save!
      song = song.versions.previous
      playlist.songs.should == [song]
      playlist.songs.each do |s| 
        s.should_not be_head
        s.should be_a_kind_of(VersionedDocument) 
        s.should_not have_slot(:name) 
      end
    end
  end

  it "should fetch head versions of associated documents if association owner wasn't saved when associated doc were created and now it is a head" do
    playlist = Playlist.new
    song = Song.create!(:playlist => playlist)
    song.name = "My song"
    song.save!
    playlist.save!
    playlist.should be_head
    playlist.songs.should == [song]
    playlist.songs.each do |s| 
      s.should be_head 
      s.should_not be_a_kind_of(VersionedDocument) 
      s.should have_slot(:name) 
    end
  end

  it "should fetch head versions of associated documents if association owner wasn't saved when associated doc were created and now it is not a head" do
    pending do
      playlist = Playlist.new
      song = Song.create!(:playlist => playlist)
      song.name = "My song"
      song.save!
      playlist.save!
      playlist.name = "My playlist"
      playlist.save!
      playlist = playlist.versions.previous
      playlist.songs.should == [song]
      playlist.songs.each do |s| 
        s.should be_head 
        s.should_not be_a_kind_of(VersionedDocument) 
        s.should have_slot(:name) 
      end
    end
  end

  it "should be able to filter associated documents" do
    playlist = Playlist.create!
    rock_song = Song.create!(:playlist => playlist, :genre => 'Rock')
    pop_song = Song.create!(:playlist => playlist, :genre => 'Pop')
    pending("result filtering is not ready") do
      playlist.songs.find(:genre => 'Rock').should == [rock_song]
      playlist.songs.find(:genre => 'Pop').should == [pop_song]
    end
  end

  it "should be able to instantiate new document with #new" do
    playlist = Playlist.create!
    song = playlist.songs.new(:name => 'My song')
    song.name.should == 'My song'
    song.playlist.should == playlist
    song.should be_a_kind_of(Document)
    song.should be_new
    song.save!
    playlist.songs.should == [song]
  end

  it "should be able to instantiate new document with #build" do
    # should be the same at the above
    playlist = Playlist.create!
    song = playlist.songs.build(:name => 'My song')
    song.name.should == 'My song'
    song.playlist.should == playlist
    song.should be_a_kind_of(Document)
    song.should be_new
    song.save!
    playlist.songs.should == [song]
  end

  it "should be able to create new document" do
    playlist = Playlist.create!
    song = playlist.songs.create!(:name => 'My song')
    song.name.should == 'My song'
    song.playlist.should == playlist
    song.should be_a_kind_of(Document)
    song.should_not be_new
    playlist.songs.should == [song]
  end
  
 

end



describe "Playlist.has_many :songs association with sort slot defined" do

  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const,'Playlist') if defined?(Playlist)
    Object.send!(:remove_const,'Song') if defined?(Song)
    Playlist = Meta.new do
      has_many :songs, :sort_by => :created_at
    end
    Song = Meta.new
  end

  it "having songs with created_at should be able sort by it" do
    playlist = Playlist.create!
    song2 = Song.create!(:playlist => playlist, :created_at => Time.now)
    song1 = Song.create!(:playlist => playlist, :created_at => Time.now - 100)
    playlist.songs.should == [song1, song2]
  end
  
end

describe "Playlist.has_many :songs association with sort slot defined and reverse order" do

  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const,'Playlist') if defined?(Playlist)
    Object.send!(:remove_const,'Song') if defined?(Song)
    Playlist = Meta.new do
      has_many :songs, :sort_by => :created_at, :reverse => true
    end
    Song = Meta.new
  end

  it "having songs with created_at should be able sort by it" do
    playlist = Playlist.create!
    song2 = Song.create!(:playlist => playlist, :created_at => Time.now)
    song1 = Song.create!(:playlist => playlist, :created_at => Time.now - 100)
    playlist.songs.should == [song2, song1]
  end
  
end


describe "Namespace::Playlist.has_many :songs association" do

  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const,'Namespace') if defined?(Namespace)
    Namespace = Module.new
    Namespace.nsurl 'namespace'
    Namespace.send!(:remove_const,'Playlist') if defined?(Namespace::Playlist)
    Namespace.send!(:remove_const,'Song') if defined?(Namespace::Song)
    Namespace::Playlist = Meta.new do
      has_many :songs, :nsurl => 'namespace'
    end
    Namespace::Song = Meta.new
  end

  it "should convert :songs to Song and Playlist to playlist to compute foreign reference slot name" do
    playlist = Namespace::Playlist.create!
    song = Namespace::Song.create!(:playlist => playlist)
    playlist.songs.should == [song]
  end


end

describe "Playlist.has_many :rock_songs, :through => :songs, :conditions => { :genre => 'Rock' } association" do

  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const,'Playlist') if defined?(Playlist)
    Object.send!(:remove_const,'Song') if defined?(Song)
    Playlist = Meta.new do
      has_many :rock_songs, :through => :songs, :conditions => { :genre => 'Rock' } 
    end
    Song = Meta.new
  end

  it "should convert :songs to Song and Playlist to playlist to compute foreign reference slot name" do
    playlist = Playlist.create!
    rock_song = Song.create!(:playlist => playlist, :genre => 'Rock')
    pop_song = Song.create!(:playlist => playlist, :genre => 'Pop')
    playlist.rock_songs.should == [rock_song]
  end

end

describe "Playlist.has_many :songs, :foreign_reference => :belongs_to_playlist association" do

  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const,'Playlist') if defined?(Playlist)
    Object.send!(:remove_const,'Song') if defined?(Song)
    Playlist = Meta.new do
      has_many :songs, :foreign_reference => :belongs_to_playlist
    end
    Song = Meta.new
  end

  it "should convert :songs to Song and use foreign_reference to compute foreign reference slot name" do
    playlist = Playlist.create!
    song = Song.create!(:belongs_to_playlist => playlist)
    playlist.songs.should == [song]
  end

end

describe "Playlist.has_many :all_songs, :through => :songs association" do

  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const,'Playlist') if defined?(Playlist)
    Object.send!(:remove_const,'Song') if defined?(Song)

    Playlist = Meta.new do
      has_many :all_songs, :through => :songs
    end
    Song = Meta.new
  end

  it "should use through's :songs to find out Song and convert Playlist to playlist" do
    playlist = Playlist.create!
    song = Song.create!(:playlist => playlist)
    playlist.all_songs.should == [song]
  end

end

describe "Playlist.has_many :authors, :through => [:songs,:authors] association" do

  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const,'Playlist') if defined?(Playlist)
    Object.send!(:remove_const,'Song') if defined?(Song)

    Playlist = Meta.new do
      has_many :authors, :through => [:songs,:author]
    end
    Song = Meta.new
  end

  it "should use through's :songs to find out Song and convert Playlist to playlist" do
    playlist = Playlist.create!
    song = Song.create!(:playlist => playlist, :author => "John Doe")
    playlist.authors.should == [song.author]
  end

  it "should not fail if Song document has no :author slot" do
    playlist = Playlist.create!
    song = Song.create!(:playlist => playlist)
    playlist.authors.should be_empty
  end

end

describe "Playlist.has_many :songs, :extend => MyExt association" do
  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const,'Playlist') if defined?(Playlist)
    Object.send!(:remove_const,'Song') if defined?(Song)
    Object.send!(:remove_const,'MyExt') if defined?(MyExt)
    MyExt = Module.new do
    end
    Playlist = Meta.new do
      has_many :songs, :extend => MyExt
    end
    Song = Meta.new
  end

  it "should extend result with MyExt" do
    playlist = Playlist.create!
    playlist.songs.should be_a_kind_of(MyExt)
  end

end

describe "Playlist.has_many :songs do .. end association" do
  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const,'Playlist') if defined?(Playlist)
    Object.send!(:remove_const,'Song') if defined?(Song)
    Playlist = Meta.new do
      has_many :songs do
        def some_method
        end
      end
    end
    Song = Meta.new
  end

  it "should extend result with given block" do
    playlist = Playlist.create!
    playlist.songs.should be_a_kind_of(Playlist::HasManySongs)
    playlist.songs.should respond_to(:some_method)
  end

end
