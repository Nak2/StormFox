
local sunAng = Angle(0,0,0)
local nextShadowUpdate = 0
local mmax, mabs, mclamp = math.max, math.abs, math.Clamp

local function SunAngleThink( flTime )
	if true then return true end -- Disabled for now. Why do we have a sun on both clientside and serverside?
	flTime = flTime or StormFox.GetTime()
	local pitch = ( ( flTime / 360 ) - 1 ) * 90
	if pitch < 0 then pitch = pitch + 360 end

	if nextShadowUpdate <= SysTime() then
		nextShadowUpdate = SysTime() + 2.5
		local ml = StormFox.GetDaylightAmount()
		local sunAlpha = 255
		if ml > 0.1 then
			sunAlpha = ( 1 - ( ml - 0.4 ) ) * 255
		else
			sunAlpha = ( 0.9 + ml * 2.5 ) * 255
		end
		sunAlpha = mclamp( sunAlpha, 0, 255 )
		StormFox.SetShadowColor( Color( sunAlpha, sunAlpha, sunAlpha ) )
	end
	StormFox.SetSunAngle( pitch )

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
