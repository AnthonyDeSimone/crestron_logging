	require 'gchart'
	require 'net/http'	
	
	#This class is used for creating the graphs with help from the google charts api
	#It takes the timescale, color information, and log information and creates a local
	#file that is downloaded from google and served
	class Graph
		attr_accessor :date, :filename
		
		def initialize(type, time_scale, style)
			@months = [nil, "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
			@type, @time_scale, @style = type, time_scale, style		
			@label, @data = [], []
			@description = @time_scale.capitalize
		end
		
		def special_round(n)
			((n.to_f/(10**(n.size-1))).ceil * 10**(n.size-1)).to_i
		end
		
		def create
			case @time_scale
				when 'monthly'; monthly_graph
				when 'hourly'; hourly_graph
				when 'minutely'; minutely_graph	
				else return false
			end			
		end
		
		def monthly_graph
			@date ||= DateTime.new(Date.today.year, Date.today.month, 1) 
			@description += " - " + @date.strftime("%Y")
			
			12.times do |n|
				@monthly_levels = Reading.all(:sensor=> @type, :timestamp => @date..(@date >> 1), :limit => 1)
				if !@monthly_levels[0].nil?
					@label << @months[@date.month]
					@data << @monthly_levels[0].value.to_i
				end
				@date = @date << 1		
			end
			
			return false if @data.size < 2			
			make_graph
		end
		
		def hourly_graph
			@date ||= DateTime.new(DateTime.now.year, DateTime.now.month, DateTime.now.day, DateTime.now.hour, 0, 0, 0)
			@description += " - " + (@date-1).strftime("%b %d, %Y")
			@data = []
			
			@hourly_levels = Reading.all(:sensor=> @type, :timestamp => (@date-1)..@date, :order=> :timestamp.asc)
			@hourly_levels.to_a.uniq! {|r| ts = r.timestamp; DateTime.new(ts.year, ts.month, ts.day, ts.hour, 0, 0,0)}

			if(!@hourly_levels.empty?)
				@data = @hourly_levels.map{|r| r.value}
				@label = @hourly_levels.map{|r| "#{([0,12].include? r.timestamp.hour) ? 12 : r.timestamp.hour % 12}:00"}
			end
			return false if @data.size < 2			
			make_graph
		end
			
		def minutely_graph
			now = DateTime.now
			
			@date ||= DateTime.new(now.year, now.month, now.day, now.hour, now.minute, 0, 0)
			@description += " - " + @date.strftime("%l:%M %p")
			@data = []
			
			@minutely_levels = Reading.all(:sensor=> @type, :timestamp => (@date-1/24.0)..@date, :order=> :timestamp.asc)
			@minutely_levels.to_a.uniq! {|r| ts = r.timestamp; DateTime.new(ts.year, ts.month, ts.day, ts.hour, ts.minute, 0,0)}
			
			if(@minutely_levels)
				@data = @minutely_levels.map{|r| r.value}
				@label = @minutely_levels.map{|r| r.timestamp.minute.to_s.rjust(2, '0')}
			end

			if @data.size < 2			
				return false
			else
				make_graph
				@label.first.insert(0, "#{([0,12].include? now.hour) ? 12 : now.hour % 12}:")				
			end
		end

		#Creates the Ghart object
		#Accesses the google url generated
		#Saves the file locally
		def make_graph
			graph = GChart.line do |g|
				g.data   = @data
				g.colors = [@style.line.to_sym]
				g.legend = [@type.gsub('_', ' ').capitalize]

				g.width  = 999
				g.height = 250

				g.entire_background = @style.background.to_sym

				g.axis(:left) { |a| a.range = 0..@data.max.to_i; a.text_color = @style.text.to_sym }
				g.axis(:bottom) do |a|
					a.labels     = @label
					a.text_color = @style.text.to_sym
				end

				g.axis(:bottom) do |a|
					a.labels = [@description]
					a.label_positions = [50]
					a.text_color = @style.text.to_sym
				end
			end
			
			@filename = "public\\images\\" + @type.gsub(' ', '_') + '_' + @time_scale + "_graph.png"
	
			Net::HTTP.start("graph.googleapis.com") do |http|
				resp = http.get(graph.to_url)
				open(filename ,"wb") do |file|
						file.write(resp.body)
				end
			end
		end	
	end