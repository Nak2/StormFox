local Weather = {}
StormFox.Weather = "Clear"

StormFox.SetData("Weather","Clear")
StormFox.SetData("Temperature",20)
StormFox.SetData("SunMoonAngle",270)
StormFox.SetData("Wind",0)
StormFox.SetData("WindAngle",math.random(360))
StormFox.SetData("ThunderLight",0)
local updateTime = 5

--[[-------------------------------------------------------------------------
	Valid weather data-templats
	[KeyData] = {Day[,Sunset/sunrise],Night}
	[KeyData] = Varable
	[KeyData] = function(weather %)

	Weathers can also be mixed with procents .. however it will use a function over data

---------------------------------------------------------------------------]]

	-- Basic Weatherdata
	local floor,round,clamp,min,max = math.floor,math.Round,math.Clamp,math.min,math.max
	Weather.Clear = {
		-- SkyPaint
					-- Top 					Bottom
		["SkyColor"] = {Color(51, 127.5, 255),Color(204, 255, 255)},
		["NightColor"] = {Color(0, 0, 0),Color(0, 1.5, 5.25)},
					-- Day, [sunrise/sunset,] night
		["FadeBias"] = {0.3,0.16,0.06},
		["DuskColor"] = {Color(255, 255, 255),Color(255, 204, 0),Color(0, 0, 0)},
		["DuskScale"] = {1,0.46,0},
		["DuskIntensity"] = {1,0.7,0},
		["HDRScale"] = {0.66,0.1},
		["StarsEnabled"] = true,
		["StarFade"] = 1,
		["StarSpeed"] = 0.001,
		["DrawStars"] = true,
		["StarTexture"] = "skybox/starfield",

		-- Sun
		["SunSize"] = 20,
		["SunOverlay"] = 20,
		["SunColor"] = Color(255,255,255),
		["MapLight"] = {100,15},
		["SunLight"] = 100,
		["MapBloom"] = {0.2,0.4},
		["MapBloomMax"] = {1,1},

		-- Moon
		["MoonLight"] = 100,
		["MoonColor"] = Color(205,205,205),

		-- Fog
		["Fogdensity"] = {0.8,0.9},
		["Fogend"] = {108000,60000},
		["Fogstart"] = 0,

		-- Rain
		["Gauge"] = 0}

	function StormFox.AddWeather(name,weatherdata)
		Weather[name] = weatherdata
	end

	function StormFox.GetWeathers()
		return table.GetKeys(Weather)
	end

	local BasicClouds = {
		-- SkyPaint
		["SkyColor"] = {Color(3.0, 2.9, 3.5),Color(3.0, 2.9, 3.5)}, -- {Color(30, 29, 35),Color(30, 29, 35)},
		["NightColor"] = {Color(0.4, 0.2, 0.54),Color(0, 0.15, 0.525)}, -- {Color(4, 2, 5.4),Color(0, 1.5, 5.25)},
		["FadeBias"] = {0.3,0.16,0.06},
		["DuskColor"] = {Color(3, 2.9, 3.5),Color(3, 2.5, .54),Color(.4, .2, .54)}, -- {Color(30, 29, 35),Color(30, 25, 5.4),Color(4, 2, 5.4)},
		["DuskScale"] = {1,0.26,0},
		["DuskIntensity"] = {1,0.7,0},
		["HDRScale"] = {0.33,0.1},
		["StarFade"] = function(procent) return max(1 - procent * 10,0) end,

		-- Sun
		["SunSize"] = function(procent) return max(0,10 - (10 * procent)) end,
		["SunOverlay"] = function(procent) return max(0,2 - (2 * procent)) end,
		["SunColor"] = Color(255,255,255,15),
		["MapLight"] = {10,1},
		["SunLight"] = 10,

		-- Moon
		["MoonLight"] = function(procent) return 100 - procent * 90 end,

		-- Fog
		["Fogdensity"] = {0.9,0.95},
		["Fogend"] = {54000,30000},
		["Fogstart"] = {0,-1000},
		-- Rain
		["Gauge"] = 0
	}

	-- Cloudy
		StormFox.AddWeather("Cloudy",BasicClouds)
	-- Fog
		local fog = table.Copy(BasicClouds)
			fog["Fogstart"] = {-400,-500}
			fog["Fogend"] = {800,600}
			fog["Fogdensity"] = {0.8,0.8}
			fog["SkyColor"] = {Color(51, 127.5, 255),Color(204, 255, 255)}
		StormFox.AddWeather("Fog",fog)
	-- Rain
		local Rain = table.Copy(BasicClouds)
			Rain["Gauge"] = function(procent) return procent * 10 end
			Rain["MapBloom"] = {1.2,1.4}
			Rain["MapBloomMax"] = {0.4,1.4}
		StormFox.AddWeather("Rain",Rain)

