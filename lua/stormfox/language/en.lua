return [[Stormfox English

#StormFox
	sf_description.newversion = You're running a beta version of SF
	sf_description.oldversion = You're running an old version of SF

#Tool
	sf_tool.menu 		= Menu
	sf_tool.maptexture 	= Map Texture
	sf_tool.maptexture.helpm1 = Press Mouse 1 to add material
	sf_tool.maptexture.helpm2 = Press Mouse 2 to remove material
	sf_tool.permaentity = Perma Entity
	sf_tool.addmaterial = Add
	sf_tool.cancel 		= Cancel
	sf_tool.menu_reload = Press R for menu

#Variables
	sf_type.roof 		= Roof
	sf_type.dirtgrass 	= Dirt/Grass
	sf_type.road 		= Road
	sf_type.pavement 	= Pavement

	# - Weather
		sf_weather.clear 		= Clear
		sf_weather.rain 		= Rain
		sf_weather.raining 		= Raining
		sf_weather.sleet 		= Sleet
		sf_weather.snowing 		= Snowing
		sf_weather.fog 			= Fog
		sf_weather.light_fog 	= Light Fog
		sf_weather.heavy_fog 	= Heavy Fog
		sf_weather.storm 		= Storm
		sf_weather.thunder 		= Thunder
		sf_weather.cloudy 		= Cloudy
		sf_weather.lava 		= Lava
		sf_weather.lava_eruption= Lava Eruption
		sf_weather.sandstorm 	= Sandstorm
		sf_weather.radioactive 	= Radioactive
		sf_weather.radioactive_rain= Radioactive Rain

	# - Wind
		sf_winddescription.calm 			= Calm
		sf_winddescription.light_air		= Light Air
		sf_winddescription.light_breeze		= Light Breeze
		sf_winddescription.gentle_breeze	= Gentle Breeze
		sf_winddescription.moderate_breeze	= Moderate Breeze
		sf_winddescription.fresh_breeze		= Fresh Breeze
		sf_winddescription.strong_breeze	= Strong Breeze
		sf_winddescription.near_gale		= Near Gale
		sf_winddescription.gale				= Gale
		sf_winddescription.strong_gale		= Strong Gale
		sf_winddescription.storm			= Storm
		sf_winddescription.violent_storm	= Violent Storm
		sf_winddescription.hurricane		= Hurricane
		sf_winddescription.cat2				= Category 2
		sf_winddescription.cat3				= Category 3
		sf_winddescription.cat4				= Category 4
		sf_winddescription.cat5				= Category 5

#Weather
	sf_current_weather = Current Weather

#Server Settings
	sf_description.autopilot		 = Try to fix all problems on launch.
	sf_description.timespeed		 = Seconds of gametime pr real second.
	sf_description.moonscale		 = Moon scale.
	sf_description.moonphase 		 = Enable moon-phases.
	sf_description.enablefog 		 = Allow SF editing the fog.
	sf_description.weatherdebuffs 	 = Enable weather debuffs/damage/impact.
	sf_description.windpush 		 = Enable wind-push on props.
	sf_description.lightningbolts 	 = Enable lightning strikes.
	sf_description.enable_mapsupport = Enable entity-support for maps.
	sf_description.sunmoon_yaw 	 	 = The sun/moon yaw.
	sf_description.debugcompatibility = Enable SF compatability-debugger.
	sf_description.skybox 			 = Enable SF-skybox.
	sf_description.enable_ekstra_lightsupport = Enable extra lightsupport (Lags on large maps)
	sf_description.start_time 		 = Start the server at a specific time.
	sf_description.mapbloom 		 = Allow SF editing light-bloom.
	sf_description.enable_mapbrowser = Allow admins changing the map with SF-browser.
	sf_description.allowcl_disableeffects = Allow clients to disable SF-effects.
	sf_description.autoweather 		 = Enable weather-generation.
	sf_description.realtime 		 = Follow the local time.
	sf_description.foliagesway 		 = Enable foliagesway.
	sf_description.override_soundscape = Override map-soundscape.
	sf_description.sf_enable_ekstra_entsupport = Update all entites on lightchange. (Taxing for servers)

#Client Settings
	sf_description.disableeffects 		= Disable all effects.
	sf_description.exspensive 			= [0-7+] Enable exspensive weather calculations.
	sf_description.exspensive_fps 		= Scale the quality setting with FPS.
	sf_description.exspensive_manually 	= Manually set the quality setting.
	sf_description.material_replacment 	= Enable material replacment for weather effects.
	sf_description.allow_rainsound 		= Enable rain-sounds.
	sf_description.allow_windsound 		= Enable wind-sounds.
	sf_description.allow_dynamiclights 	= Enable lamp-lights from SF.
	sf_description.allow_sunbeams 		= Enable sunbeams.
	sf_description.allow_dynamicshadow 	= Enable dynamic light/shadows.
	sf_description.dynamiclightamount 	= Controls the dynamic-light amount.
	sf_description.redownloadlightmaps 	= Update lightmaps (Can lag on large maps)
	sf_description.allow_raindrops 		= Enable raindrops on the screen
	sf_description.renderscreenspace_effects = Enable RenderScreenspaceEffects
	sf_description.useAInode 			= Use AI nodes for more reliable sounds and effects.
	sf_description.enable_breath 		= Enable cold breath-effect.
	sf_description.enable_windoweffect 	= Enable raindrops on breakable windows.
	sf_description.enable_windoweffect_enable_tr = Check if rain hits the breakable windows.
	sf_description.rainpuddle_enable 	= Spawn rainpuddles doing rain. (Need AI nodes)
	sf_description.footsteps_enable 	= Render footsteps in snow.
	sf_description.footsteps_max 		= Max footsteps.
	sf_description.footsteps_distance 	= Render distance for footsteps in snow.
	sf_description.hq_shadowmaterial 	= Set HQ shadow convars

#Map Settings
	sf_description.map_entities			 = Map entities
	sf_description.dynamiclight 		 = Allow dynamiclight for all clients.
	sf_description.replace_dirtgrassonly = Only replace grass/dirt.
	sf_description.wind_breakconstraints = Break constraints and unfreeze props in strong wind.

#StormFox msg
	sf_added_content 			= Added %i content files
	sf_permisson.deny 			= You don't have access to weather settings
	sf_permisson.denysettings 	= You don't have access to SF settings
	sf_permisson.denymap 		= You don't have access to change the map
	sf_permisson.denymapsetting = This server have disabled map-browser
	sf_permisson.denymapmissing = Server is missing the map
	sf_generating.puddles 		= Generated puddle positions
	sf_missinglanguage 			= Missing language-file:

#MapData
	sf_mapdata_load 	 = Loaded mapdata.
	sf_mapdata_invalid 	 = Invalid mapdata from server!
	sf_mapdata_cleanup 	 = Cleaning map-changes ...
	sf_ain_load 		 = Loaded .ain file

#Interface basics
	Settings 		 = Settings
	Server Settings  = Server Settings
	Client Settings  = Client Settings
	Controller 		 = Controller
	Troubleshooter 	 = Troubleshooter
	Reset 			 = Reset
	Weather Controller = Weather Controller
	Effects 		 = Effects
	Map Browser 	 = Map Browser
	Map 			 = Map
	Clients 		 = Clients
	Other 			 = Other
	Time 			 = Time
	Misc 			 = Misc
	Weather 		 = Weather
	Auto Weather 	 = Auto Weather
	Adv Light 		 = Adv Light
	Sun / Moon 		 = Sun / Moon
	Changelog 		 = Changelog
	Temperature 	 = Temperature
	Wind 			 = Wind
	Quality 		 = Quality
	Materials 		 = Materials
	Rain/Snow Effects= Rain/Snow Effects

#Interface adv	
	sf_troubleshooter.description 	= This will display the common problems with settings.
	sf_temperature_range 		 	= Temperature range
	sf_setwindangle 			 	= Set WindAngle
	sf_setweather 					= Set Weather
	sf_settime 						= Set Time
	sf_holdc 						= Hold C
	sf_interface_lighttheme 		= Light Theme
	sf_interface_darktheme 			= Dark Theme
	sf_interface_light 				= Light
	sf_interface_light_range 		= Light range: 
	sf_interface_save_on_exit 		= Save on exit
	sf_interface_adv_light 			= Adv light
	sf_interface_closechat 			= Close chat to interact
	sf_interface_closeconsole 		= Close console
	sf_interface_material_replacment= Material replacment
	sf_interface_max_wind 			= Max wind
	sf_interface_max_footprints 	= Max footprints
	sf_interface_footprint_render 	= Footprint render distance
	sf_interface_language 			= Language override

#Errors and warning
	sf_missing_convar 				= Missing Convar
	sf_warning_clientlag 			= Can lag on some clients!
	sf_warning_serverlag 			= Can cause major serverlag!
	sf_warning_reqmapchange 		= Requires mapchange
	sf_description.disabled_on_server = Disabled on this server
	sf_warning_unsupportmap 		= Required on unsupported maps
	sf_warning_missingmaterial.title = You're missing materials.
	sf_warning_missingmaterial.nevershow = Never show this again.
	sf_warning_missingmaterial 		= You're missing %i material(s).
	sf_warning_unfinished_a 		= This is not finished yet. Please use the Troubleshooter in server-settings
	sf_warning_unfinished_b 		= Open serverside Troubleshooter (Requires permission)
]]