	require_relative 'value'
	
	class Alert < Value
		include DataMapper::Resource
		
		property :sensor, String
		property :timestamp, DateTime
		property :id, Serial
		property :message, String

		alias_method :entry, :message #Added so both modles can use same layout
	end