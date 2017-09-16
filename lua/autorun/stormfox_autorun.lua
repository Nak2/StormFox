StormFox = {}
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
	if not ConVarExists("sf_disable_mapsupport") then
		CreateConVar("sf_disable_mapsupport",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Disable the entity-support for maps.")
	end
	if not ConVarExists("sf_disable_autoweather_cold") then
		CreateConVar("sf_disable_autoweather_cold",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Stop the autoweather creating snow.")
	end

if SERVER then
	-- Permissions 
	resource.AddWorkshop("1132466603")
	-- Add addon content
	--[[
		local i = 0
		local function AddDir(dir,dirlen)
			if not dirlen then dirlen = dir:len() end
			local files, folders = file.Find(dir .. "/*", "GAME")
			for _, fdir in ipairs(folders) do
				if fdir != ".svn" then
					AddDir(dir .. "/" .. fdir)
				end
			end
			for k, v in ipairs(files) do
				local fil = dir .. "/" .. v --:sub(dirlen + 2)
				resource.AddFile(fil,dirlen)
				i = i + 1
			end
		end
		AddDir("materials/stormfox")
		AddDir("sound/stormfox")

		MsgN("[StormFox] Added " .. i .. " content files")]]
else
	CreateClientConVar("sf_exspensive","0",true,false,"[0-7+] Enable exspensive weather calculations.")
	CreateClientConVar("sf_material_replacment","1",true,false,"Enable material replacment for weather effects.")
	CreateClientConVar("sf_allow_rainsound","1",true,false,"Enable rain-sounds.")
	CreateClientConVar("sf_allow_windsound","1",true,false,"Enable wind-sounds.")
	CreateClientConVar("sf_allow_dynamiclights","1",true,false,"Enable lamp-lights from SF.")
	CreateClientConVar("sf_allow_sunbeams","1",true,false,"Enable sunbeams.")
	CreateClientConVar("sf_allow_dynamicshadow","0",true,false,"Enable dynamic light/shadows.")
	CreateClientConVar("sf_redownloadlightmaps","1",true,false,"Lighterrors and light_environment fix (Can lagspike)")

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
				--print("Running: " .. path)
				return include(str)
			end
		elseif _type != "sv_" then
			--print("Running: " .. path)
			return include(str)
		end
	end

--print("Framework")
for _,fil in ipairs(file.Find("stormfox/framework/*.lua","LUA")) do
	HandleFile("stormfox/framework/" .. fil)
end
--print("Functions")
for _,fil in ipairs(file.Find("stormfox/functions/*.lua","LUA")) do
	HandleFile("stormfox/functions/" .. fil)
end
--print("Rest")
HandleFile("stormfox/" .. "sh_options.lua")
if SERVER then
	HandleFile("stormfox/" .. "sv_map_lights.lua")
	HandleFile("stormfox/" .. "sv_weather_controller.lua")
	HandleFile("stormfox/" .. "sv_weather_generator.lua")
else

end