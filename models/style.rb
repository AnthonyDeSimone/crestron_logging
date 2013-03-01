	class Style
		include DataMapper::Resource
	 
		property :id, Serial
		property :sensor, String
		property :background, String
		property :line, String
		property :text, String
	end