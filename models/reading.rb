  require_relative 'value'

  class Reading < Value
    include DataMapper::Resource

    property :sensor, String
    property :timestamp, DateTime    
    property :id, Serial   
    property :value, Float
    
    alias_method :entry, :value #Added so both modles can use same layout    
  end
