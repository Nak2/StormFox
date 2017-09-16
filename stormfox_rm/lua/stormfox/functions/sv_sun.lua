
local sunAng = Angle(0,0,0)
local env_var = 0
local mmax,mabs,mclamp = math.max,math.abs,math.Clamp

local function SunAngleThink(time)
	time = time or StormFox.GetTime()
	local pitch = ((time / 360) - 1) * 90
	if pitch < 0 then pitch = pitch + 360 end

	local ang = Angle(pitch,StormFox.GetData("SunMoonAngle",0), 0)
	sunAng = ang
	local forceday = false
	local env_vars = false
	if env_var <= SysTime() then
		env_var = SysTime() + 1
		env_vars = true
		local sa = 1
		local ml = StormFox.GetDaylightAmount()
		if ml < 0.1 then
			-- follow night
			sa = 0.9 + ml * 2.5
		elseif ml < 0.4 then
			-- no shadow
			sa = 1
			env_vars = false
		else
			-- follow day
			sa = 1 - (ml - 0.4)
		end
		sa = mclamp(sa,0,1)
		if ml < 0.1 then
			-- night
			StormFox.SetShadowColor(Color(255 * sa,255 * sa,255 * sa)) -- dark
		else
			forceday = true
			StormFox.SetShadowColor(Color(255 * sa,255 * sa,255 * sa)) -- lightish
		end
	end
	StormFox.SetSunAngle(ang,env_vars,forceday)
end

function StormFox.GetSunAngle()
	return sunAng
end

function StormFox.GetSunZenith()
	--return math.abs(math.AngleDifference(StormFox.GetSunAngle().p,270))
	return math.AngleDifference(StormFox.GetSunAngle().p,270)
end

-- SunCalc
local aa = 0
hook.Add("StormFox-Tick","StormFox - Sun",function(time)
	if aa >= 2 then return end
	SunAngleThink(time)
end)
hook.Add("Think","StormFox - Sun",function()
	if aa < 2 then return end
	SunAngleThink()
end)

-- That was kinda easy ..
-- .. or not


--color = Color1math.clamp(0,1,sin(A)) + Color2math.clamp(0,1,sin(A) * -1)