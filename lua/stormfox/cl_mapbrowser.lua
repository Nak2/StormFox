
-- List of map categories 
local MapPatterns = {}
local MapNames = {}
	MapNames[ "aoc_" ] = "Age of Chivalry"

	MapPatterns[ "^asi-" ] = "Alien Swarm"
	MapNames[ "lobby" ] = "Alien Swarm"

	MapNames[ "cp_docks" ] = "Blade Symphony"
	MapNames[ "cp_parkour" ] = "Blade Symphony"
	MapNames[ "cp_sequence" ] = "Blade Symphony"
	MapNames[ "cp_terrace" ] = "Blade Symphony"
	MapNames[ "cp_test" ] = "Blade Symphony"
	MapNames[ "duel_" ] = "Blade Symphony"
	MapNames[ "ffa_community" ] = "Blade Symphony"
	MapNames[ "free_" ] = "Blade Symphony"
	MapNames[ "practice_box" ] = "Blade Symphony"
	MapNames[ "tut_training" ] = "Blade Symphony"

	MapNames[ "ar_" ] = "Counter-Strike"
	MapNames[ "cs_" ] = "Counter-Strike"
	MapNames[ "de_" ] = "Counter-Strike"
	MapNames[ "es_" ] = "Counter-Strike"
	MapNames[ "fy_" ] = "Counter-Strike"
	MapNames[ "gd_" ] = "Counter-Strike"
	MapNames[ "training1" ] = "Counter-Strike"

	MapNames[ "dod_" ] = "Day Of Defeat"

	MapNames[ "ddd_" ] = "Dino D-Day"

	MapNames[ "de_dam" ] = "DIPRIP"
	MapNames[ "dm_city" ] = "DIPRIP"
	MapNames[ "dm_refinery" ] = "DIPRIP"
	MapNames[ "dm_supermarket" ] = "DIPRIP"
	MapNames[ "dm_village" ] = "DIPRIP"
	MapNames[ "ur_city" ] = "DIPRIP"
	MapNames[ "ur_refinery" ] = "DIPRIP"
	MapNames[ "ur_supermarket" ] = "DIPRIP"
	MapNames[ "ur_village" ] = "DIPRIP"

	MapNames[ "dys_" ] = "Dystopia"
	MapNames[ "pb_dojo" ] = "Dystopia"
	MapNames[ "pb_rooftop" ] = "Dystopia"
	MapNames[ "pb_round" ] = "Dystopia"
	MapNames[ "pb_urbandome" ] = "Dystopia"
	MapNames[ "sav_dojo6" ] = "Dystopia"
	MapNames[ "varena" ] = "Dystopia"

	MapNames[ "d1_" ] = "Half-Life 2"
	MapNames[ "d2_" ] = "Half-Life 2"
	MapNames[ "d3_" ] = "Half-Life 2"

	MapNames[ "dm_" ] = "Half-Life 2: Deathmatch"
	MapNames[ "halls3" ] = "Half-Life 2: Deathmatch"

	MapNames[ "ep1_" ] = "Half-Life 2: Episode 1"
	MapNames[ "ep2_" ] = "Half-Life 2: Episode 2"
	MapNames[ "ep3_" ] = "Half-Life 2: Episode 3"

	MapNames[ "d2_lostcoast" ] = "Half-Life 2: Lost Coast"

	MapPatterns[ "^c[%d]a" ] = "Half-Life"
	MapPatterns[ "^t0a" ] = "Half-Life"

	MapNames[ "boot_camp" ] = "Half-Life Deathmatch"
	MapNames[ "bounce" ] = "Half-Life Deathmatch"
	MapNames[ "crossfire" ] = "Half-Life Deathmatch"
	MapNames[ "datacore" ] = "Half-Life Deathmatch"
	MapNames[ "frenzy" ] = "Half-Life Deathmatch"
	MapNames[ "lambda_bunker" ] = "Half-Life Deathmatch"
	MapNames[ "rapidcore" ] = "Half-Life Deathmatch"
	MapNames[ "snarkpit" ] = "Half-Life Deathmatch"
	MapNames[ "stalkyard" ] = "Half-Life Deathmatch"
	MapNames[ "subtransit" ] = "Half-Life Deathmatch"
	MapNames[ "undertow" ] = "Half-Life Deathmatch"

	MapNames[ "ins_" ] = "Insurgency"

	MapNames[ "l4d_" ] = "Left 4 Dead"

	MapPatterns[ "^c[%d]m" ] = "Left 4 Dead 2"
	MapPatterns[ "^c1[%d]m" ] = "Left 4 Dead 2"
	MapNames[ "curling_stadium" ] = "Left 4 Dead 2"
	MapNames[ "tutorial_standards" ] = "Left 4 Dead 2"
	MapNames[ "tutorial_standards_vs" ] = "Left 4 Dead 2"

	MapNames[ "clocktower" ] = "Nuclear Dawn"
	MapNames[ "coast" ] = "Nuclear Dawn"
	MapNames[ "downtown" ] = "Nuclear Dawn"
	MapNames[ "gate" ] = "Nuclear Dawn"
	MapNames[ "hydro" ] = "Nuclear Dawn"
	MapNames[ "metro" ] = "Nuclear Dawn"
	MapNames[ "metro_training" ] = "Nuclear Dawn"
	MapNames[ "oasis" ] = "Nuclear Dawn"
	MapNames[ "oilfield" ] = "Nuclear Dawn"
	MapNames[ "silo" ] = "Nuclear Dawn"
	MapNames[ "sk_metro" ] = "Nuclear Dawn"
	MapNames[ "training" ] = "Nuclear Dawn"

	MapNames[ "bt_" ] = "Pirates, Vikings, & Knights II"
	MapNames[ "lts_" ] = "Pirates, Vikings, & Knights II"
	MapNames[ "te_" ] = "Pirates, Vikings, & Knights II"
	MapNames[ "tw_" ] = "Pirates, Vikings, & Knights II"

	MapNames[ "escape_" ] = "Portal"
	MapNames[ "testchmb_" ] = "Portal"

	MapNames[ "e1912" ] = "Portal 2"
	MapPatterns[ "^mp_coop_" ] = "Portal 2"
	MapPatterns[ "^sp_a" ] = "Portal 2"

	MapNames[ "achievement_" ] = "Team Fortress 2"
	MapNames[ "arena_" ] = "Team Fortress 2"
	MapNames[ "cp_" ] = "Team Fortress 2"
	MapNames[ "ctf_" ] = "Team Fortress 2"
	MapNames[ "itemtest" ] = "Team Fortress 2"
	MapNames[ "koth_" ] = "Team Fortress 2"
	MapNames[ "mvm_" ] = "Team Fortress 2"
	MapNames[ "pl_" ] = "Team Fortress 2"
	MapNames[ "plr_" ] = "Team Fortress 2"
	MapNames[ "rd_" ] = "Team Fortress 2"
	MapNames[ "pd_" ] = "Team Fortress 2"
	MapNames[ "sd_" ] = "Team Fortress 2"
	MapNames[ "tc_" ] = "Team Fortress 2"
	MapNames[ "tr_" ] = "Team Fortress 2"
	MapNames[ "trade_" ] = "Team Fortress 2"
	MapNames[ "pass_" ] = "Team Fortress 2"

	MapNames[ "zpa_" ] = "Zombie Panic! Source"
	MapNames[ "zpl_" ] = "Zombie Panic! Source"
	MapNames[ "zpo_" ] = "Zombie Panic! Source"
	MapNames[ "zps_" ] = "Zombie Panic! Source"

	MapNames[ "bhop_" ] = "Bunny Hop"
	MapNames[ "cinema_" ] = "Cinema"
	MapNames[ "theater_" ] = "Cinema"
	MapNames[ "xc_" ] = "Climb"
	MapNames[ "deathrun_" ] = "Deathrun"
	MapNames[ "dr_" ] = "Deathrun"
	MapNames[ "fm_" ] = "Flood"
	MapNames[ "gmt_" ] = "GMod Tower"
	MapNames[ "gg_" ] = "Gun Game"
	MapNames[ "scoutzknivez" ] = "Gun Game"
	MapNames[ "ba_" ] = "Jailbreak"
	MapNames[ "jail_" ] = "Jailbreak"
	MapNames[ "jb_" ] = "Jailbreak"
	MapNames[ "mg_" ] = "Minigames"
	MapNames[ "pw_" ] = "Pirate Ship Wars"
	MapNames[ "ph_" ] = "Prop Hunt"
	MapNames[ "rp_" ] = "Roleplay"
	MapNames[ "slb_" ] = "Sled Build"
	MapNames[ "sb_" ] = "Spacebuild"
	MapNames[ "slender_" ] = "Stop it Slender"
	MapNames[ "gms_" ] = "Stranded"
	MapNames[ "surf_" ] = "Surf"
	MapNames[ "ts_" ] = "The Stalker"
	MapNames[ "zm_" ] = "Zombie Survival"
	MapNames[ "zombiesurvival_" ] = "Zombie Survival"
	MapNames[ "zs_" ] = "Zombie Survival"
	local GamemodeList = engine.GetGamemodes()
	for k, gm in ipairs( GamemodeList ) do
		local Name = gm.title or "Unnammed Gamemode"
		local Maps = string.Split( gm.maps, "|" )
		if ( Maps && gm.maps != "" ) then

			for k, pattern in ipairs( Maps ) do
				-- When in doubt, just try to match it with string.find
				MapPatterns[ string.lower( pattern ) ] = Name
			end
		end
	end
