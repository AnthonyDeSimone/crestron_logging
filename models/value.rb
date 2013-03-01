#Methods commong to alerts and readings class 

	class Value		
		def self.recent(sensor, limit = 100)
			if(sensor == "*")
				all(:order => :timestamp.desc, :limit => limit)
			else
				all(:sensor=> sensor, :order => :timestamp.desc, :limit => limit)
			end
		end
		
		def self.hourly(sensor, timestamp)
			if(sensor == "*")
				all(:timestamp => timestamp..(timestamp+1/24.0), :order => :timestamp.desc, :limit => 100)
			else
				all(:sensor=> sensor, :timestamp => timestamp..(timestamp+1/24.0), :order => :timestamp.desc, :limit => 100)
			end
		end
		
		def self.daily(sensor, timestamp)
			if(sensor == "*")
				all(:timestamp => timestamp..(timestamp+1), :order => :timestamp.desc, :limit => 100)		
			else
				all(:sensor=> sensor, :timestamp => timestamp..(timestamp+1), :order => :timestamp.desc, :limit => 100)
			end
		end
end