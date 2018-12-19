--[[-------------------------------------------------------------------------
	This is some easy shared functions to help SF-addons and with other varables.
---------------------------------------------------------------------------]]
local clamp = math.Clamp
local min,max,sqrt = math.min,math.max,math.sqrt
local mad = math.AngleDifference

-- Local functions
	local function ColorMixer(c1,c2) -- c2 alpha controls the color applied
		local c2a = c2.a / 255
		local c2an = 1 - c2a
		local r = c1.r * c2an + c2.r * c2a
		local g = c1.g * c2an + c2.g * c2a
		local b = c1.b * c2an + c2.b * c2a
		return Color(r,g,b,c1.a)
	end

	local function ET(pos,pos2,mask,filter)
		local t = util.TraceLine( {
			start = pos,
			endpos = pos + pos2,
			mask = mask,
			filter = filter
			} )
		t.HitPos = t.HitPos or (pos + pos2)
		return t,t.HitSky
	end

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

	function StormFox.IsTimeBetween(from,to)
		if type(from) == "string" then from = StormFox.StringToTime(from) end
		if type(to) == "string" then to = StormFox.StringToTime(to) end
		local t = StormFox.GetTime()
		if from <= to then
			return t >= from and t <= to
		else
			return t >= from or t <= to
		end
	end