local IgnorePatterns = {
	"^background",
	"^devtest",
	"^ep1_background",
	"^ep2_background",
	"^styleguide",
}
local IgnoreMaps = {
	-- Prefixes
	[ "sdk_" ] = true,
	[ "test_" ] = true,
	[ "vst_" ] = true,

	-- Maps
	[ "c4a1y" ] = true,
	[ "credits" ] = true,
	[ "d2_coast_02" ] = true,
	[ "d3_c17_02_camera" ] = true,
	[ "ep1_citadel_00_demo" ] = true,
	[ "intro" ] = true,
	[ "test" ] = true
}

-- Setup SQL functions
	if not sql.TableExists( "sf_mapinfo" ) then
		sql.Query( "CREATE TABLE IF NOT EXISTS sf_mapinfo( map TEXT NOT NULL PRIMARY KEY, mapdata TEXT );" )
	end

	local loadedData = {}
	local function LoadMapdata(str)
		if loadedData[str] then
			return loadedData[str]
		end
		if not sql.TableExists( "sf_mapinfo" ) then return end
		local sqlData = sql.QueryValue( "SELECT mapdata FROM sf_mapinfo WHERE map = " .. SQLStr(str)) or ""
		local mapData = util.JSONToTable(sqlData) or {}
		loadedData[str] = mapData or {}
		return loadedData[str]
	end
	local function SaveUpdateMapData(data)
		local json = util.TableToJSON(data)
		if not json or #json < 1 then return end
		sql.Query( "REPLACE INTO sf_mapinfo (map,mapdata) VALUES (" .. SQLStr(game.GetMap()) .. "," .. SQLStr(json) .. ")" )
	end
