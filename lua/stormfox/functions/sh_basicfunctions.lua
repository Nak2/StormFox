--[[-------------------------------------------------------------------------
	This is some easy shared functions to help SF-addons and other varables.
---------------------------------------------------------------------------]]

-- Time functions
	function StormFox.IsNight()
		local t = StormFox.GetTime()
		return t > 1080 or t < 360
	end

	function StormFox.IsDay()
		return not StormFox.IsNight()
	end

	-- 360, 1080
	local abs,rad,cos = math.abs,math.rad,math.cos
	function StormFox.GetSun_SetRise(t)
		local t = t or StormFox.GetTime()
		local a = 0
		if t > 300 and t < 420 then
			a = abs(t - 360)
		elseif t > 1020 and t < 1140 then
			a = abs(t - 1080)
		else
			return 0
		end
		return cos(rad(a * 1.5))
	end

-- Weather functions
	local clamp = math.Clamp

	function StormFox.CelsiusToFahrenheit(num)
		return num * 1.8 + 32
	end

	-- Beaufort scale
		local bfs = {}
			bfs[0] = "Calm"
			bfs[0.3] = "Light Air"
			bfs[1.6] = "Light Breeze"
			bfs[3.4] = "Gentle breeze"
			bfs[5.5] = "Moderate breeze"
			bfs[8] = "Fresh breeze"
			bfs[10.8] = "Strong breeze"
			bfs[13.9] = "Near gale"
			bfs[17.2] = "Gale"
			bfs[20.8] = "Strong gale"
			bfs[24.5] = "Storm"
			bfs[28.5] = "Violent Storm"
			bfs[32.7] = "Hurricane"
		local bfkey = table.GetKeys(bfs)
		table.sort(bfkey,function(a,b) return a < b end)
	function StormFox.GetBeaufort(ms)
		local n = ms or StormFox.GetData( "Wind" , 0 )
		local Beaufort, Description = 0, "Calm"
		for k,kms in ipairs( bfkey ) do
			if kms < n then
				Beaufort, Description = k - 1, bfs[ kms ]
			else
				break
			end
		end
		return Beaufort, Description
	end

	function StormFox.IsRaining()
		return StormFox.GetData("Gauge",0) > 0
	end

	function StormFox.IsThunder()
		return StormFox.GetNetworkData("Thunder",false)
	end

	function StormFox.GetWeather()
		return StormFox.Weather:GetName()
	end

	function StormFox.GetWeatherMagnitude()
		return StormFox.GetNetworkData("WeatherMagnitude",0)
	end

	function StormFox.GetWeatherID()
		return StormFox.GetNetworkData("Weather","clear")  
	end

	function StormFox.GetTemperature(fahrenheit)
		local temp = StormFox.GetNetworkData("Temperature",0)
		if not fahrenheit then return temp end
		return StormFox.CelsiusToFahrenheit(temp)
	end

	if SERVER then
		function StormFox.SetTemperature(temp,use_fahrenheit)
			if use_fahrenheit then
				StormFox.SetNetworkData("Temperature",(temp - 32) / 1.8)
			else
				StormFox.SetNetworkData("Temperature",temp)
			end
		end
		function StormFox.SetThunder(bool)
			StormFox.SetNetworkData("Thunder",bool)
		end
	end

-- Serverside moon and sun angle.. thise are only calculated when needed (Server never really uses them besides calc moonphase each night)
	if SERVER then
		function StormFox.GetSunAngle(time)
			local pitch = (((time or StormFox.GetTime()) / 360) - 1) * 90 + 180
			if pitch < 0 then pitch = pitch + 360 end
			return Angle(pitch,StormFox.GetSunMoonAngle(), 0)
		end
		function StormFox.GetMoonAngle(time)
			local t = time or StormFox.GetTime()
			local pitch = ((t / 360) - 1) * 90
			if pitch < 0 then pitch = pitch + 360 end
			local ang = Angle(pitch,StormFox.GetSunMoonAngle(), 0)
			local p_offset,r_offset = StormFox.GetNetworkData("Moon-offset_p",0),StormFox.GetNetworkData("Moon-offset_r",0)
			-- Smooth
				local p = t / 1440
				local c_offset_p = 12.2 * p
				local c_offset_r = 0.98 * p
			local moonAng = Angle((ang.p + p_offset + c_offset_p) % 360,ang.y,ang.r)
			moonAng:RotateAroundAxis(moonAng:Up(),math.cos((r_offset + c_offset_r) % 360) * 28.5)
			moonAng = moonAng:Forward():Angle()
			return moonAng
		end
	end

-- Moonphase
	function StormFox.GetMoonPhaseNumber(time)
		local sunAng,moonAng = StormFox.GetSunAngle(time),StormFox.GetMoonAngle(time)
		local A = sunAng:Forward() * 14975
		local B = moonAng:Forward() * 39
		local moonTowardSun = (A - B):Angle()
		local C = moonAng
			C.r = 0
		local dot = C:Forward():Dot(moonTowardSun:Forward())
		return 45.625 - 62.5 * dot
	end

	if SERVER then
		StormFox.SetNetworkData("MoonPhase",StormFox.GetMoonPhaseNumber())
		hook.Add("StormFox-NewDay", "StormFox-CalcMoonphase", function()
			StormFox.SetNetworkData("MoonPhase",StormFox.GetMoonPhaseNumber())
		end )
		hook.Add("StormFox - Timeset","StormFox-CalcMoonphaseTS",function()
			timer.Simple(0,function()
				StormFox.SetNetworkData("MoonPhase",StormFox.GetMoonPhaseNumber())
			end)
		end)
	end

	function StormFox.GetMoonPhase() -- Returns moonphase-name and procent of light
		local currentMoonPhase_num = StormFox.GetNetworkData("MoonPhase",0)
		if currentMoonPhase_num >= 99 then -- 99% -
			return "Full",currentMoonPhase_num
		elseif currentMoonPhase_num > 51 then -- 51% - 99%
			return "Gibbous",currentMoonPhase_num
		elseif currentMoonPhase_num >= 49 then -- 49% - 51%
			return "Quarter",currentMoonPhase_num
		elseif currentMoonPhase_num >= 1 then -- 1% - 49%
			return "Crescent",currentMoonPhase_num
		else
			return "New",currentMoonPhase_num
		end
	end
