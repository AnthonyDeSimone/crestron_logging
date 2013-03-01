	require 'sinatra'
	require 'sinatra/reloader'
	require_relative 'models/dmconfig.rb'
	require_relative 'graph'

	set :port, 80

####################### Monkey Patches #######################

	class DateTime
		def self.epoch
			DateTime.new(1970, 1, 1, 0, 0, 0)
		end	
	end
	
####################### All Graph Calls #######################
#All graph calls require ISO-8601 dates

#Minutely graph
get '/graph/:sensor/:date/:time' do
	sensor, date, time = params[:captures]
	time.gsub!('.png', '') 		#Hack to allow Crestron Dynamic graphics to get this as an image

	style = Style.all(:sensor => sensor).first
	style ||= (Style.all(:sensor => 'default')).first

	if(date =~ /\A\d{4}-\d{2}-\d{2}\Z/)
		graph = Graph.new(sensor, "minutely", style )
		graph.date = DateTime.parse("#{date} #{time}:00")
	end
	
	if(!graph.nil? && graph.create)
		send_file graph.filename
	else
		send_file "public\\images\\no_data.png"
	end
end

#Hourly and Monthly graphs
get '/graph/:sensor/:date' do
	sensor, date = params[:captures]

	date.gsub!('.png', '') 		#Hack to allow Crestron Dynamic graphics to get this as an image
	
	style = Style.all(:sensor => sensor).first
	style ||= (Style.all(:sensor => 'default')).first

	if(date =~ /\A\d{4}-\d{2}-\d{2}\Z/)
		graph = Graph.new(sensor, "hourly", style )
		graph.date = DateTime.parse(date) + 1
	elsif(date =~ /\A\d{4}\Z/)
		graph = Graph.new(sensor, "monthly", style )
		graph.date = DateTime.parse(date+"-12-01") + 1
	else
		graph = Graph.new(sensor, date, style )	
	end
		
	if(graph.create)
		send_file graph.filename
	else
		send_file "public\\images\\no_data.png"
	end
end

####################### Averages #######################
get '/average/:sensor' do
	date = DateTime.new(Date.today.year, Date.today.month, 1) 
	average = Reading.avg(:value, :sensor=> params[:sensor]).round(2)
	
	erb :basic, :locals => {:record => average}
end

####################### Value Requests #######################
get '/values/:sensor/recent/:limit' do
	sensor, limit = params[:captures]
	records = Reading.recent(sensor, limit.to_i)	
	
	erb :basic, :locals => {:records => records}
end

get '/values/:sensor/recent' do
	sensor = @params[:sensor]
	records = Reading.recent(sensor)
	
	erb :basic, :locals => {:records => records}
end

#Return results for a specific date, hour
#Expecting ISO 8601 dates & 24 hour format
get '/values/:sensor/:date/:hour' do
	sensor, date, hour = @params[:captures]
	
	begin
		timestamp = DateTime.parse(date + " " + hour + ":00") 
		records = Reading.hourly(sensor, timestamp)

	rescue Exception
		record = "No Data"
	end
	
	erb :basic, :locals => {:record => record, :records => records}
end

#Return results for a specific date
#Expecting ISO 8601 dates
get '/values/:sensor/:date' do
	sensor, date = @params[:captures]

	#Rescue from malformed dates
	begin
		timestamp = DateTime.parse(date) 
		records = Reading.daily(sensor, timestamp)
	rescue Exception
		record = "No Data"
	end
		
	erb :basic, :locals => {:record => record, :records => records}
end

####################### Alert Requests #######################
get '/alerts/recent' do
	records = Alert.all(:order => :timestamp.desc, :limit => 100)
	
	erb :basic, :locals => {:records => records}
end

get '/alerts/recent/:limit' do
	records = Alert.all(:order => :timestamp.desc, :limit => params[:limit].to_i)
	
	erb :basic, :locals => {:records => records}
end

get '/alerts/:sensor/recent' do
	records = Alert.recent(@params[:sensor])
	
	erb :basic, :locals => {:records => records}
end

get '/alerts/*/recent/*' do
	sensor, limit = @params[:splat]
	
	records = Alert.recent(sensor, limit.to_i)
	erb :basic, :locals => {:records => records}
end

get '/alerts/:sensor/:date' do
	sensor, date = @params[:captures]

	#Rescue from malformed dates
	begin
		timestamp = DateTime.parse(date) 
		puts timestamp
		records = Alert.daily(sensor, timestamp)
	rescue Exception
		record = "No Data"
	end
	
	erb :basic, :locals => {:record => record, :records => records}
end


####################### Adding Values or Alerts to the Database #######################
post '/:sensor/:value' do
	sensor, value = @params[:captures]
	
	if(value =~ /\A\d+(\.\d+)*\Z/)
		Reading.create(:sensor =>sensor, :value=> value.to_f, :timestamp => DateTime.now)
	else
		Alert.create(:sensor =>sensor, :message=> value, :timestamp => DateTime.now)
	end
end

####################### Adding Styles for Graph Outputs #######################
put '/graph/:sensor/:background/:line/:text' do
	sensor, background, line, text = @params[:captures]
	
	#Add style to database if all colors are valid
	if(([background.to_sym, line.to_sym, text.to_sym] - GChart::COLORS.keys).empty?)
		style = Style.first_or_create(:sensor => sensor)
		style.update(:background => background, :line => line, :text => text)
	end
end

####################### Additional Error Handling #######################
not_found do
	erb :'404'
end