StormFox = {}
StormFox.Version = 1.5
StormFox.WorkShopVersion = true--game.IsDedicated()

function StormFox.Msg(...)
	local a = {...}
	if StormFox.LanguageTranslate then
		for id,var in pairs(a) do
			if type(var) ~= "string" then continue end
			a[id] = StormFox.LanguageTranslate(var) or var
		end
	end
	MsgC(Color(155,155,255),"[StormFox] ",Color(255,255,255),unpack( a ),"\n")
end
StormFox.Msg("V " .. StormFox.Version .. ".")

if SERVER then
	file.CreateDir("stormfox")
	file.CreateDir("stormfox/maps")
	AddCSLuaFile("stormfox/sh_settings.lua")
end

-- Skypaint creation fix.
	local con = GetConVar("sf_skybox")
	if not con or con:GetBool() then
		RunConsoleCommand("sv_skyname", "painted")
	end
-- Reload support
	hook.Add("InitPostEntity","StormFox - CallPostEntitiy",function()
		_STORMFOX_POSTENTIY = true
		hook.Run("StormFox - PostEntity")
	end)
	if _STORMFOX_POSTENTIY then
		timer.Simple(1,function()
			hook.Run("StormFox - PostEntity")
		end)
	end
-- Load language
	-- Local & load functions
		local lang = {}
		local char = "[^%z]"
		local function ReadLine(str)
			-- Check for #
				if string.match(str,"^%s-#") then return end
			-- Match
				local a,b = string.match(str,"(" .. char .. "+)=(" .. char .. "+)")
				if not a or not b then return end -- Not a valid line
			-- Trim left
				a = a:gsub("^[%s	]+","")
				b = b:gsub("^[%s	]+","")
			-- Trim right
				a = a:gsub("[%s	]+$","")
				b = b:gsub("[%s	]+$","")
			lang[a] = b
		end
		local function LoadLangauge( str_langauge )
			-- Empty the table
				table.Empty(lang)
			-- Load the english language
				for k,v in pairs( string.Explode("\n",file.Read( "stormfox/language/en.lua","LUA" )) ) do
					if string.match(v,"::END::") then break end
					ReadLine(v)
				end
				if str_langauge == "en" then return end -- Already english
			-- Override the language table
				local c_lang = "stormfox/language/" .. str_langauge .. ".lua"
				-- That language don't excist
					if not file.Exists(c_lang,"LUA") then print("UNKNOWN") return end
				-- Load
					for k,v in pairs( string.Explode("\n",file.Read( c_lang,"LUA" )) ) do
						if string.match(v,"::END::") then break end
						ReadLine(v)
					end
		end
	-- Locate language
		local con = GetConVar( "gmod_language" )
		LoadLangauge(con:GetString() or "en")
	-- Create callback on language change
		cvars.RemoveChangeCallback("gmod_language","StormFox_languagechange")
		cvars.AddChangeCallback( "gmod_language", function( convar_name, value_old, value_new )
			LoadLangauge(value_new)
		end,"StormFox_languagechange")

	function StormFox.LanguageFormat(str,...)
		return string.format(lang[str] or str, ... )
	end
	--local missing = {}
	function StormFox.LanguageTranslate(str)
		--if not lang[str] then table.insert(missing,str) end
		return lang[str] or str
	end
		--
