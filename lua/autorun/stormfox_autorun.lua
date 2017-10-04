StormFox = {}
StormFox.Version = 2.0

if SERVER then
	game.ConsoleCommand("sv_skyname painted\n")
end
--if true then return end
-- Reload support
hook.Add("InitPostEntity","StormFox-PostEntitiy",function()
	hook.Call("StormFox - PostEntity")
	_STORMFOX_POSTENTIY = true
end)
if _STORMFOX_POSTENTIY then
	timer.Simple(1,function()
		hook.Call("StormFox - PostEntity")
	end)
end

-- Add configs
if not ConVarExists("sf_timespeed") then
	CreateConVar("sf_timespeed",1, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "The minutes of gametime pr second." )
end
if not ConVarExists("sf_moonscale") then
	CreateConVar("sf_moonscale",6,{ FCVAR_REPLICATED , FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Set the moonscale." )
end
if not ConVarExists("sf_sv_material_replacment") then
	CreateConVar("sf_sv_material_replacment",1, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Replaces materials for weather effects.")
end
if not ConVarExists("sf_replacment_dirtgrassonly") then
	CreateConVar("sf_replacment_dirtgrassonly",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Replace only dirt and grass. (Useful on crazy maps)")
end
if not ConVarExists("sf_disablefog") then
	CreateConVar("sf_disablefog",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Disable the fog.")
end
if not ConVarExists("sf_disable_autoweather") then
	CreateConVar("sf_disable_autoweather",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Disable the automatic weather-generator.")
end

if not ConVarExists("sf_minimum_temp") then
	CreateConVar("sf_minimum_temp", 5, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Sets the minimum temp")
end

if not ConVarExists("sf_disable_mapsupport") then
	CreateConVar("sf_disable_mapsupport",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Disable the entity-support for maps.")
end
if not ConVarExists("sf_disable_autoweather_cold") then
	CreateConVar("sf_disable_autoweather_cold",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Stop the autoweather creating snow.")
end

if SERVER then
	resource.AddWorkshop("1132466603")
else
	CreateClientConVar("sf_graphic_settings", "2", true,false,"[0-4] Adjusts the amount of expensive calculations and effects created by the weather Default: 2.")
	CreateClientConVar("sf_material_replacment","1",true,false,"Enable material replacment for weather effects.")
	CreateClientConVar("sf_allow_rainsound","1",true,false,"Enable rain-sounds.")
	CreateClientConVar("sf_allow_windsound","1",true,false,"Enable wind-sounds.")
	CreateClientConVar("sf_allow_raindrops","1",true,false,"Enables raindrops on the screen")
end

-- Launch Stormfox
	-- Adds and runs files
	local function HandleFile(str)
		local path = str
		if string.find(str,"/") then
			path = string.GetFileFromFilename(str)
		end
		local _type = string.sub(path,0,3)
		if SERVER then
			if _type == "cl_" or _type == "sh_" then
				AddCSLuaFile(str)
			end
			if _type != "cl_" then
				return include(str)
			end
		elseif _type != "sv_" then
			return include(str)
		end
	end

HandleFile("stormfox/" .. "sh_variables.lua")
HandleFile("stormfox/" .. "cl_performance_config.lua")
HandleFile("stormfox/" .. "sh_weathertype_meta.lua")

for _,fil in ipairs(file.Find("stormfox/framework/*.lua","LUA")) do
	HandleFile("stormfox/framework/" .. fil)
end


HandleFile("stormfox/" .. "sh_weather_controller.lua")

for _,fil in ipairs(file.Find("stormfox/functions/*.lua","LUA")) do
	HandleFile("stormfox/functions/" .. fil)
end

for _,fil in ipairs(file.Find("stormfox/weather_types/*.lua","LUA")) do
	HandleFile("stormfox/weather_types/" .. fil)
end


if SERVER then
	HandleFile("stormfox/" .. "sv_map_lights.lua")
	HandleFile("stormfox/" .. "sv_weather_generator.lua")
end
