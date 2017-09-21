assert(StormFox,"Missing everything")
assert(StormFox.SetWeather,"Missing weather controller")

util.AddNetworkString("StormFox-NextDayWeather")

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

local function PickRandomWeather(exclude)
	if math.random(0,3) >= 3 and false then
		return 1
	else
		local i = math.random(#weatherdata)
		local s = weatherdata[i].name
		if exclude and s == exclude then
			return PickRandomWeather(exclude)
		end
		if weatherdata[i].canPick then
			if not weatherdata[i].canPick() then
				return PickRandomWeather(exclude)
			end
		end
		return i
	end
end

local clamp,max,abs = math.Clamp,math.max,math.abs
function GetDataAcceleration(current,lastacc,min,max,lerp_acc)
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
		table.remove(week,1)
	end
	local lastWeather = week[#week] or {}
	-- Calc temperature change
	local last_tempacc = lastWeather.tempacc or math.random(-7,7)
	local last_temp = lastWeather.temp or StormFox.GetData("Temperature",20)

	local tempacc = GetDataAcceleration(last_temp,last_tempacc,math.random(-10,5),20,math.random(2,7))
	local con = GetConVar("sf_disable_autoweather_cold")
	local temp = clamp(last_temp + tempacc,-10,20)
	if con:GetBool() then
		if temp < 5 then
			tempacc = abs(tempacc)
		end
		temp = max(temp,5)
	end

	-- Wind windmax = math.max(temp,3)

	local last_wind = temp >= 7 and (lastWeather.wind or StormFox.GetData("Wind",0)) or math.min(lastWeather.wind or StormFox.GetData("Wind",0),1.5)
	local last_windacc = lastWeather.windacc or 0
	local windacc = GetDataAcceleration(last_wind,last_windacc,0,math.max(temp,3),5)
	local wind = clamp(last_wind + windacc,0,20)

	local windangle = ((lastWeather.windangle or StormFox.GetData("WindAngle",math.random(0,360))) + math.random(-50,50)) % 360
	windangle = windangle < 0 and windangle + 360 or windangle
	-- Pick a random weather
	local next_weather_id = PickRandomWeather(lastWeather.name or "Clear")
	local data = weatherdata[next_weather_id]

	local d_length = data.lengthrange or {0,1440 * 0.8}
	local length = math.random(d_length[1],d_length[2])

	local d_timestart = data.clockrange or {0,1440}
	local timestart = math.random(d_timestart[1],d_timestart[2])

	local d_percent = data.percentrange or {0.1,1}
	local percent = math.Rand(d_percent[1], d_percent[2])
	local thunder = false
	if percent >= 0.8 and wind >= 10 and data.name == "Rain" then
		thunder = true
	end
	table.insert(week,{name = data.name,
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

end

for i = 1,7 do
	StormFox.GenerateNewDay( )
end


local autoWeatherConvar = GetConVar("sf_disable_autoweather")
local bAutoWeatherOn = autoWeatherConvar and autoWeatherConvar:GetBool() or true

cvars.AddChangeCallback( "sf_disable_autoweather", function( sConvar, sOldValue, sNewValue )
	MsgN("[StormFox] Auto Weather " .. ( sNewValue == "1" and "enabled" or "disabled" ) )
	StormFox.SetWeather("Clear")
	bAutoWeatherOn = false
end, "StormFox-AutoWeatherChanged")

hook.Add("StormFox-NewDay", "StormFox-SendNextDay", function()
	if not bAutoWeatherOn then return end

	StormFox.GenerateNewDay( )
	net.Start("StormFox-NextDayWeather")
		net.WriteTable( week[1] )
	net.Broadcast()
end )
