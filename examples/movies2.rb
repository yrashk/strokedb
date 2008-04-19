require File.dirname(__FILE__) + '/../lib/strokedb'
$KCODE = 'u'


# cleanup the database
FileUtils.rm_rf '.movies.strokedb'
# setup database
StrokeDB::Config.build :default => true, :base_path => '.movies.strokedb'
include StrokeDB

Movie = Meta.new(:credits => %w[ Автор Актер Режиссер Исполнитель Год ]) do
  has_many :comments
  on_new_document do |doc|
    doc[:credits] ||= []
  end
  
  # :edited_by slot keeps track on who edited this particular version
  before_save do |doc|
    doc[:edited_by] ||= doc[:owner]
  end
  
  # returns ordered credits in a form of:
  # movie.credits == [ ["Artist", "Mylène Farmer"], ["Director", "Laurent Boutonnat"] ]
  def credits
    meta.credits.map do |s| 
      self[s] ? [s, self[s]] : nil
    end.compact
  end
end

Comment = Meta.new

User = Meta.new do
  on_new_document do |u|
    u[:playlists] ||= []
  end
end

Playlist = Meta.new do
  on_new_document do |pl|
    pl[:items] ||= []
  end
end

oleg   = User.create!(:name => "Олег Андреев")
yrashk = User.create!(:name => "Юрій Рашковський")

melancholie = Movie.create!(:owner        => oleg, 
                            :title        => "Je t'aime mélancolie")

desenchantee = Movie.create!(:owner       => oleg, 
                             :title        => "Désenchantée")

sanscontrefacon = Movie.create!(:owner    => yrashk, 
                                :title        => "Sans Contrefaçon")

# Oleg creates a favorites playlist
my_favorites = Playlist.new(:owner => oleg, 
                            :title => "Favorite MF music videos")

my_favorites.items += [ melancholie, desenchantee ]
my_favorites.save!

# Yurii adds credits to movies

common = { :edited_by    => yrashk, "Исполнитель" => "Mylène Farmer" }

melancholie.update_slots!(common.merge("Год" => 1991))
desenchantee.update_slots!(common.merge("Год" => 1991))
sanscontrefacon.update_slots!(common.merge("Год" => 1987))

# Oleg adds a comment to "Sans Contrefaçon"
sanscontrefacon.comments.create!(:text => "Обалдеть!!!111", :owner => oleg)

p sanscontrefacon.comments.map{|c|c.text} 
# => ["Обалдеть!!!111"]

# Find all Movies
p Movie.find.map { |d|
  "#{d.uuid[0,4]}: #{d.title}"
}
# => ["fd59: Je t'aime mélancolie", "66d0: Sans Contrefaçon", "9c4c: Désenchantée"]

# Find all Oleg's documents
p Document.find(:owner => oleg).map { |d|
  "#{d.meta.name}:#{d.uuid[0,4]}"
}
# => ["Movie:fd59", "Movie:9c4c", "Playlist:8acc", "Comment:8306"]

p sanscontrefacon.credits
# => [["Исполнитель", "Mylène Farmer"], ["Год", 1987]]

# Find all 1991 year movies
p Movie.find("Год" => 1991).map { |d| d.title }
# => ["Désenchantée", "Je t'aime mélancolie"]


