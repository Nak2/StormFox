assert(StormFox,"Missing everything")
assert(StormFox.SetWeather,"Missing weather controller")


--[[
Data
	Thunder: boolean
	Temperature: number
	Wind: number
	WindAngle: number 0-360

Functions:
	StormFox.SetWeather(weather_str,0-1)
		Clear
		Rain
		Cloudy
		Fog

Statments:
	Snow looks bad in a storm
		if snow then wind = min(wind,3) end
	Rain should max be a ½ day
	Rain should be from 0.2 and up
	Thunder is with rain thats 0.8 and up
	Fog should be in the morning


]]
local weatherdata = {}
--[[
	funccondition(weatherpercent,currentweather)
]]
function StormFox.AddWeatherCondition(name,clockrange,percentrange,lengthrange,canPick)
	table.insert(weatherdata,{name = name,clockrange = clockrange,percentrange = percentrange,lengthrange = lengthrange,canPick = canPick})
end

StormFox.AddWeatherCondition("Clear") -- Always
StormFox.AddWeatherCondition("Rain",nil,{0.2,1},{240,720})

--StormFox.AddWeatherCondition("Cloudy",nil,{0.2,1},{240,960})

StormFox.AddWeatherCondition("Fog",{335,400},{0.1,0.8},{180,200},function() return math.random(1,3) >= 2 end)

local function PickRandomWeather(current)
	current = current or StormFox.Weather.id or "clear"
	if math.random(0,3) >= 3 then
		return "clear"
	else
		local pickable = {}
		local weathers = StormFox.GetWeathers()
		for i,id in ipairs(weathers) do
			local canGenerate = StormFox.GetMapSetting("weather_" .. id,StormFox.GetWeatherType(id).CanGenerate)
			if id ~= "clear" and canGenerate and id ~= current then
				local tfunc = StormFox.GetWeatherType(id).GenerateCondition
				if not tfunc or tfunc() then -- If not aviable, then add it
					table.insert(pickable,id)
				end
			end
		end
		local selected_weather = "clear"
		if #pickable > 0 then
			selected_weather = table.Random(pickable)
		end
		return selected_weather
	end
end

local clamp,max,abs = math.Clamp,math.max,math.abs
local function GetDataAcceleration(current,lastacc,min,max,lerp_acc)
	local dis = max - min
	local addacc = {-lerp_acc,lerp_acc}
	if current >= max - dis / 5 then addacc = {-lerp_acc,lerp_acc * 0.2} end
	if current <= min + dis / 5 then addacc = {-lerp_acc * 0.2,lerp_acc} end
	return clamp(lastacc + math.random(addacc[1],addacc[2]),-lerp_acc,lerp_acc)
end

local week = {}
function StormFox.GenerateNewDay(dont_update)
	-- Delete last weather
	if #week >= 7 then
		week["ot"] = week[1].temp
		table.remove(week,1)
	end
	local lastWeather = week[#week] or {}
	-- Calc temperature change
		local tempmin,tempmax = StormFox.GetMapSetting("mintemp",-10),StormFox.GetMapSetting("maxtemp",20)
		local last_tempacc = lastWeather.tempacc or math.random(-7,7)
		local last_temp = lastWeather.temp or StormFox.GetNetworkData("Temperature",math.random(tempmin,tempmax))

		local tempacc = GetDataAcceleration(last_temp,last_tempacc,tempmin,tempmax,math.random(2,7))
		local temp = clamp(last_temp + tempacc,tempmin,tempmax)

	-- Wind windmax = math.max(temp,3)
		local last_wind = temp >= 7 and (lastWeather.wind or StormFox.GetNetworkData("Wind",0)) or math.min(lastWeather.wind or StormFox.GetData("Wind",0),1.5)
		local last_windacc = lastWeather.windacc or 0
		local windacc = GetDataAcceleration(last_wind,last_windacc,0,math.max(temp,3),5)
		if last_wind >= 18 then
			last_windacc = last_windacc - 1
		end
		local wind = clamp(last_wind + windacc,0,StormFox.GetMapSetting("maxwind",30))

		local windangle = ((lastWeather.windangle or StormFox.GetNetworkData("WindAngle",math.random(0,360))) + math.random(-50,50)) % 360
		windangle = windangle < 0 and windangle + 360 or windangle
	-- Pick a random weather

	local id = PickRandomWeather(lastWeather.name)
	local length = math.random(1440 / 6,StormFox.GetWeatherType(id).MaxLength or 1440 / 3)

	local d_timestart = StormFox.GetWeatherType(id).TimeDependentGenerate or {0,1339}
	local timestart = math.random(d_timestart[1],d_timestart[2])

	local percent = math.Rand(StormFox.GetWeatherType(id).StormMagnitudeMin or 0, StormFox.GetWeatherType(id).StormMagnitudeMax or 1)
	local thunder = StormFox.GetWeatherType(id):GetData("EnableThunder") and math.random(10) > 6 and wind >=14 or false
	table.insert(week,{name = id,
					trigger = timestart,
					stoptime = math.max(timestart + length),
					percent = percent,
					temp = temp,
					tempacc = tempacc,
					wind = wind,
					windacc = windacc,
					windangle = windangle,
					thunder = thunder
					})
	if dont_update then return end
	StormFox.SetNetworkData("WeekWeather",week)
end
hook.Add("StormFox - PostInit","StormFox - GenerateFirstWeather",function()
	for i = 1,6 do
		StormFox.GenerateNewDay( true )
	end
	StormFox.GenerateNewDay( false )
end)

local selected,clearWD = false
local autocon = GetConVar("sf_autoweather")
hook.Add("StormFox - NewDay", "StormFox - SendNextDay", function()
	if autocon and not autocon:GetBool() then return end
	StormFox.GenerateNewDay( )
	if clearWD and clearWD >= 1440 then
		clearWD = clearWD - 1339
	end
	selected = false
end )

local max = math.max
hook.Add("StormFox - Tick", "StormFox - WeatherAIThink",function(n)
	if #week < 1 then return end
	if autocon and autocon:GetBool() then return end
	if clearWD and clearWD <= n then
		StormFox.SetWeather("clear",0)
		clearWD = nil
	end
	if selected then return end -- Days job done
	if week[1].trigger > n then return end
	local currentWD = week[1]
	-- Set the weather data
		local weather_length = currentWD.stoptime - currentWD.trigger
		local weather_smooth = weather_length / math.random(8,16)
	if weather_smooth <= 0 then print("Error .. tiny weather" .. weather_length) return end -- That weather is old
	clearWD = n + weather_length
		StormFox.SetWeather(currentWD.name,max(currentWD.percent,0.1))

	if #week <= 1 then return end -- Ehhh ..
	local timeBetween = (1400 - currentWD.trigger) + week[2].trigger
	StormFox.SetNetworkData("Wind",week[2].wind,timeBetween)
	StormFox.SetNetworkData("WindAngle",week[1].windangle)
	StormFox.SetNetworkData("Thunder",week[1].thunder or false)
	StormFox.SetNetworkData("Temperature",week[2].temp,timeBetween)
	selected = true
end)