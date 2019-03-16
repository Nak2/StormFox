
local clamp,floor = math.Clamp,math.floor
local min = math.min

-- Local variables
	local function IsColdWorld()
		local mapEnt = StormFox.MAP.Entities()[1]
		if not mapEnt.coldworld then return false end
		return mapEnt.coldworld > 0
	end
	local function lerpAnyValue( amount, currentValue, targetValue )
		if not currentValue then return targetValue end -- NOTE: If you find that the values are going instantly to the target check here first
		if not targetValue then return currentValue end
		amount = math.Clamp( amount, 0, 1 )
		if type( currentValue ) ~= type( targetValue ) then
			ErrorNoHalt("ERROR: lerpAnyValue called with values of two different types. Returning original value")
			debug.Trace()
			return currentValue
		end
		if type( currentValue ) == "number" then -- Standard number Lerp
			return Lerp( amount, currentValue, targetValue )
		elseif type( currentValue ) == "table" and currentValue.a and currentValue.r and currentValue.g and currentValue.b then -- Color lerp
			local r = Lerp( amount, currentValue.r, targetValue.r )
			local g = Lerp( amount, currentValue.g, targetValue.g )
			local b = Lerp( amount, currentValue.b, targetValue.b )
			local a = Lerp( amount, currentValue.a, targetValue.a )
			return Color( r, g, b, a )
		end
		ErrorNoHalt("ERROR: Unsupported lerp value type. Returning original value")
		return currentValue
	end

-- functions
function StormFox.CalculateMapLight( flTime , nMin, nMax )
	if not nMin then nMin = 0 end
	if not nMax then nMax = 100 end
	flTime = flTime or StormFox.GetTime()
	-- Just a function to calc daylight amount based on time. See here https://www.desmos.com/calculator/842tvu0nvq
	local flMapLight = -0.00058 * math.pow( flTime - 750, 2 ) + nMax
	return clamp( flMapLight, nMin, nMax )
end

local currentMapMaterialFunc,currentMapMaterial,currentLvl,currentMapMaterialid = nil,nil,0,""
if SERVER then
	local startTemp = math.random(StormFox.GetMapSetting("mintemp",-10),StormFox.GetMapSetting("maxtemp",20))
	if IsColdWorld() then
		startTemp = math.min(startTemp,-3)
	end
	StormFox.SetNetworkData( "Temperature", startTemp )
	StormFox.SetNetworkData( "Thunder",false)
	StormFox.SetNetworkData( "Wind", 0 )
	StormFox.SetNetworkData( "WindAngle", math.random(360) ) --cl
	if StormFox.GetNetworkData( "Temperature",0) < -4 then
		if StormFox.WeatherTypes[ "rain" ] then
			local str,mType,lvl,snd = StormFox.WeatherTypes[ "rain" ].DataCalculationFunctions.MapMaterial(1,StormFox.GetNetworkData( "Temperature",0))
			currentMapMaterialFunc = StormFox.WeatherTypes[ "rain" ].DataCalculationFunctions.MapMaterial
			StormFox.TexHandler.ApplyMaterial(str,mType,lvl,snd)
		end
	end

	function StormFox.SetWeather( sWeatherId, flMagnitude, tTime )
		if not StormFox.GetWeatherType( sWeatherId ) then print( "[StormFox] Weather not found:", sWeatherId ) print(debug.traceback()) return end
		local old_w = StormFox.GetNetworkData("Weather","clear")
		StormFox.SetNetworkData( "Weather",sWeatherId)
		StormFox.SetNetworkData( "WeatherMagnitude", flMagnitude, tTime)

		if flMagnitude <= 0 then
			hook.Call("StormFox - NewWeather",nil,"clear",old_w)
		else
			hook.Call("StormFox - NewWeather",nil,sWeatherId,old_w)
		end
	end
	StormFox.SetWeather("clear",0)
end

local skyUpdate = 0
hook.Add("StormFox - NetDataChange","StormFox - WeatherLogic",function(var,weather)
	if var ~= "Weather" and var ~= "WeatherMagnitude" then return end
	local sWeatherID = StormFox.GetNetworkData( "Weather", "clear" )
	local flMagnitude = StormFox.GetNetworkData( "WeatherMagnitude") or 0
	if not StormFox.GetWeatherType( sWeatherID ) then print( "[StormFox] Weather not found:", sWeatherId ) return end
	StormFox.Weather = StormFox.GetWeatherType( sWeatherID )
	skyUpdate = 0 -- update now
end)

