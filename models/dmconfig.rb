require 'dm-core'
require 'dm-migrations'
require 'dm-aggregates'
require_relative 'value'
require_relative 'reading'
require_relative 'alert'
require_relative 'style' 
 
DataMapper.setup( :default, "sqlite3://#{Dir.pwd}/logs.db" )
DataMapper.finalize
DataMapper.auto_upgrade!

#Make sure we always have a default style
Style.first_or_create({:sensor => 'default'}, {:background => :white, :line => :black, :text => :black})
