--[[-------------------------------------------------------------------------
	Basic shared functions

---------------------------------------------------------------------------]]
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
		local n = ms or StormFox.GetData("Wind",0)
		local Beaufort,Desction = 0,"Calm"
		for k,kms in ipairs(bfkey) do
			if kms < n then
				Beaufort,Desction = k - 1,bfs[kms]
			else
				break
			end
		end
		return Beaufort,Desction
	end

-- WeatherData
	function StormFox.CelsiusToFahrenheit(num)
		return num * (9 / 5) + 32
	end

	local l,ld = 0
	local str = "Clear"
	function StormFox.GetWeatherName()
		if l > SysTime() then
			return str
		end
		l = SysTime() + 1
		--local weather = StormFox.GetData("Weather","Clear") Ignore weather. We want it to be dynamic
		local wind = StormFox.GetData("Wind",0) > 10
		local day_light = StormFox.GetDaylightAmount()
		local temp = StormFox.GetData("Temperature",20)
		local gauge = StormFox.GetData("Gauge",0)
		local thunder = StormFox.GetData("Thunder",false)
		local foggy = StormFox.GetData("Fogend",2000) <= 5500 and StormFox.GetData("Fogstart",0) < - 100
			str = "Cloudy"
		if gauge <= 0 then
			-- No rain
			if thunder then
				str = "Thunder"
			elseif foggy then
				str = "Fog"
			elseif wind then
				str = "Windy"
			elseif day_light > 0.4 then
				if temp < -2 then
					str = "Icy"
				else
					str = "Sunny"
				end
			else
				str = "Night"
			end
		else
			-- Rain
			if thunder then
				str = "Raining - Thunder"
			else
				if temp > -2 and temp < 5 then
					str = "RainingSnowing"
				elseif temp < 0 then
					str = "Snowing"
				elseif wind then
					str = "Raining - Windy"
				else
					str = "Raining"
				end
			end
		end
		return str
	end

	if CLIENT then
		local l,ld = 0
		local str = ""
		function StormFox.GetWeatherSymbol()
			if l > SysTime() then
				return ld,str
			end
			l = SysTime() + 1
			--local weather = StormFox.GetData("Weather","Clear") Ignore weather. We want it to be dynamic
			local wind = StormFox.GetData("Wind",0) > 10
			local day_light = StormFox.GetDaylightAmount()
			local temp = StormFox.GetData("Temperature",20)
			local gauge = StormFox.GetData("Gauge",0)
			local thunder = StormFox.GetData("Thunder",false)
			local foggy = StormFox.GetData("Fogend",2000) <= 5500 and StormFox.GetData("Fogstart",0) < - 100
				str = "Cloudy"
			if gauge <= 0 then
				-- No rain
				if thunder then
					str = "Thunder"
				elseif foggy then
					str = "Fog"
				elseif wind then
					str = "Windy"
				elseif day_light > 0.4 then
					if temp < -2 then
						str = "Icy"
					else
						str = "Sunny"
					end
				else
					str = "Night"
				end
			else
				-- Rain
				if thunder then
					str = "Raining - Thunder"
				else
					if temp > -2 and temp < 5 then
						str = "RainingSnowing"
					elseif temp < 0 then
						str = "Snowing"
					elseif wind then
						str = "Raining - Windy"
					else
						str = "Raining"
					end
				end
			end
			ld = Material("stormfox/symbols/" .. str .. ".png")
			return ld
		end
	end