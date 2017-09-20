
local sunAng = Angle(0,0,0)
local nextShadowUpdate = 0
local mmax, mabs, mclamp = math.max, math.abs, math.Clamp

local function SunAngleThink(time)
	time = time or StormFox.GetTime()
	local pitch = ((time / 360) - 1) * 90
	if pitch < 0 then pitch = pitch + 360 end

	local ang = Angle( pitch, StormFox.GetData( "SunMoonAngle", 0 ), 0 )
	sunAng = ang

	local forceday = false
	local drawShadow = false
	if nextShadowUpdate <= SysTime() then
		nextShadowUpdate = SysTime() + 2.5
		drawShadow = true

		local ml = StormFox.GetDaylightAmount()
		local sunAlpha = 255

		if ml > 0.1 then
			drawShadow = ml < 0.4
			forceday = true
			sunAlpha = ( 1 - ( ml - 0.4 ) ) * 255
		else
			sunAlpha = ( 0.9 + ml * 2.5 ) * 255
		end

		sunAlpha = mclamp( sunAlpha, 0, 255 )
		StormFox.SetShadowColor( Color( sunAlpha, sunAlpha, sunAlpha ) )
	end
	StormFox.SetSunAngle( ang, drawShadow, forceday )
end

function StormFox.GetSunAngle()
	return sunAng
end

function StormFox.GetSunZenith()
	--return math.abs(math.AngleDifference(StormFox.GetSunAngle().p,270))
	return math.AngleDifference(StormFox.GetSunAngle().p,270)
end

-- SunCalc
hook.Add("StormFox-Tick","StormFox - Sun", function( time )
	SunAngleThink(time)
end)


-- That was kinda easy ..
-- .. or not


--color = Color1math.clamp(0,1,sin(A)) + Color2math.clamp(0,1,sin(A) * -1)
