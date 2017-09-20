

local mclamp = math.Clamp

local function ShadowAngleThink( )
	flTime = StormFox.GetTime()
	local pitch = ( ( flTime / 360 ) - 1 ) * 90
	if pitch < 0 then pitch = pitch + 360 end
	if pitch > 180 then pitch = ( pitch + 180 ) % 360 end

	local ml = StormFox.GetDaylightAmount()
	local shadowColor = 255
	if ml > 0.1 then
		shadowColor = ( 1 - ( ml - 0.4 ) ) * 255
	else
		shadowColor = ( 0.9 + ml * 2.5 ) * 255
	end
	sunAlpha = mclamp( shadowColor, 0, 255 )
	StormFox.SetShadowAngle( pitch )
	StormFox.SetShadowColor( Color( shadowColor, shadowColor, shadowColor ) )

end
timer.Create( 2.5, "StormFox.UpdateShadows", ShadowAngleThink )