-- Weather functions
	local clamp = math.Clamp

	function StormFox.CelsiusToFahrenheit(num)
		return num * 1.8 + 32
	end

	-- Beaufort scale and Saffir–Simpson hurricane scale
		local bfs = {}
			bfs[0] = "Calm"
			bfs[0.3] = "Light Air"
			bfs[1.6] = "Light Breeze"
			bfs[3.4] = "Gentle Breeze"
			bfs[5.5] = "Moderate Breeze"
			bfs[8] = "Fresh Breeze"
			bfs[10.8] = "Strong Breeze"
			bfs[13.9] = "Near Gale"
			bfs[17.2] = "Gale"
			bfs[20.8] = "Strong Gale"
			bfs[24.5] = "Storm"
			bfs[28.5] = "Violent Storm"
			bfs[32.7] = "Hurricane"
			bfs[43] = "Category 2"
			bfs[50] = "Category 3"
			bfs[58] = "Category 4"
			bfs[70] = "Category 5"
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
		hook.Add("StormFox - NewDay", "StormFox - CalcMoonphase", function()
			StormFox.SetNetworkData("MoonPhase",StormFox.GetMoonPhaseNumber())
		end )
		hook.Add("StormFox - Timeset","StormFox - CalcMoonphaseTS",function()
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
-- Map light functions
	-- Sun light amount
		local tt,cc = -1,-1
		function StormFox.GetSunLightAmount()
			if tt > CurTime() then return cc end
				tt = CurTime() + 1
			cc = StormFox.GetData("DayLightAmount",100) / 100 -- 1 at day, 0 at night
			return cc
		end
	-- Moon light amount	
		local t,c = -1,-1
		function StormFox.GetMoonLightAmount()
			if t > CurTime() then return c end
				t = CurTime() + 1
			local a = StormFox.GetMoonAngle()
			local light_aa = clamp(mad(a.p,360) / -90 * 5,0,1) -- 1 if moon is on the sky, 0 if it isn't
			local vis = (StormFox.GetData("MoonVisibility",100)-50) / 60
			light_aa = vis * light_aa -- Use the moon visibility

			local _,pla = StormFox.GetMoonPhase() -- Get the light amount for the current phase (0-100)

			c = clamp(light_aa * (pla / 100),0,1)

			return c
		end
	-- Sky light
		local ttt,ccc,aaa = -1,Color(0,0,0,0),0
		function StormFox.GetAmbientLight() -- Returns color and angle
			if ttt > CurTime() then return ccc,aaa end
				ttt = CurTime() + 0.5
			local sun_l = StormFox.GetSunLightAmount()
			local c,a
			if sun_l > 0 then
				-- Sun is in the sky
				local sc = StormFox.GetData("SunColor", Color(255,255,255))
				c,a = Color(sc.r,sc.g,sc.b,sun_l * 255),StormFox.GetSunAngle()
			else
				-- Moon
				local m_l = StormFox.GetMoonLightAmount()
				local mc = StormFox.GetData("MoonColor",Color(205,205,205))
				c,a = Color(mc.r * 0.62,mc.g * 0.78,mc.b,m_l * 150),StormFox.GetMoonAngle() -- 150,200,255
			end
			a = Angle(a.p,a.y,a.r)
			-- Add sunset and sunrise
			local sun_riseset = StormFox.GetSun_SetRise()
			if sun_riseset >= 0.1 then -- ignore the moon
				local sa = StormFox.GetSunAngle()
				a = Angle(sa.p,sa.y,sa.r)
				if a.p > 90 and a.p < 270 then -- sunrise
					a.p = max(a.p,190)
				else
					if a.p > 180 then
						a.p = min(a.p,350)
					else
						a.p = max(a.p,350)
					end
				end
			end
			local sun_rise = Color(250, 214, 165,sun_riseset * 255) -- from wiki https://en.wikipedia.org/wiki/Sunset_(color)
			local c = ColorMixer(c,sun_rise)
				ca = c.a / 255
			a.p = a.p + 180
			ccc = Color(c.r * ca,c.g * ca,c.b * ca),a
			aaa = a
			return ccc,aaa
		end

-- Wind functions
	local windNorm = Vector(0,0,1)
	local windVec = Vector(0,0,0)
	local wind = 0
	timer.Create("StormFox - WindUpdater",1,0,function()
		wind = StormFox.GetNetworkData("Wind",0) * 0.75
		local windangle = StormFox.GetNetworkData("WindAngle",0)
		windNorm = Angle( 90 - sqrt(wind) * 10 ,windangle,0):Forward()

		windVec = windNorm * wind
		windNorm:Normalize()
	end)
	function StormFox.GetWindNorm()
		return windNorm
	end
	function StormFox.GetWindVector()
		return windVec
	end
	local max_dis = 32400
	function StormFox.IsVectorInWind(vec ,filter )
		local tr = ET(vec, windNorm * -640000, MASK_SHOT, filter)
		local hitSky = tr.HitSky
		local dis = tr.HitPos:DistToSqr( vec )
		if not hitSky and dis >= max_dis then -- So far away. The wind would had gone around. Check if we're outside.
			local tr = ET(vec,Vector(0,0,640000),MASK_SHOT,filter)
			hitSky = tr.HitSky
		end
		return hitSky,tr
	end
	local e_pos = function(ent)
		if ent:IsPlayer() then
			return ent:GetShootPos()
		else
			return ent:OBBCenter() + ent:GetPos()
		end
	end
	-- Checks if the entity is in the wind (or rain)
	function StormFox.IsEntityInWind(ent,dont_cache)
		if not dont_cache then
			if ent.sf_wind_var then
				if ent.sf_wind_var[2] > CurTime() then
					return ent.sf_wind_var[1],windNorm
				end
			else
				ent.sf_wind_var = {}
			end
		end
		local pos = ent:OBBCenter() + ent:GetPos()
		local tr = ET(pos, windNorm * -640000, MASK_SHOT, ent)
		local hitSky = tr.HitSky
		local dis = tr.HitPos:DistToSqr( pos )
		if not hitSky and dis >= max_dis then -- So far away. The wind would had gone around. Check if we're outside.
			local tr = ET(pos,Vector(0,0,640000),MASK_SHOT,ent)
			hitSky = tr.HitSky
		end
		if not dont_cache then
			ent.sf_wind_var[1] = hitSky
			ent.sf_wind_var[2] = CurTime() + 1
		end
		return hitSky,windNorm
	end
	-- Checks if the entity is outside (It can still be shield by a prop above)
	function StormFox.IsEntityOutside(ent,dont_cache)
		if not dont_cache then
			if ent.sf_outside_var then
				if ent.sf_outside_var[2] > CurTime() then
					return ent.sf_outside_var[1],windNorm
				end
			else
				ent.sf_outside_var = {}
			end
		end
		local pos = e_pos(ent)
		local tr = ET(pos, windNorm * -640000, MASK_SHOT, ent)
		local hitSky = tr.HitSky
		local dis = pos:DistToSqr( Vector(tr.HitPos.x,tr.HitPos.y,pos.z) )
		if not hitSky then -- Check trace up
			local tr = ET(pos,Vector(0,0,640000),MASK_SHOT,ent)
			hitSky = tr.HitSky
		end
		if not dont_cache then
			ent.sf_outside_var[1] = hitSky
			ent.sf_outside_var[2] = CurTime() + 1
		end
		return hitSky,windNorm
	end
	-- Checks if the entity is in rain
	function StormFox.IsEntityInRain( ent, dont_cache )
		if StormFox.GetData("Gauge",0) <= 0 then return false end
		return StormFox.IsEntityOutside(ent,dont_cache)
	end