-- Add configs
	StormFox.convars = {}
	local function AddConVar(str,default,helptext)
		StormFox.convars[str] = true
		if ConVarExists(str) then return end
		CreateConVar(str,default, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, helptext)
		-- FCVAR_REPLICATED is not 100% accurate for some reason
	end
	AddConVar("sf_autopilot", game.SinglePlayer() and 1 or 0,"sf_description.autopilot")
	AddConVar("sf_timespeed",60,"sf_description.timespeed")
	AddConVar("sf_moonscale",6,"sf_description.moonscale")
	AddConVar("sf_moonphase",1,"sf_description.moonphase")
	AddConVar("sf_enablefog",1,"sf_description.enablefog")
	AddConVar("sf_weatherdebuffs",game.IsDedicated() and 0 or 1,"sf_description.weatherdebuffs")
	AddConVar("sf_windpush",0,"sf_description.windpush")
	AddConVar("sf_lightningbolts",1,"sf_description.lightningbolts")
	AddConVar("sf_enable_mapsupport",1,"sf_description.enable_mapsupport")
	AddConVar("sf_sunmoon_yaw",270,"sf_description.sunmoon_yaw")
	AddConVar("sf_debugcompatibility",0,"sf_description.debugcompatibility")
	AddConVar("sf_skybox",1,"sf_description.skybox")
	AddConVar("sf_enable_ekstra_lightsupport",0,"sf_description.enable_ekstra_lightsupport")
	AddConVar("sf_start_time","","sf_description.start_time")
	AddConVar("sf_mapbloom",0,"sf_description.mapbloom")
	AddConVar("sf_enable_mapbrowser",game.IsDedicated() and 0 or 1,"sf_description.enable_mapbrowser")
	AddConVar("sf_allowcl_disableeffects",engine.ActiveGamemode() == "sandbox" and 1 or 0,"sf_description.allowcl_disableeffects")
	AddConVar("sf_autoweather",1,"sf_description.autoweather")
	AddConVar("sf_block_lightenvdelete",1,"sf_description.block_lightenvdelete")
	AddConVar("sf_realtime",0,"sf_description.realtime")
	AddConVar("sf_foliagesway",1,"sf_description.foliagesway")
	AddConVar("sf_disableambient_sounds",0,"sf_description.disableambient_sounds")
	local enable = engine.ActiveGamemode() == "sandbox"
	if enable and game.IsDedicated() then enable = false end
	AddConVar("sf_enable_ekstra_entsupport",enable and 1 or 0,"sf_description.sf_enable_ekstra_entsupport")

	--	AddConVar("sf_disable_autoweather_cold",0,"Disable autoweather creating snow.")
	--	AddConVar("sf_sv_material_replacment",1,"Enable material-replacment for weather effects.")
	--	AddConVar("sf_replacment_dirtgrassonly",0,"Only replace dirt and grass. (Useful on crazy maps)")
	if CLIENT then
		CreateClientConVar("sf_disableeffects","0",true,false,"sf_description.disableeffects")
		CreateClientConVar("sf_exspensive","0",true,false,"sf_description.exspensive")
		CreateClientConVar("sf_material_replacment","1",true,false,"sf_description.material_replacment")
		CreateClientConVar("sf_allow_rainsound","1",true,false,"sf_description.allow_rainsound")
		CreateClientConVar("sf_allow_windsound","1",true,false,"sf_description.allow_windsound")
		CreateClientConVar("sf_allow_dynamiclights","1",true,false,"sf_description.allow_dynamiclights")
		CreateClientConVar("sf_allow_sunbeams","1",true,false,"sf_description.allow_sunbeams")
		CreateClientConVar("sf_allow_dynamicshadow","0",true,false,"sf_description.allow_dynamicshadow")
		CreateClientConVar("sf_dynamiclightamount","0",true,false,"sf_description.dynamiclightamount")
		CreateClientConVar("sf_redownloadlightmaps","1",true,false,"sf_description.redownloadlightmaps")
		CreateClientConVar("sf_allow_raindrops","0",true,false,"sf_description.allow_raindrops")
		CreateClientConVar("sf_renderscreenspace_effects","1",true,false,"sf_description.renderscreenspace_effects")
		CreateClientConVar("sf_useAInode","1",true,false,"sf_description.useAInode")
		CreateClientConVar("sf_enable_breath","1",true,false,"sf_description.enable_breath")
		CreateClientConVar("sf_enable_windoweffect","1",true,false,"sf_description.enable_windoweffect")
		CreateClientConVar("sf_enable_windoweffect_enable_tr","1",true,false,"sf_description.enable_windoweffect_enable_tr")

		CreateClientConVar("sf_rainpuddle_enable","1",true,false,"sf_description.rainpuddle_enable")
		CreateClientConVar("sf_footsteps_enable","1",true,false,"sf_description.footsteps_enable")
		CreateClientConVar("sf_footsteps_max","200",true,false,"sf_description.footsteps_max")
		CreateClientConVar("sf_footsteps_distance","1400",true,false,"sf_description.footsteps_distance")
	end
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
					if fdir != ".svn" then
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

			StormFox.Msg(StormFox.LanguageFormat("sf_added_content",i))
		end
	end

