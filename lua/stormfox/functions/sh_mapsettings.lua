local mapSettings = {}
local defaultSettings = {}
	defaultSettings["autoweather"] = true 			--
	defaultSettings["mintemp"] = -10 				--
	defaultSettings["maxtemp"] = 20					--
	defaultSettings["maxwind"] = 30					--
	defaultSettings["minlight"] = 2				--
	defaultSettings["maxlight"] = 80				--
	defaultSettings["dynamiclight"] = true 			--
	defaultSettings["material_replacment"] = true 		--
	defaultSettings["replace_dirtgrassonly"] = false 	--
	defaultSettings["override_sounds"] = false 			
	defaultSettings["sound_birds"] = false
	defaultSettings["sound_crickets"] = false
mapSettings = table.Copy(defaultSettings)
function StormFox.GetMapSetting(str,var)
	return mapSettings[str] or var
end

if SERVER then
	util.AddNetworkString("sf_mapsettings")
	-- SQL setup
		if not sql.TableExists( "sf_mapsettings" ) then
			print("[StormFox] Create SQL database.")
			sql.Query( "CREATE TABLE IF NOT EXISTS sf_mapsettings( map TEXT NOT NULL PRIMARY KEY, mapdata TEXT );" )
		end
		local function loadMapdata()
			if not sql.TableExists( "sf_mapsettings" ) then return end
			local sqlData = sql.QueryValue( "SELECT mapdata FROM sf_mapsettings WHERE map = " .. SQLStr(game.GetMap())) or ""
			for k,v in pairs(util.JSONToTable(sqlData) or defaultSettings) do
				mapSettings[k] = v
			end
		end
		local function saveMapdata()
			local json = util.TableToJSON(mapSettings)
			if not json or #json < 1 then return end
			sql.Query( "REPLACE INTO sf_mapsettings (map,mapdata) VALUES (" .. SQLStr(game.GetMap()) .. "," .. SQLStr(json) .. ")" )
		end
	-- Update
		local function UpdateSettings()
			StormFox.SetNetworkData("override_sounds",mapSettings["override_sounds"])
			StormFox.SetNetworkData("sound_birds",mapSettings["sound_birds"])
			StormFox.SetNetworkData("sound_crickets",mapSettings["sound_crickets"])
			StormFox.SetNetworkData("dynamiclight",mapSettings["dynamiclight"])
		end
	-- Interactions
		local function sendMapSettings(ply)
			net.Start("sf_mapsettings")
				net.WriteTable(mapSettings)
			net.Send(ply)
		end
		net.Receive("sf_mapsettings",function(len,ply)
			local msg = net.ReadString()
			if msg == "open" then
				StormFox.CanEditMapSetting(ply,sendMapSettings,ply)
			elseif msg == "set" then
				local key = net.ReadString()
				local var = net.ReadType()
				StormFox.CanEditMapSetting(ply,function()
					mapSettings[key] = var
					print(ply,"setting mapdata",key,var)
					saveMapdata()
					UpdateSettings()
				end)
			end
		end)
	-- Load mapdata
		loadMapdata()
		UpdateSettings()