-- timeChange
	local function timeToEnumeratedValue( flTime )
		if flTime <= StormFox.Weather.TIME_SUNRISE - 60 then
			return "TIME_NIGHT"
		elseif flTime < StormFox.Weather.TIME_SUNRISE then
			return "TIME_SUNRISE"
		elseif flTime < StormFox.Weather.TIME_SUNSET then
			return "TIME_NOON"
		elseif flTime < StormFox.Weather.TIME_SUNSET + 60 then
			return "TIME_SUNSET"
		else
			return "TIME_NIGHT"
		end
	end

-- update varables
local instantSet = false
	hook.Add("StormFox.Time.Set","StormFox - instasetfix",function()
		instantSet = true
		skyUpdate = 0
	end)
local UPDATE_INTERVAL = 5
local oldTime,oldAmount,oldWeather
local cacheAmount,cacheflMagnitude = {},-1

-- ground material controller
	if SERVER then
		timer.Create("StormFox - MapMaterialController",4,0,function()
			if not StormFox.GetMapSetting("material_replacment") then
				if currentMapMaterialFunc then -- Remove old material
					StormFox.TexHandler.ApplyMaterial()
					currentMapMaterial = nil
				end
				return
			end
			if not currentMapMaterialFunc then return end -- No ground function
			-- Load/generate data
				local sWeatherID = StormFox.GetNetworkData( "Weather", "clear" )
				local mat,mType,lvl,snd = currentMapMaterialFunc(StormFox.GetNetworkData( "WeatherMagnitude" , 0),StormFox.GetNetworkData("Temperature",20),sWeatherID)
					lvl = clamp(floor(lvl or 0),0,3)
			-- Remove old weather-functions if nil material
				if not mat then -- Remove material and function
					currentLvl = 0
					if currentMapMaterial then -- Remove old material
						StormFox.TexHandler.ApplyMaterial()
						currentMapMaterial = nil
					end
					if sWeatherID ~= currentMapMaterialid then  -- Remove function if its set by old weather
						currentMapMaterialFunc = nil
						currentMapMaterialid = nil
					end
					return
				end

			-- Lvl 0 is no material change
				if lvl <= 0 then return end
			local checkMat = mat
			if type(mat) == "table" then checkMat = mat[1] end

			-- Only material if new or if material-lvl is grown
				if (currentMapMaterial or "") == checkMat and (lvl or 0) <= currentLvl then return end
				currentLvl = lvl
				currentMapMaterial = checkMat
			-- Update
				StormFox.TexHandler.ApplyMaterial(mat,mType,lvl,snd)
		end)
	end

local function weatherThink()
	if skyUpdate > CurTime() then return end
	local flTimeSpeed = StormFox.GetTimeSpeed()
	if flTimeSpeed <= 0.2 then
		flTimeSpeed = 5
	end
	skyUpdate = CurTime() + UPDATE_INTERVAL / flTimeSpeed

	-- Load data
		local sWeatherID = StormFox.GetNetworkData( "Weather", "clear" )
		local flMagnitude = StormFox.GetNetworkData( "WeatherMagnitude" , 0)
		if flMagnitude <= 0 then
			StormFox.SetNetworkData( "Weather", "clear" )
			sWeatherID = "clear"
		end
		if sWeatherID == "clear" then
			flMagnitude = 1
		end
		local flTime = StormFox.GetTime() -- The UPDATE_INTERVAL seconds in the furture (Unless you speed up flTime)
			flTime = flTime + UPDATE_INTERVAL / flTimeSpeed
		local currentTimeType = timeToEnumeratedValue(flTime)
		local dataUpdate = min(5,UPDATE_INTERVAL / flTimeSpeed) * 10
		local newWeather = oldWeather ~= StormFox.Weather.id
		local newTime = oldTime ~= currentTimeType
		local newMagnitude = oldAmount ~= flMagnitude
		if newMagnitude then
			dataUpdate = dataUpdate / 4
		end
		if instantSet then
			newWeather = true
			instantSet = false
			dataUpdate = nil
		end
	-- Calc weather and day data
		if not newWeather and not newTime and not newMagnitude then return end
		oldTime = currentTimeType
		oldAmount = flMagnitude
		oldWeather = StormFox.Weather.id
		-- Update Static data
			if newWeather then
				dataUpdate = 5
				for key,_ in pairs(StormFox.Weather.StaticData) do
					StormFox.SetData(key,(StormFox.Weather:GetData(key)), dataUpdate)
				end
			end
		-- Update timevars
			for key,_ in pairs(StormFox.Weather.TimeDependentData) do
				if flMagnitude >= 1 then
					StormFox.SetData(key,(StormFox.Weather:GetData(key,flTime)), dataUpdate)
				elseif flMagnitude > 0 then
					local base = StormFox.GetWeatherType("clear"):GetData(key,flTime)
					local aim = StormFox.Weather:GetData(key,flTime)
					if not aim then
						StormFox.SetData(key,base, dataUpdate)
					else
						local var = lerpAnyValue(flMagnitude,base,aim)
						StormFox.SetData(key,var, dataUpdate)
					end
				end
			end
		-- Update weather/magnitude
			if newMagnitude or newWeather then
				for key,_ in pairs(StormFox.Weather.CalculatedData) do
					if flMagnitude >= 1 then
						StormFox.SetData(key,(StormFox.Weather:GetData(key,flTime)), dataUpdate)
					elseif flMagnitude >= 0 then
						local base = StormFox.GetWeatherType("clear"):GetData(key,flTime)
						local aim = StormFox.Weather:GetData(key,flTime)
						if not aim then
							StormFox.SetData(key,base, dataUpdate)
						else
							local var = lerpAnyValue(flMagnitude,base,aim)
							StormFox.SetData(key,var, dataUpdate)
						end
					end
				end
				for key,func in pairs(StormFox.Weather.DataCalculationFunctions) do
					if type(func) ~= "function" then
						ErrorNoHalt("[StormFox]: DataCalculationFunctions with an unknown value.")
					elseif key == "MapMaterial" then
						currentMapMaterialFunc = func
						currentMapMaterialid = sWeatherID
					else
						StormFox.SetData(key,func(flMagnitude,currentTimeType), dataUpdate)
					end
				end
			end