-- Launch Stormfox
	-- Add the language files to download
		for _,fil in ipairs(file.Find("stormfox/language/*.lua","LUA")) do
			if SERVER then
				AddCSLuaFile("stormfox/language/" .. fil)
			end
		end
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

		if SERVER then
			HandleFile("stormfox/" .. "sv_map_lights.lua")
			HandleFile("stormfox/" .. "sv_weather_generator.lua")
		end
		for _,fil in ipairs(file.Find("stormfox/weather_types/*.lua","LUA")) do
			if SERVER then
				AddCSLuaFile("stormfox/weather_types/" .. fil)
			end
			include("stormfox/weather_types/" .. fil)
		end
		HandleFile("stormfox/" .. "sh_options.lua")
		HandleFile("stormfox/" .. "cl_wizard.lua")
		HandleFile("stormfox/" .. "cl_mapbrowser.lua")
	hook.Call("StormFox - PostInit")
-- Check version
	if CLIENT then
		local function ReportVersion(version)
			if StormFox.Version < version then
				chat.AddText(Color(155,155,255),"[StormFox]",Color(255,255,255),": You're running an older version of StormFox.")
				chat.AddText(Color(155,155,255),"[StormFox]",Color(255,255,255),": " .. StormFox.Version .. " < " .. version)
			end
		end
		hook.Add("StormFox - NetDataChange","VersionCheck",function(str,var)
			if str ~= "workshopVersion" then return end
			ReportVersion(var)
		end)
		local workshopVersion = StormFox.GetNetworkData("workshopVersion")
		if workshopVersion then
			ReportVersion(workshopVersion)
		end
		return
	end

	local function onSuccess(body)
		local workshopVersion = tonumber(body:match('Version ([%d%.]+)%s') or "") or StormFox.Version
		StormFox.SetNetworkData("workshopVersion",workshopVersion or StormFox.Version)
		if workshopVersion > StormFox.Version then
			StormFox.Msg(Color(255,0,0), StormFox.LanguageFormat(sf_running_old.console,workshopVersion))
			StormFox.Msg(StormFox.LanguageFormat("sf_running_version",StormFox.Version))
		elseif workshopVersion < StormFox.Version then
			StormFox.Msg("sf_running_new")
		else
			StormFox.Msg("sf_running_current")
		end
	end
	http.Fetch("http://steamcommunity.com/sharedfiles/filedetails/?id=1132466603",onSuccess,function() StormFox.SetNetworkData("workshopVersion",StormFox.Version) end)

	hook.Add("PostGamemodeLoaded","StormFox.GM",function()
		local GM = GM or GAMEMODE
		if GM.StormFox then
			local mapsettings = GM.StormFox()
			if not mapsettings then return end
			StormFox.SetMapSettings(mapsettings)
		end
	end)

-- Sandbox load support
	-- Hack to stop cleanupmap breaking SF
		STORMFOX_CLEANUPMAP = STORMFOX_CLEANUPMAP or game.CleanUpMap
		function game.CleanUpMap( dontSendToClients, ExtraFilters )
			ExtraFilters = ExtraFilters or {}
			table.insert(ExtraFilters,"light_environment")
			table.insert(ExtraFilters,"env_fog_controller")
			table.insert(ExtraFilters,"shadow_control")
			table.insert(ExtraFilters,"env_tonemap_controller")
			table.insert(ExtraFilters,"env_wind")
			table.insert(ExtraFilters,"env_skypaint")
			STORMFOX_CLEANUPMAP(dontSendToClients,ExtraFilters)
		end
	-- Rescan a map when loaded from a save
		hook.Add("LoadGModSave","StormFox - SandboxLoadSupport",function()
			hook.Call( "StormFox - PostEntity" )
		end)