-- Load SF data
	local colors = {}
	colors[1] = Color(241,223,221,255)
	colors[2] = Color(78,85,93,255)
	colors[3] = Color(51,56,60)
	colors[4] = Color(47,50,55)

	local t = {}
		t["light_environment"] = "Enables smooth light-controls and doesn't require extra light support to make the map dark."
		t["env_tonemap_controller"] = "Enables light-bloom/tonemap effects."
		t["env_fog_controller"] = "Allows to control and edit fog."
		t["shadow_control"] = "Allows to control shadows."
		t[".ain nodes"] = "Allows special map-effects."
	local bonus_t = {}
		bonus_t["trigger"] = "This map have extra light-effects and triggers."

	local function GetMapData()
		local t_l = table.GetKeys(t)
		local data = {}
		local n,totaln = 0,1
		for i,str in ipairs(t_l) do
			totaln = totaln + 1
			data[str] = StormFox.GetNetworkData("has_" .. str)
			if data[str] then
				n = n + 1
			end
		end
		if StormFox.AIAinIsValid() then
			n = n + 1
		end
		data["3D Skybox"] = StormFox.Is3DSkybox()
		if StormFox.Is3DSkybox() then
			n = n + 1
		end
		data["percent_support"] = n / totaln
		local n = 0
		for str,_ in pairs(bonus_t) do
			if StormFox.GetNetworkData("has_" .. str) then
				n = n + 1
			end
		end
		data[".ain nodes"] = StormFox.AIAinIsValid()
		data["bonus"] = n
		return data
	end
	hook.Add("StormFox - NetDataChange","StormFox - SaveMapdata",function()
		-- We got new data
		timer.Simple(6,function()
			local t = GetMapData()
			if t.percent_support > 0 then
				SaveUpdateMapData(t)
			end
		end)
		hook.Remove("StormFox - NetDataChange","StormFox - SaveMapdata")
	end)