end
hook.Add( "Think", "StormFox - WeatherThink", weatherThink )

timer.Create("StormFox - MapLight",5,0,function()
	-- Generate maplight
	local mapLight = StormFox.CalculateMapLight(StormFox.GetTime(),StormFox.GetData("MapNightLight",0),StormFox.GetData("MapDayLight",100))
		-- mapLight is from 0 to 100
		-- Add the map-settings
	local minlight,maxlight = StormFox.GetMapSetting("minlight",4),StormFox.GetMapSetting("maxlight",80)
	local delta = (maxlight - minlight ) / 100

	local light = minlight + mapLight * delta
	--print("Calculated light: " .. mapLight)
	--print("Min",minlight,"Max",maxlight)
	--print("Delta",delta)
	--print("Light calc",light)
	StormFox.SetData("DayLightAmount",mapLight)
	StormFox.SetData("MapLight",light)
	if SERVER then
		-- StormFox.CalculateMapLight(flTime, 0, 1)
		StormFox.SetMapLight(light)
	end
end)


if SERVER then
	timer.Create("StormFox - BloomControl",5,0,function()
		StormFox.SetMapBloom(StormFox.GetData("MapBloom") or 0.2)
		StormFox.SetMapBloomAutoExposureMin(StormFox.GetData("MapBloomMin") or 0.7)
		StormFox.SetMapBloomAutoExposureMax(StormFox.GetData("MapBloomMax") or 1)
	end)
end

local function ET(pos,pos2,mask,filter)
	if not pos or not pos2 then return {} end
	local t = util.TraceLine( {
		start = pos,
		endpos = pos + pos2,
		mask = mask,
		filter = filter
		} )
	if not t then return {} end -- Sometimes it returns nil??
	if not t.HitPos then
		t.HitPos = pos + pos2
	end
	return t
end

local max = math.max
if SERVER then
	timer.Create("StormFox - WeatherEvent",1,0,function()
		if type(StormFox.Weather.InRain) ~= "function" then return end
		local Gauge = StormFox.GetData("Gauge",0)
		local wind = StormFox.GetNetworkData("Wind",0)
		local windangle = StormFox.GetNetworkData("WindAngle",0)
		local flMagnitude = StormFox.GetNetworkData( "WeatherMagnitude" , 0)
		local downspeed = -max(1.56 * Gauge + 1.22,10) -- Base on realworld stuff .. and some tweaking (Was too slow)
		downfallNorm = Angle(0,windangle,0):Forward() * wind
			downfallNorm.z = downspeed
		for _,ply in ipairs(player.GetAll()) do
			local tr = ET(ply:GetShootPos(),downfallNorm * -16384,MASK_SHOT,ply)
			if tr.HitSky then
				StormFox.Weather:InRain(ply,flMagnitude)
			end
		end
	end)
else
	timer.Create("StormFox - WeatherEvent",1,0,function()
		if type(StormFox.Weather.InRain) ~= "function" then return end
		if not StormFox.Env.IsInRain() then return end
		StormFox.Weather:InRain(LocalPlayer(),flMagnitude)
	end)
end
