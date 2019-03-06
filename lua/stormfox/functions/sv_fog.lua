
--[[-------------------------------------------------------------------------
	Reads the maps fog_data and shares it to the clients
	This will tell the client what the "default" fog for the map doing the day.
---------------------------------------------------------------------------]]
local clamp = math.Clamp
hook.Add("StormFox.PostEntityScan","Fog reader",function()
	if not StormFox.env_fog_controller then return end
	local fog_val = StormFox.env_fog_controller:GetKeyValues()
	StormFox.SetNetworkData("fog_start",clamp(fog_val["fogstart"] or -100,-1000,0))
	StormFox.SetNetworkData("fog_end",clamp(fog_val["fogend"] or 108000,7000,108000))
	StormFox.SetNetworkData("fogmaxdensity",clamp(fog_val["fogmaxdensity"] or 0.8,0.2,0.9))
end)