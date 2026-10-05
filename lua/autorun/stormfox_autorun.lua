StormFox = {}
StormFox.Version = 1.80
StormFox.WorkShopVersion = false--game.IsDedicated()

StormFox.NikNaks = false
if NikNaks or file.Exists("includes/modules/niknaks.lua","LUA") then
	pcall(require,"niknaks")
	StormFox.NikNaks = NikNaks and true or false
end

function StormFox.Msg(...)
	local a = {...}
	if StormFox.Language then
		for id,var in pairs(a) do
			if type(var) ~= "string" then continue end
			a[id] = StormFox.Language.Translate(var) or var
		end
	end
	MsgC(Color(155,155,255),"[StormFox] ",Color(255,255,255),unpack( a ),"\n")
end
StormFox.Msg("V " .. StormFox.Version .. (StormFox.NikNaks and " (NikNaks detected!)" or "."))

file.CreateDir("stormfox")
if SERVER then
	AddCSLuaFile()
	file.CreateDir("stormfox/maps")
end
-- Skypaint creation fix. For some odd reason this has to be called ASAP.
	local con = GetConVar("sf_skybox")
	if not con or con:GetBool() then
		RunConsoleCommand("sv_skyname", "painted")
	end
-- Local functions
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
			if _type ~= "cl_" then
				return include(str)
			end
		elseif _type ~= "sv_" then
			return include(str)
		end
	end
-- Load lib
	for _,fil in ipairs(file.Find("stormfox/lib/*.lua","LUA")) do
		HandleFile("stormfox/lib/" .. fil)
	end
	assert(StormFox.Language,"Missing language functions!")
-- Add resources
	if SERVER then
		if StormFox.WorkShopVersion then
			resource.AddWorkshop("1132466603")
		else
		-- Add addon content
			local i = 0
			local function AddDir(dir,dirlen)
				if not dirlen then dirlen = dir:len() end
				local files, folders = file.Find(dir .. "/*", "GAME")
				for _, fdir in ipairs(folders) do
					if fdir ~= ".svn" then
						AddDir(dir .. "/" .. fdir)
					end
				end
				for k, v in ipairs(files) do
					local fil = dir .. "/" .. v --:sub(dirlen + 2)
					resource.AddFile(fil)
					i = i + 1
				end
			end
			AddDir("materials/stormfox")
			AddDir("sound/stormfox")
			AddDir("models/sf_models")

			StormFox.Msg(StormFox.Language.Format("sf_added_content",i))
		end
	end
-- Launch Stormfox
	HandleFile("stormfox/" .. "cl_mvgui.lua")
	HandleFile("stormfox/" .. "sh_settings.lua")
	for _,fil in ipairs(file.Find("stormfox/framework/*.lua","LUA")) do
		HandleFile("stormfox/framework/" .. fil)
	end
	for _,fil in ipairs(file.Find("stormfox/functions/*.lua","LUA")) do
		HandleFile("stormfox/functions/" .. fil)
	end
	HandleFile("stormfox/" .. "sh_debugcompatibility.lua")
	HandleFile("stormfox/" .. "sh_weathertype_meta.lua")
	HandleFile("stormfox/" .. "sh_weather_controller.lua")
	HandleFile("stormfox/" .. "sv_map_lights.lua")
	HandleFile("stormfox/" .. "sv_weather_generator.lua")
-- Load weather types
	for _,fil in ipairs(file.Find("stormfox/weather_types/*.lua","LUA")) do
		if SERVER then
			AddCSLuaFile("stormfox/weather_types/" .. fil)
		end
		include("stormfox/weather_types/" .. fil)
	end
-- Finish loading
	HandleFile("stormfox/" .. "sh_options.lua")
	HandleFile("stormfox/" .. "cl_wizard.lua")
	HandleFile("stormfox/" .. "cl_mapbrowser.lua")
	HandleFile("stormfox/" .. "sv_concommands.lua")
	hook.Call("StormFox.PostInit")
-- Reload support
	hook.Add("LoadGModSave","StormFox.SandboxLoadSupport",function()
		hook.Call( "StormFox.PostEntity" )
	end)
	hook.Add("InitPostEntity","StormFox.CallPostEntitiy",function()
		_STORMFOX_POSTENTIY = true
		hook.Run("StormFox.PostEntity")
	end)
	if _STORMFOX_POSTENTIY then
		timer.Simple(1,function()
			hook.Run("StormFox.PostEntity")
		end)
	end
-- Hack to stop cleanupmap breaking SF
	STORMFOX_CLEANUPMAP = STORMFOX_CLEANUPMAP or game.CleanUpMap
	local keep_classes = {
		"light_environment","env_fog_controller","shadow_control","env_tonemap_controller",
		"env_wind","env_skypaint","sf_soundscape"
	}
	function game.CleanUpMap( dontSendToClients, ExtraFilters )
		-- Build a new list. Other addons might reuse (or share) the table they gave us.
		local filters = table.Copy(keep_classes)
		if istable(ExtraFilters) then
			table.Add(filters,ExtraFilters)
		end
		timer.Simple(0,function() hook.Run("StormFox.PostEntity") end)
		return STORMFOX_CLEANUPMAP(dontSendToClients,filters)
	end
