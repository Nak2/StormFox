

StormFox.SunMoonAngle = 270 -- The roll angle the sun and move follow
StormFox.Data = StormFox.Data or {}


function StormFox.GetData( sKey, anyFallback )
	return StormFox.Data[ sKey ] or anyFallback
end

function StormFox.SetData( sKey, anyValue )
	if anyValue == nil then return end
	StormFox.Data[ sKey ] = anyValue
end

function StormFox.GetDataTable()
	return StormFox.Data
end


StormFox.SetData( "Temperature", 20 )
StormFox.SetData( "Wind", 0 )
StormFox.SetData( "WindAngle", math.random(360) ) --cl
StormFox.SetData( "ThunderLight", 0 )

-- if CLIENT then
--
--
-- end