else
	local clamp,abs,round = math.Clamp,math.abs,math.Round
	local function getTemp(n)
		return n .. "C/" .. math.Round(n * (9 / 5) + 32,1) .. "F"
	end
	local function RequestSetting(key,var)
		if mapSettings[key] and mapSettings[key] == var then
			return
		end
		if var == nil then var = false end
		mapSettings[key] = var
		net.Start("sf_mapsettings")
			net.WriteString("set")
			net.WriteString(key)
			net.WriteType(var)
		net.SendToServer()
	end
	local function charRound(n)
		return round(n / 4) * 4
	end
	local function openMapSettings()
		if STORMFOX_MSPANEL then
			STORMFOX_MSPANEL:Remove()
		end
		local panel = StormFox.vguiCreate("Frame")
			panel:SetTitle("SF settings for: " .. game.GetMap())
			panel:MakePopup()
			panel.btnMaxim:SetVisible( false )
			panel.btnMinim:SetVisible( false )
			local w,h = 220,340
			panel:SetSize(w,h)
			panel:Center()
		local function CreateToggle(str,setting,y)
			local text = vgui.Create("DLabel",panel)
				text:SetText(str)
				text:SetFont("SkyFox-Console")
				text:SizeToContents()
				text:SetPos(w - 50 - text:GetSize() - 10,y)
			local dynamiclight = StormFox.vguiCreate("Toggle",panel)
				dynamiclight:SetPos(w - 50 ,y - 2)
				dynamiclight:SetToggle(mapSettings[setting])
			return dynamiclight
		end
		-- Enable autoweather
			local con = GetConVar("sf_disable_autoweather")
			local text = vgui.Create("DLabel",panel)
				text:SetText("Auto-weather generator")
				text:SetFont("SkyFox-Console")
				text:SizeToContents()
				text:SetPos(w / 2 - text:GetSize() / 2 - 20,30)
			local aw_enable = StormFox.vguiCreate("Toggle",panel)
				aw_enable:SetPos(w / 2 + text:GetSize() / 2 - 16,28)
				aw_enable:SetToggle(mapSettings["autoweather"])
			function aw_enable:Think()
				local d = false
				if con and con:GetBool() then
					self:SetDisabled(true)
					d = true
				else
					self:SetDisabled(false)
				end
				if self:IsHovered() then
					local xx,yy = self:LocalToScreen(0,7 )
					StormFox.DisplayTip(xx,yy,d and "All weather is already disabled (sf_disable_autoweather 1)" or "Enable auto-weather for this map.",RealFrameTime())
				end
			end
		-- temperature
			local text = vgui.Create("DLabel",panel)
				text:SetText("Temperature range")
				text:SetFont("SkyFox-Console_Medium")
				text:SetSize(200,20)
				text:SetContentAlignment(5)
				text:SetPos(w / 2 - 100,50)
			local tempsetting = StormFox.vguiCreate("TwoSlider",panel)
			tempsetting:SetPos(10,78)
			tempsetting:SetSize(w - 20,15)
			tempsetting:SetVar(mapSettings["mintemp"] / 80 + 0.5)
			tempsetting:SetVar2(mapSettings["maxtemp"] / 80 + 0.5)
			local con = GetConVar("sf_disable_autoweather_cold")
			function tempsetting:PaintOver(w,h)
				if con and con:GetBool() then
					surface.SetTextColor(255,255,255,55)
					surface.SetTextPos(12,0)
					surface.DrawText("sf_disable_autoweather_cold")
					tempsetting:SetMin(4 / 80 + 0.5)
				else
					tempsetting:SetMin(0)
				end
				surface.DisableClipping(true)
					local first_text,second_text = getTemp(mapSettings["mintemp"]),getTemp(mapSettings["maxtemp"])
					surface.SetFont("SkyFox-Console_Small")
					if abs(self.first_pos - self.second_pos) < surface.GetTextSize(first_text .. " | " .. second_text) / 2 then
						-- Noo close
						local p = self.first_pos + (self.second_pos - self.first_pos) / 2
						draw.DrawText(first_text .. " | " .. second_text,"SkyFox-Console_Small",p,14,Color(241,223,221),1)
					else
						draw.DrawText(getTemp(mapSettings["mintemp"]),"SkyFox-Console_Small",self.first_pos,14,Color(241,223,221),1)
						draw.DrawText(getTemp(mapSettings["maxtemp"]),"SkyFox-Console_Small",self.second_pos,14,Color(241,223,221),1)
					end
				surface.DisableClipping(false)

				if not self:IsHovered() then return end
				surface.SetDrawColor(Color(241,223,221,255))
				local w = self:GetSize()
				local x = self:CursorPos()
				local percent = clamp((x - w * 0.05) / (w * 0.9),0,1) -- w * 0.9
				surface.DisableClipping(true)
					local p = w * 0.05 + w * 0.9 * percent
					local c = math.Round((percent - 0.5) * 80)
					local text = (self.selectedside == 1 and "Min" or self.selectedside == 2 and "Max" or "") .. " " .. c .. "C/" .. math.Round(c * (9 / 5) + 32) .. "F"
					surface.DrawLine(p,0,p, -10)
					surface.SetDrawColor(0,0,0,155)
					local tw,th = surface.GetTextSize(text)
					surface.DrawRect(p - 12, -22, tw + 4, th + 4)
					surface.SetTextPos(p - 10, - 22)
					surface.SetTextColor(241,223,221)
					surface.DrawText(text)
				surface.DisableClipping(false)
			end
			function tempsetting:OnChange(percent,n)
				local c = math.Round((percent - 0.5) * 80)
				if n == 1 then
					RequestSetting("mintemp",c)
				else
					RequestSetting("maxtemp",c)
				end
			end
			function tempsetting:Think()
				if self:IsHovered() then
					local xx,yy = self:LocalToScreen(0,7 )
					StormFox.DisplayTip(xx,yy,"The temperature range for auto-weather.",RealFrameTime())
				end
			end
		-- wind
			local text = vgui.Create("DLabel",panel)
				text:SetText("Max Wind")
				text:SetFont("SkyFox-Console_Medium")
				text:SetSize(200,140)
				text:SetContentAlignment(5)
				text:SetPos(w / 2 - 100,50)
			local windsetting = StormFox.vguiCreate("Slider",panel)
			windsetting:SetPos(10,128)
			windsetting:SetSize(w - 20,15)
			windsetting:SetVar(mapSettings["maxwind"] / 50)
			function windsetting:PaintOver(w,h)
				surface.DisableClipping(true)
					local text = mapSettings["maxwind"] .. "m/s" .. "/" .. math.Round(mapSettings["maxwind"] * 2.236936) .. "mph"
					draw.DrawText(text,"SkyFox-Console_Small",self.first_pos,14,Color(241,223,221),1)
				surface.DisableClipping(false)

				if not self:IsHovered() then return end
				surface.SetDrawColor(Color(241,223,221,255))
				local w = self:GetSize()
				local x = self:CursorPos()
				local percent = clamp((x - w * 0.05) / (w * 0.9),0,1) -- w * 0.9
				surface.DisableClipping(true)
					local p = w * 0.05 + w * 0.9 * percent
					local c = round(percent * 50,1)
					local text = c .. "m/s" .. "/" .. round(c * 2.236936,1) .. "mph"
					surface.DrawLine(p,0,p, -10)
					surface.SetDrawColor(0,0,0,155)
					local tw,th = surface.GetTextSize(text)
					surface.DrawRect(p - 12, -22, tw + 4, th + 4)
					surface.SetTextPos(p - 10, - 22)
					surface.SetTextColor(241,223,221)
					surface.DrawText(text)
				surface.DisableClipping(false)
			end
			function windsetting:Think()
				if self:IsHovered() then
					local xx,yy = self:LocalToScreen(0,7 )
					StormFox.DisplayTip(xx,yy,"The max wind-speed for auto-weather.",RealFrameTime())
				end
			end
			function windsetting:OnChange(percent,n)
				local w = round(percent * 50,1)
				RequestSetting("maxwind",w)
			end
		-- lightsettings
			local text = vgui.Create("DLabel",panel)
				text:SetText("Light range")
				text:SetFont("SkyFox-Console_Medium")
				text:SetSize(200,20)
				text:SetContentAlignment(5)
				text:SetPos(w / 2 - 100,158)
			local lightsetting = StormFox.vguiCreate("TwoSlider",panel)
			lightsetting:SetPos(10,184)
			lightsetting:SetSize(w - 20,15)
			lightsetting:SetVar(mapSettings["minlight"] / 100)
			lightsetting:SetVar2(mapSettings["maxlight"] / 100)
			function lightsetting:PaintOver(w,h)
				surface.DisableClipping(true)
					local first_text,second_text = "Night: " .. charRound(mapSettings["minlight"]) .. "%","Day: " .. charRound(mapSettings["maxlight"]) .. "%"
					if abs(self.first_pos - self.second_pos) < surface.GetTextSize(first_text .. " | " .. second_text) / 2 then
						-- Noo close
						local p = self.first_pos + (self.second_pos - self.first_pos) / 2
						draw.DrawText(first_text .. " | " .. second_text,"SkyFox-Console_Small",p,14,Color(241,223,221),1)
					else
						draw.DrawText(first_text,"SkyFox-Console_Small",self.first_pos,14,Color(241,223,221),1)
						draw.DrawText(second_text,"SkyFox-Console_Small",self.second_pos,14,Color(241,223,221),1)
					end
				surface.DisableClipping(false)

				if not self:IsHovered() then return end
				surface.SetDrawColor(Color(241,223,221,255))
				local w = self:GetSize()
				local x = self:CursorPos()
				local percent = clamp((x - w * 0.05) / (w * 0.9),0,1) -- w * 0.9
				surface.DisableClipping(true)
					local p = w * 0.05 + w * 0.9 * percent
					local c = math.Round(percent * 100)
					local text = charRound(c) .. "%"
					surface.DrawLine(p,0,p, -10)
					surface.SetDrawColor(0,0,0,155)
					local tw,th = surface.GetTextSize(text)
					surface.DrawRect(p - 12, -22, tw + 4, th + 4)
					surface.SetTextPos(p - 10, - 22)
					surface.SetTextColor(241,223,221)
					surface.DrawText(text)
				surface.DisableClipping(false)
			end
			function lightsetting:Think()
				if self:IsHovered() then
					local xx,yy = self:LocalToScreen(0,7 )
					StormFox.DisplayTip(xx,yy,"The light-procent for night and day.",RealFrameTime())
				end
			end
			function lightsetting:OnChange(percent,n)
				local c = math.Round(percent * 100)
				if n == 1 then
					RequestSetting("minlight",c)
				else
					RequestSetting("maxlight",c)
				end
			end
		-- Setup ag
			function aw_enable:OnClick(bool)
				--tempsetting:SetDisabled(not bool)
				windsetting:SetDisabled(not bool)
				RequestSetting("autoweather",bool)
			end
			if not mapSettings["autoweather"] then
				--tempsetting:SetDisabled(true)
				windsetting:SetDisabled(true)
			end
		-- dynamiclight
			local dyr_lig = CreateToggle("Allow dynamiclight","dynamiclight",220)
			function dyr_lig:OnClick(bool)
				RequestSetting("dynamiclight",bool)
			end
			function dyr_lig:Think()
				if self:IsHovered() then
					local xx,yy = self:LocalToScreen(0,7 )
					StormFox.DisplayTip(xx,yy,"Enable dynamiclight for all clients. Useful for when maps break due to small 2D skyboxes.",RealFrameTime())
				end
			end
		-- material_replacment
			local mat_rep = CreateToggle("Material Replacment","material_replacment",248)
			function mat_rep:Think()
				if self:IsHovered() then
					local xx,yy = self:LocalToScreen(0,7 )
					StormFox.DisplayTip(xx,yy,"Enable material replacment (snow) for this map.",RealFrameTime())
				end
			end
			-- replace_dirtgrassonly
				local gra_dirt = CreateToggle("Rep. Dirt-Grass only","replace_dirtgrassonly",276)
				function gra_dirt:OnClick(bool)
					RequestSetting("replace_dirtgrassonly",bool)
				end
				function gra_dirt:Think()
					if self:IsHovered() then
						local xx,yy = self:LocalToScreen(0,7 )
						StormFox.DisplayTip(xx,yy,"Only replace grass and dirt materials. (Useful for crazy maps.)",RealFrameTime())
					end
				end
			function mat_rep:OnClick(bool)
				gra_dirt:SetDisabled(not bool)
				RequestSetting("material_replacment",bool)
			end
			if not mapSettings["material_replacment"] then
				gra_dirt:SetDisabled(true)
			end
		-- override_sounds
			local map_sound = CreateToggle("Block map-ambient","override_sounds",304)
			function map_sound:OnClick(bool)
				RequestSetting("override_sounds",bool)
			end
			function map_sound:Think()
				if self:IsHovered() then
					local xx,yy = self:LocalToScreen(0,7 )
					StormFox.DisplayTip(xx,yy,"Block map-ambient sounds.",RealFrameTime())
				end
			end

		--[[ Todo ..
		-- Day/Night sounds
			local text = vgui.Create("DLabel",panel)
				text:SetText("Additional Map Sounds")
				text:SetFont("SkyFox-Console_Medium")
				text:SizeToContents()
				text:SetPos(w / 2 - text:GetSize() / 2,334)
			local bird = StormFox.vguiCreate("SmallButton",panel)
				bird:SetText("Birds")
				bird:SetSize(50,18)
				bird:SetPos(w / 2 - 55,354)
				bird:SetDown(mapSettings["bird"])
			function bird:OnClick()
				RequestSetting("bird",not mapSettings["bird"])
				self:SetDown(mapSettings["bird"])
			end
			local crickets = StormFox.vguiCreate("SmallButton",panel)
				crickets:SetText("Crickets")
				crickets:SetSize(50,18)
				crickets:SetPos(w / 2 + 5,354)
				crickets:SetDown(mapSettings["crickets"])
			function crickets:OnClick()
				RequestSetting("crickets",not mapSettings["crickets"])
				self:SetDown(mapSettings["crickets"])
			end]]
		STORMFOX_MSPANEL = panel
	end
	net.Receive("sf_mapsettings",function()
		mapSettings = net.ReadTable()
		openMapSettings()
	end)
	function StormFox.MapSettings()
		net.Start("sf_mapsettings")
			net.WriteString("open")
		net.SendToServer()
	end
end
-- Block mapsounds
hook.Add("EntityEmitSound","StormFox BlockSounds",function(data)
	if not StormFox.GetNetworkData("override_sounds") then return end
	if not data.Entity:IsWorld() then return end
	if data.OriginalSoundName:sub(0,8) == "ambient/" then
		return false
	end
end)