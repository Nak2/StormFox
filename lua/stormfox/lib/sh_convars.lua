--[[-------------------------------------------------------------------------
	Convars
		Creates the table: StormFox.convars
---------------------------------------------------------------------------]]

StormFox.convars = {}
	local function AddConVar(str,default,helptext)
		StormFox.convars[str] = true
		if ConVarExists(str) then return end
		-- FCVAR_REPLICATED is not 100% accurate for some reason
		CreateConVar(str,default, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, helptext)
		cvars.AddChangeCallback(str, function(convar_name, value_old, value_new)
			StormFox.SetNetworkData("con_" .. convar_name, value_new)
			--print("StormFox update " .. str)
		end,"SF_Netupdate-" .. str )
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
	AddConVar("sf_foliagesway",1,"sf_description.foliagesway")																		-- Enable foliagesway.
	AddConVar("sf_overridefoliagesway",1,"sf_description.overridefoliagesway") 														-- Override the foliagesway from a default list. ( Require reload )
	AddConVar("sf_overridemapsounds",1,"sf_description.override_soundscape")														-- Override the soundscape. ( Require reload )
	AddConVar("sf_addmapsounds",0,"sf_description.add_soundscape")
	local enable = engine.ActiveGamemode() == "sandbox"
	if enable and game.IsDedicated() then enable = false end
	AddConVar("sf_enable_ekstra_entsupport",enable and 1 or 0,"sf_description.sf_enable_ekstra_entsupport")

	--	AddConVar("sf_disable_autoweather_cold",0,"Disable autoweather creating snow.")
	--	AddConVar("sf_sv_material_replacment",1,"Enable material-replacment for weather effects.")
	--	AddConVar("sf_replacment_dirtgrassonly",0,"Only replace dirt and grass. (Useful on crazy maps)")
	if not CLIENT then return end
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

	CreateClientConVar("sf_language_override","",true,false,"sf_description.override_language")