#Crestron Logging
	This is a backend for logging values and generating graphs. It was designed for easy use
	with a Crestron control system. All valid requests for log values either an unordered list
	with values separated from (formatted) timestamps by a semi-colon. Any request without
	associated data will return "No Data". Valid graph requests will serve an image generated
	by the Google Charts API at a resolution of 999x250, which is the maximum. If there is not 
	enough data to produce a graph, an image dsiaplying that information will be served.
	
	The API is below.

##Charts
*	monthly `GET /graph/$sensor/monthly.png`
*	hourly `GET /graph/$sensor/hourly.png`
*	minutely `GET /graph/$sensor/minutely.png`
*	hourly by date `GET /graph/sensor/YYYY-MM-DD.png`


##Averages
*	`GET /average/$sensor`

##Adding Data
*	value: `POST /$sensor/$value`
*	alert: `POST /$sensor/$message`

##Reading Data
*	Last 100 sensor alerts `GET /alerts/$sensor/recent`
*	Last 5 sensor values `GET /values/$sensor/recent/5`
*	Entries for a specific date (YYYY-MM-DD) `GET /values/$sensor/$date` `GET /alerts/$sensor/$date`
*	Entries for a specific hour of a date (24 hour format) `GET /values/$sensor/$date/$hour` 
*	The wildcard character * can be subsitituted in the above requests*

Recent request also take an additional parameter to limit the size of the results 
*	GET /alerts/$sensor/recent/20`


##Setting Graph Colors
*	`PUT /graph/$sensor/$bg_color/$line_color`
*	$sensor can also be 'default', which will be used if no specific sensor entry is found*

A partial list of colors can be found here: http://www.w3schools.com/html/html_colornames.asp