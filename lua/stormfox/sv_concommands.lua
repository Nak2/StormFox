--[[-------------------------------------------------------------------------
Console commands, for dedicated servers and people who prefer the console.
	sf_settime <time>			"19:00", "7:00 PM" or minutes (0-1440)
	sf_settimespeed <number>
	sf_setwind <0-75>
	sf_setwindangle <0-360>
	sf_settemperature <number>	Celsius. Add 'f' for Fahrenheit ( "70f" )
	sf_setthunder <0/1>
	sf_setting <convar> <value>	Any StormFox serversetting.
(sf_setweather is in sh_options.lua)
---------------------------------------------------------------------------]]
local function Reply(ply,...)
	local msg = table.concat({...}," ")
	if IsValid(ply) then
		ply:PrintMessage(HUD_PRINTCONSOLE,"[StormFox] " .. msg .. "\n")
	else
		StormFox.Msg(msg)
	end
end

local function AddWeatherCommand(name,help,func)
	concommand.Add(name,function(ply,_,args,argStr)
		StormFox.Permission.WetherEdit(ply,function()
			local reply = func(args,argStr)
			if reply then Reply(ply,reply) end
		end)
	end,nil,help)
end

AddWeatherCommand("sf_settime","Sets the time. Use '19:00', '7:00 PM' or minutes.",function(_,argStr)
	argStr = string.Trim(argStr or "")
	if argStr == "" then return "Usage: sf_settime 19:00" end
	if not StormFox.SetTime(tonumber(argStr) or argStr) then
		return "Invalid time: " .. argStr
	end
end)

AddWeatherCommand("sf_settimespeed","Sets how fast time moves. 0 stops time.",function(args)
	local n = tonumber(args[1])
	if not n or n < 0 then return "Usage: sf_settimespeed <number>" end
	RunConsoleCommand("sf_timespeed",tostring(n))
end)

AddWeatherCommand("sf_setwind","Sets the wind-speed (0-75).",function(args)
	local n = tonumber(args[1])
	if not n then return "Usage: sf_setwind <0-75>" end
	StormFox.SetNetworkData("Wind",math.Clamp(n,0,75))
end)

AddWeatherCommand("sf_setwindangle","Sets the wind direction (0-360).",function(args)
	local n = tonumber(args[1])
	if not n then return "Usage: sf_setwindangle <0-360>" end
	StormFox.SetNetworkData("WindAngle",n % 360)
end)

AddWeatherCommand("sf_settemperature","Sets the temperature. Add 'f' for Fahrenheit.",function(_,argStr)
	argStr = string.Trim(argStr or "")
	local n = tonumber(string.match(argStr,"^-?%d+%.?%d*"))
	if not n then return "Usage: sf_settemperature 20 ( or 70f )" end
	StormFox.SetTemperature(n,string.find(argStr,"[fF]") ~= nil)
end)

AddWeatherCommand("sf_setthunder","Enables or disables thunder.",function(args)
	StormFox.SetThunder(tobool(args[1]))
end)

-- Settings. Only StormFox convars.
concommand.Add("sf_setting",function(ply,_,args)
	local name,value = args[1],args[2]
	if not name or not value then
		Reply(ply,"Usage: sf_setting <setting> <value>")
		return
	end
	if not StormFox.convars[name] then
		Reply(ply,"Invalid setting: " .. name)
		return
	end
	StormFox.Permission.SettingsEdit(ply,function()
		RunConsoleCommand(name,value)
		Reply(ply,name .. " = " .. value)
	end)
end,function(cmd,argStr)
	argStr = string.lower(string.TrimLeft(argStr or ""))
	local tab = {}
	for name in pairs(StormFox.convars) do
		if string.find(name,argStr,1,true) then
			tab[#tab + 1] = cmd .. " " .. name
		end
	end
	table.sort(tab)
	return tab
end,"Changes a StormFox serversetting.")
