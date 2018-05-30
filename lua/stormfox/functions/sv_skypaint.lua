
-- Galexy
	StormFox.SetNetworkData("GalaxyAngle",math.random(90))
	hook.Add("StormFox-Sunset","StormFox.SetGalaxyAngle",function()
		StormFox.SetNetworkData("GalaxyAngle",math.random(360))
	end)