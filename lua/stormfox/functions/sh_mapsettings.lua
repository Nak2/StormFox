local mapSettings = {}
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
			mapSettings = util.JSONToTable(sqlData) or {}
		end
		local function saveMapdata()
			local json = util.TableToJSON(mapSettings)
			if not json or #json < 1 then return end
			sql.Query( "REPLACE INTO sf_mapsettings (map,mapdata) VALUES (" .. SQLStr(game.GetMap()) .. "," .. SQLStr(json) .. ")" )
		end
	-- Interactions
		local function sendMapSettings(ply)
			net.Start("sf_mapsettings")
				net.WriteTable(mapSettings)
			net.Send(ply)
		end
		net.Receive("sf_mapsettings",function(len,ply)
			if true then return end
			local msg = net.ReadString()
			if msg == "open" then
				sendMapSettings(ply)
			elseif msg == "set" then
				local key = net.ReadString()
				local var = net.ReadType()
				mapSettings[key] = var
				print(ply,"setting mapdata",key,var)
				saveMapdata()
			end
		end)
	-- Mapdata
		mapSettings["mintemp"] = -10
		mapSettings["maxtemp"] = 20

		loadMapdata()
else
	local clamp,abs = math.Clamp,math.abs
	local function getTemp(n)
		return n .. "C/" .. math.Round(n * (9 / 5) + 32,1) .. "F"
	end
	local function RequestSetting(key,var)
		if mapSettings[key] and mapSettings[key] == var then
			return
		end
		mapSettings[key] = var
		net.Start("sf_mapsettings")
			net.WriteString("set")
			net.WriteString(key)
			net.WriteType(var)
		net.SendToServer()
	end
	local function openMapSettings()
		if STORMFOX_MSPANEL then
			STORMFOX_MSPANEL:Remove()
		end
		local panel = StormFox.vguiCreate("Frame")
			panel:SetTitle("SF settings for: " .. game.GetMap())
			panel:MakePopup()
			local w,h = 320,400
			panel:SetSize(w,h)
			panel:Center()
		local text = vgui.Create("DLabel",panel)
			text:SetText("Auto-weather generator")
			text:SetFont("SkyFox-Console")
			text:SetSize(200,20)
			text:SetContentAlignment(5)
			text:SetPos(w / 2 - 100,30)
		-- temperature
			local text = vgui.Create("DLabel",panel)
				text:SetText("Temperature range")
				text:SetFont("SkyFox-Console_Medium")
				text:SetSize(200,20)
				text:SetContentAlignment(5)
				text:SetPos(w / 2 - 100,50)
			local tempsetting = StormFox.vguiCreate("TwoSlider",panel)
			tempsetting:SetPos(w / 2 - 150,78)
			tempsetting:SetSize(300,15)
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
		-- mapsounds
			local text = vgui.Create("DLabel",panel)
				text:SetText("Map sounds")
				text:SetFont("SkyFox-Console_Medium")
				text:SetSize(200,20)
				text:SetContentAlignment(5)
				text:SetPos(w / 2 - 100,110)
			local bird = StormFox.vguiCreate("SmallButton",panel)
				bird:SetText("Birds")
				bird:SetSize(50,18)
				bird:SetPos(w / 2 - 55,130)
				bird:SetDown(mapSettings["bird"])
			function bird:OnClick()
				RequestSetting("bird",not mapSettings["bird"])
				self:SetDown(mapSettings["bird"])
			end
			local crickets = StormFox.vguiCreate("SmallButton",panel)
				crickets:SetText("Crickets")
				crickets:SetSize(50,18)
				crickets:SetPos(w / 2 + 5,130)
				crickets:SetDown(mapSettings["crickets"])
			function crickets:OnClick()
				RequestSetting("crickets",not mapSettings["crickets"])
				self:SetDown(mapSettings["crickets"])
			end

		STORMFOX_MSPANEL = panel
	end
	net.Receive("sf_mapsettings",function()
		mapSettings = net.ReadTable()
		openMapSettings(mapSettings)
	end)

	function StormFox.MapSettings()
		net.Start("sf_mapsettings")
			net.WriteString("open")
		net.SendToServer()
	end
	--StormFox.MapSettings()
end