-- The browser itself
	local map_list
	-- A copycat from Gmod github .. but there aren't any functions to get the list outside the menu :\
	local function CreateMaplist()
		map_list = {}
		for _,map_name in ipairs(file.Find( "maps/*.bsp", "GAME" )) do
			local name = string.lower( string.gsub( map_name, "%.bsp$", "" ) )
			local prefix = string.match( name, "^(.-_)" )
			local Ignore = IgnoreMaps[ name ] or IgnoreMaps[ prefix ]
			for _, ignore in ipairs( IgnorePatterns ) do
				if ( string.find( name, ignore ) ) then
					Ignore = true
					break
				end
			end
			if ( Ignore ) then continue end
			local Category = MapNames[ name ] or MapNames[ prefix ]
			if ( not Category ) then
				for pattern, category in pairs( MapPatterns ) do
					if ( string.find( name, pattern ) ) then
						Category = category
					end
				end
			end
			Category = Category or "Other"
			if not map_list[Category] then
				map_list[Category] = {}
			end
			table.insert( map_list[ Category ], name )
			local csgo
			if ( Category == "Counter-Strike" ) then
				if ( file.Exists( "maps/" .. name .. ".bsp", "csgo" ) ) then
					if ( file.Exists( "maps/" .. name .. ".bsp", "cstrike" ) ) then -- Map also exists in CS:GO
						csgo = true
					else
						Category = "CS: Global Offensive"
					end
				end
			end
			if ( csgo ) then
				if ( not map_list[ "CS: Global Offensive" ] ) then
					map_list[ "CS: Global Offensive" ] = {}
				end
				-- We have to make the CS:GO name different from the CS:S name to prevent Favourites conflicts
				table.insert( map_list[ "CS: Global Offensive" ], name .. " " )
			end
		end
	end
	local mat = Material("gui/gradient")
	local cross = Material("debug/particleerror")
	local check = Material("vgui/hud/icon_check")
	local question = Material("vgui/avatar_default")
	local medal = Material("icon16/award_star_gold_1.png")
	local l = 12
	local function paintDetails(self,w,h)
		surface.SetDrawColor(colors[2])
		surface.SetDrawColor(Color(0,0,0,200))
		surface.SetMaterial(mat)
		surface.DrawRect(0,0,w,h)
		surface.DrawTexturedRectRotated(w - 10 ,h / 2,20,h,180)
		surface.DrawTexturedRectRotated(10 ,h / 2,20,h,0)
		if not self.mapdata.percent_support then
			draw.DrawText("Not scanned","mgui_default",w / 2,0,Color(255,255,255),1)
			return
		end
		draw.DrawText("Map Entities","mgui_default",w / 2,0,Color(255,255,255),1)
		local y = 0
		local i = 0
		local checkVersion = self
		surface.SetFont("mgui_default")
		for str,helptext in pairs(t) do
			i = i + 1
			local b = self.mapdata[str]
			surface.SetTextPos(18,i * l + 2)
			if b then
				surface.SetTextColor(0,255,0)
				surface.SetDrawColor(255,255,255)
				surface.SetMaterial(check)
			elseif b == false then
				surface.SetTextColor(255,255,255)
				surface.SetDrawColor(255,0,0)
				surface.SetMaterial(cross)
			else
				surface.SetTextColor(150,150,255)
				surface.SetDrawColor(150,150,255)
				surface.SetMaterial(question)
			end
			surface.DrawText(str)
			surface.DrawTexturedRect(5,i * l + 2,10,10)
			y = i * l + 2 + l
		end
		local b = self.mapdata["3D Skybox"]
			surface.SetTextPos(18,y)
			if b then
				surface.SetTextColor(0,255,0)
				surface.SetDrawColor(255,255,255)
				surface.SetMaterial(check)
			elseif b == false then
				surface.SetTextColor(255,255,255)
				surface.SetDrawColor(255,0,0)
				surface.SetMaterial(cross)
			else
				surface.SetTextColor(150,150,255)
				surface.SetDrawColor(150,150,255)
				surface.SetMaterial(question)
			end

		surface.DrawText("3D Skybox")
		surface.DrawTexturedRect(5,y,10,10)

		if (self.mapdata["bonus"] or 0) > 0 then
			surface.SetTextPos(18,y + 12)
			surface.SetTextColor(0,255,0)
			surface.SetDrawColor(255,255,255)
			surface.SetMaterial(medal)
			surface.DrawText("Map Triggers")
			surface.DrawTexturedRect(5,y + 12,10,10)
		end
	end

	local browserIcon_width,browserIcon_height = 96 * 1.3, 96 * 1.3
		local grad = Material("gui/gradient_up")
		local function Createcategory(panel,name)
			local DLabel = panel:Add( "DButton" )
			DLabel:SetText( name )
			DLabel:Dock( TOP )
			DLabel:DockMargin( 0, 0, 0, 0 )
			DLabel.top = panel
			DLabel.name = name
			function DLabel:Paint(w,h)
				if self:IsDown() then
					surface.SetDrawColor(colors[2])
				elseif self.top.on == self.name then
					surface.SetDrawColor(Color(190,190,190))
				else
					surface.SetDrawColor(colors[1])
				end
				surface.DrawRect(0,0,w,h)
				surface.SetDrawColor(Color(0,0,0,55))
				surface.DrawLine(0,h - 1,w,h - 1)
			end
			return DLabel
		end
		function StormFox.OpenMapBrowser()
			if STORMFOX_MBPANEL and IsValid(STORMFOX_MBPANEL) then
				STORMFOX_MBPANEL:Remove()
			end
			if not map_list then
				CreateMaplist()
			end

			local panel = mgui.Create("DFrame")
			local w,h = 160 + 10 + (browserIcon_width + 8) * 6,550
			panel:SetSize(w,h)
			panel:SetTitle("StormFox Map Browser")
			panel:Center()
			function panel.Paint(self,w,h)
				surface.SetDrawColor(colors[2])
				surface.DrawRect(0,0,w,h)
				surface.SetDrawColor(colors[4])
				surface.DrawRect(0,0,w,24)
			end

			local side_panel = mgui.Create("DPanel",panel)
			local category_list = mgui.Create("DScrollPanel",side_panel)
				panel.category_list = category_list
				category_list.on = nil
			side_panel:SetPos(0,24)
			side_panel:SetSize(160,h)
			-- Create maplist
				local d_map_list = mgui.Create("DScrollPanel",panel)
				d_map_list:SetPos(160,24)
				d_map_list:SetSize(w - 160,h - 24)

			local function PopulateLayout(panel,category)
				panel.VBar:SetScroll(0)
				if panel.map_table then
					panel.map_table:Remove()
				end
				if not map_list[category] then return end
				--panel:PerformLayout()
				local map_table = mgui.Create( "DIconLayout", d_map_list )
					map_table:Dock( FILL )
					map_table:SetBorder(5)
					map_table:SetSpaceX( 5 )
					map_table:SetSpaceY( 5 )
				panel.map_table = map_table
				-- List Logic and mapbuttons
				category_list.on = category
				map_table:SetSize(w - 160,200 + math.ceil(#map_list[category] / 4) * (browserIcon_height + 10) - 24)
				for _,map in ipairs(map_list[category]) do
					local btn = map_table:Add( "DImageButton" )
					btn:SetSize(browserIcon_width,browserIcon_height)
					btn:SetStretchToFit( true )
					btn.map = map
					btn.mapdata = LoadMapdata(map or "_unknown")
					btn.text_scroll = 0
					if file.Exists("maps/" .. map .. ".png","GAME") then
						btn:SetImage( "maps/" .. map .. ".png" )
					elseif not Material("maps/" .. map):IsError() then
						btn:SetImage( "maps/" .. map )
					else
						btn:SetImage("maps/noicon.png")
					end
					btn.outdate = false
					for str,helptext in pairs(t) do
						local b = btn.mapdata[str]
						if b == nil then
							btn.outdate = true
						end
					end 
					function btn:PaintOver(w,h)
						local p = self.mapdata.percent_support or 0
						local b = self.mapdata.bonus or 0
						if self:IsHovered() then
							paintDetails(self,w,h)
						end
						--local percent_support = mapdata.percent_support or 0
						surface.SetDrawColor(0,0,0,155)
						surface.DrawRect(0,h - 16,w,16)
						if self.mapdata.percent_support then
							surface.SetDrawColor(255,50,50,105)
							surface.DrawRect(w * p,h - 20,w * (1-p),4)
							if self.outdate then
								surface.SetDrawColor(155,155,255,255)
							else
								surface.SetDrawColor(0,255,0,255)
							end
							surface.DrawRect(0,h - 20,w * p,4)
						end
						for i = 1,b do
							surface.SetMaterial(medal)
							surface.SetDrawColor(255,255,255)
							surface.DrawTexturedRect( i * 8 - 8,i * 2 - 2,16,16)
						end
						surface.SetFont("default")
						local tw,tl = surface.GetTextSize(self.map or "Unknown")
						surface.SetTextColor(255,255,255)
						if tw < w then
							surface.SetTextPos(2,h - 8 - tl / 2)
							surface.DrawText(self.map or "Unknown")
						else
							if self:IsHovered() then
								self.text_scroll = self.text_scroll - RealFrameTime() * 30
								if self.text_scroll < -tw - 30 then
									self.text_scroll = 0
								end
								surface.SetTextPos(self.text_scroll,h - 8 - tl / 2)
								surface.DrawText(self.map or "Unknown")

								surface.SetTextPos(self.text_scroll + tw + 30,h - 8 - tl / 2)
								surface.DrawText(self.map or "Unknown")
							else
								self.text_scroll = 0
								surface.SetTextPos(2,h - 8 - tl / 2)
								surface.DrawText(self.map or "Unknown")
							end
						end
					end
					function btn:DoClick()
						LocalPlayer():EmitSound("garrysmod/content_downloaded.wav")
						RunConsoleCommand("sf_map_change",self.map)
					end
				end
				panel:SizeToContents()
				panel:SetSize(w - 160,h - 24)
			end
			PopulateLayout(d_map_list,cookie.GetString("StormFox - MapSelect","Sandbox"))
			-- Create category
					category_list:Dock( FILL )
				local ts = table.GetKeys(map_list)
				for i,v in ipairs(ts) do
					if v == "Sandbox" then
						table.remove(ts,i)
					end
				end
				for i,v in ipairs(ts) do
					if v == "Other" then
						table.remove(ts,i)
					end
				end
				table.sort( ts, function( a, b ) return a < b end )
				local btn = Createcategory(category_list,"Sandbox")
				function btn:DoClick()
					LocalPlayer():EmitSound("garrysmod/ui_click.wav")
					PopulateLayout(d_map_list,"Sandbox")
					cookie.Set("StormFox - MapSelect","Sandbox")
				end
				for i,category in ipairs(ts) do
					local btn = Createcategory(category_list,category)
					btn.category = category
					function btn:DoClick()
						LocalPlayer():EmitSound("garrysmod/ui_click.wav")
						PopulateLayout(d_map_list,self.category)
						cookie.Set("StormFox - MapSelect",self.category)
					end
				end
				local btn = Createcategory(category_list,"Other")
				function btn:DoClick()
					LocalPlayer():EmitSound("garrysmod/ui_click.wav")
					PopulateLayout(d_map_list,"Other")
					cookie.Set("StormFox - MapSelect","Other")
				end
			panel:MakePopup()
			STORMFOX_MBPANEL = panel
		end
	concommand.Add("sf_open_mapbrowser",StormFox.OpenMapBrowser)