-- Weather Brain
	local function LeapVarable(at_zero,at_one,procent) -- Number, table and color
		--if not procent then procent = 1 end
			if procent <= 0 then
				if type(at_zero) == "function" then
					return at_zero(procent)
				else
					return at_zero
				end
			end
			if procent >= 1 or type(at_zero) != type(at_one) then
				if type(at_one) == "function" then
					return at_one(procent)
				else
					return at_one
				end
			end
			if type(at_zero) == "number" then
				local delta = at_one - at_zero -- Deltavar
				return at_zero + delta * procent
			elseif type(at_zero) == "table" then
				if at_zero.a and at_zero.r and at_zero.g and at_zero.b then
					-- color
					local r = LeapVarable(at_zero.r,at_one.r,procent)
					local g = LeapVarable(at_zero.g,at_one.g,procent)
					local b = LeapVarable(at_zero.b,at_one.b,procent)
					local a = LeapVarable(at_zero.a,at_one.a,procent)
					return Color(r,g,b,a)
				else
					-- A table of stuff? .. or what.
					local tab = table.Copy(at_zero)
					for key,var in pairs(at_one) do
						tab[key] = LeapVarable(at_zero[key],var,procent)
					end
					return tab
				end
			elseif type(at_one) == "function" then
				return at_one(procent)
			elseif type(at_zero) == "function" then
				return at_one(procent)
			end
			if procent < 0.5 then
				return at_zero
			end
			return at_one
	end

	local CurrentWeatherData = table.Copy(Weather.Clear)
	function StormFox.SetWeather(name,procent)
		if not Weather[name] then print("[StormFox] Weather not found:",name) return end
		StormFox.Weather = name
		if not procent then
			procent = 1
		else
			procent = clamp(procent,0,1)
		end
		StormFox.SetData("Weather",procent > 0 and name or "Clear")
		CurrentWeatherData = table.Copy(Weather.Clear)
		if procent <= 0 then
			return CurrentWeatherData
		end
		for key,data in pairs(Weather[name]) do
			if not CurrentWeatherData[key] then
				CurrentWeatherData[key] = data
			else
				CurrentWeatherData[key] = LeapVarable(CurrentWeatherData[key],data,procent)
			end
		end
		return CurrentWeatherData
	end

	local function Get(var,id)
		if type(var) == "table" then
			return var[id] or var[1]
		end
		return var
	end

	local skyUpdate = 0
	hook.Add("StormFox - Timeset","StormFox - FixSky",function()
		skyUpdate = 0
	end)
	local function weatherThink(force)
		if not force and skyUpdate > SysTime() then return end
		local t = StormFox.GetTimeSpeed()
		if t <= 0 then t = 2 end
		skyUpdate = SysTime() + updateTime / t
		-- Sun
			local sunSize = floor(StormFox.GetData("SunSize") or 30,0)
			local sunOverLay = floor(StormFox.GetData("SunOverlay") or 30,0)
			StormFox.SetSunSize(sunSize > 15 and sunSize or 0)
			StormFox.SetSunOverlaySize(sunOverLay)
			StormFox.SetSunColor(StormFox.GetData("SunColor"))
			StormFox.SetSunOverlayColor(StormFox.GetData("SunColor"))

		-- Fix maps with no light enviroment
	--	if StormFox.GetData("has_light_environment",false) then
			StormFox.SetMapBloom(StormFox.GetData("MapBloom",0))
			StormFox.SetMapBloomAutoExposureMin(StormFox.GetData("MapBloomMin",0.7))
			StormFox.SetMapBloomAutoExposureMax(StormFox.GetData("MapBloomMax",1))
	--	else
			StormFox.SetMapBloom(0)
	--	end

		local time = StormFox.GetTime() -- The updateTime seconds in the furture (Unless you speed up time)
		if t <= 0 then t = 0.2 end
			time = time + updateTime / t

		local daytime = StormFox.GetDaylightAmount(time)
		StormFox.SetData("Topcolor",LeapVarable(Get(CurrentWeatherData["SkyColor"],1),Get(CurrentWeatherData["NightColor"],1),1 - daytime),time)
		StormFox.SetData("Bottomcolor",LeapVarable(Get(CurrentWeatherData["SkyColor"],2),Get(CurrentWeatherData["NightColor"],2),1 - daytime),time)
		StormFox.SetMapLight(LeapVarable(CurrentWeatherData["MapLight"][1],CurrentWeatherData["MapLight"][2],1 - daytime))


		local n = (CurrentWeatherData["StarFade"] or 1.5) * clamp(((1 - daytime) - 0.5) * 2,0,1)
		StormFox.SetData("StarFade",n,time)
		if n > 0 then
			StormFox.SetData("DrawStars",CurrentWeatherData["DrawStars"],time)
			StormFox.SetData("StarTexture",CurrentWeatherData["StarTexture"],time)
			StormFox.SetData("StarSpeed",CurrentWeatherData["StarSpeed"],time)
		end

		-- Sun
			-- SkyPaint
		--	StormFox.SetData("SunSize",CurrentWeatherData["SunSize"] * daytime,time)
		--	StormFox.SetData("SunOverlay",CurrentWeatherData["SunOverlay"] * daytime,time)
		local blacklist = {"SkyColor","NightColor","StarFade"}
			for key,var in pairs(CurrentWeatherData) do
				if not table.HasValue(blacklist,key) then
					if type(var) == "table" then
						if (var.r and var.g and var.b) or #var < 2 then
							-- Just color or something
							StormFox.SetData(key,var,time)
						else
							-- Alright, time based
							if #var == 2 then
								-- Day, night
								local nn = LeapVarable(var[1],var[2],1 - daytime)
								StormFox.SetData(key,nn,time)
							else
								-- Day, sunset/sunrise, night
								local p = daytime * 2 -- DayLight [0-2] (0 night, 1 sunset/rise, 2 day)
								if daytime > 0.5 then -- 0 horizon - 1 day
									p = (daytime - 0.5) * 2 -- (0 sunset/rise, 1 day)
									local nn = LeapVarable(var[2],var[1],p)
									StormFox.SetData(key,nn,time)
								else -- 0 night - 1 horizon
									local nn = LeapVarable(var[3],var[2],min(p * 1.25,1)) -- (1.25 gives a nice 'effect' as sunrise is quicker)
									StormFox.SetData(key,nn,time)
								end
							end
						end
					elseif type(var) != "function" then
						-- String, numbers, set varables
						StormFox.SetData(key,var,time)
					end
				end
			end
	end
	hook.Add("Think","StormFox - Think",weatherThink)

-- Reload
timer.Simple(1,StormFox.SendAllData)