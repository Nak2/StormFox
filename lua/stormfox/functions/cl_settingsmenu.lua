--[[-------------------------------------------------------------------------
Server settings
Time
	sf_timespeed
	sf_start_time
	sf_realtime

Sun / Moon
	sf_sunmoon_yaw
	sf_moonscale
	sf_moonphase

Wind
	sf_windpush
	sf_foliagesway

Weather
	sf_autoweather
	sf_enablefog
	sf_weatherdebuffs
	sf_lightningbolts

Map
	

Misc
	sf_debugcompatibility
	sf_enable_mapbrowser
	sf_allowcl_disableeffects


	AddConVar("sf_realtime",0,"Follow the servers localtime. (This is not perfect)")
---------------------------------------------------------------------------]]


--[[-------------------------------------------------------------------------
	Client Settings
		StormFox Settings:
			- sf_disableeffects
			- sf_exspensive
		Light and Shadows
			- sf_allow_dynamicshadow
				- sf_dynamiclightamount
			- sf_redownloadlightmaps
			- sf_allow_sunbeams
			- sf_allow_entitylights
		Sound
			- sf_allow_rainsound
			- sf_allow_windsound
		Map
			- sf_material_replacment
			- sf_useAInode

---------------------------------------------------------------------------]]	
local cos,sin,rad = math.cos,math.sin,math.rad
local settingList = {}
local mapsettingList = {}
local function serverToggle(parent,setting)
	settingList[setting] = 1
	local p = mgui.Create("Switch",parent)
		p.setting = setting
	local l = mgui.Create("DLabel",parent)
	local c = GetConVar(setting)
		p:Toggle(c:GetInt() == 1)
	function p:DoClick()
		local b = self.state
		mgui.CallEvent(self.setting .. "_set",self.state)
		StormFox.SetConvarSetting(self.setting,self.state and "1" or "0")
	end
	if not c then
		l:SetText("Missing convar")
	else
		l:SetText(c:GetHelpText())
	end
		l:SizeToContentsX( 10 )
	return p,l
end
local function serverText(parent,setting,numberonly,canbeempty)
	settingList[setting] = 2
	local p = mgui.Create("TextBox",parent)
		p:SetNumeric(numberonly or false)
		p.setting = setting
		p.canbeempty = canbeempty or false
	local l = mgui.Create("DLabel",parent)
	local c = GetConVar(setting)
	if not c then
		p:SetValue(60)
		l:SetText("Missing convar")
	else
		if numberonly then
			p:SetValue(c:GetInt())
		else
			p:SetValue(c:GetString())
		end
		l:SetText(c:GetHelpText())
	end
	function p:OnEdit()
		if not self.canbeempty then
			if not self.value then
				self.value = c:GetDefault()
			end
			if string.len(self.value) <= 0 then
				self.value = c:GetDefault()
			end
		end
		mgui.CallEvent(self.setting .. "_set",self.value or c:GetDefault())
		StormFox.SetConvarSetting(self.setting,self.value or c:GetDefault())
	end
	l:SizeToContentsX( 4 )
	return p,l
end
local function makeTitle(parent,text)
	local p = mgui.Create("Panel",parent)
	p.text = text
	function p:Paint(w,h)
		surface.SetFont("mgui_default")
		local tc = self:GetTextColor()
		surface.SetTextColor(tc)
		local tw,th = surface.GetTextSize(self.text)
		surface.SetTextPos(20,0)
		surface.DrawText(self.text)
		surface.SetDrawColor(tc)
		surface.DrawLine(20,th + 1, w, th + 1)
	end
	return p
end
local m_circle = Material("vgui/circle")
local element_size = 24
local p_list = {}
local function setmapdata(key,var)
	net.Start("sf_mapsettings")
		net.WriteString("set")
		net.WriteString(key)
		net.WriteType(var)
	net.SendToServer()
end
local function serverMapToggle(parent,setting)
	local p = mgui.Create("Switch",parent)
		p.setting = setting
	mapsettingList[p.setting] = 1
	local c = StormFox.GetMapSetting(setting)
		p:Toggle(c)
	function p:DoClick()
		local b = self.state
		mgui.CallEvent(self.setting .. "_set",self.state)
		StormFox.SetMapSetting(self.setting,b)
	end
	return p
end
function StormFox.OpenServerSettings()
	if _STORMFOX_CLMENU then
		_STORMFOX_CLMENU:Remove()
	end
	local dark = cookie.GetNumber("SF-DarkTheme",1) == 1
	_STORMFOX_CLMENU = mgui.Create("DFrame")
	local r = cookie.GetNumber("SF-ThemeR",30)
	local g = cookie.GetNumber("SF-ThemeG",136)
	local b = cookie.GetNumber("SF-ThemeB",229)

	_STORMFOX_CLMENU:SetPallete(Color(r, g, b),nil,dark)
	--_STORMFOX_CLMENU:SetPallete(Color(255, 0, 0),nil,dark)

	_STORMFOX_CLMENU:SetTitle("Server Settings - ERROR")
	_STORMFOX_CLMENU:DockPadding(0,24,0,0)
	_STORMFOX_CLMENU:SetIcon(Material("stormfox/SF.png"))
	_STORMFOX_CLMENU:SetSize(600,400)
	_STORMFOX_CLMENU:Center()
	_STORMFOX_CLMENU:MakePopup()
	
	local panel = mgui.Create("Panel",_STORMFOX_CLMENU)
	panel:Dock(FILL)
	panel:InvalidateLayout(true)

	local menu = mgui.Create("Panel",panel)
	menu:Dock(LEFT)
	menu:SetWide(120)
	function menu:Paint(w,h)
		local c = self:GetPalleteColor()
		surface.SetDrawColor(Color(c.r,c.g,c.b,0))
		surface.DrawRect(0,0,w,h)
	end
	local display = mgui.Create("Panel",panel)
	display:Dock(FILL)
	display:InvalidateLayout(true)
	function display:Paint(w,h)
		local c = self:GetPalleteColor()
		surface.SetDrawColor(Color(c.r,c.g,c.b,255))
		surface.DrawRect(0,0,w,h)
	end
	local l = {"Time","Weather", "Misc", "Troubleshooting","Changelog"}

	menu.buttons = {}
	menu.board = {}
	for i,d in pairs(l) do
		local b = mgui.Create("DButton",menu)
		table.insert(menu.buttons,b)
		b.menu = menu
		b:Dock(TOP)
		b.roundcornor = 0
		b:SetTextAlingn(2)
		b:SetText(d)

		local p = mgui.Create("DScrollPanel",display)
		p.menu_button = b
		menu.board[d] = p
		p:Dock(FILL)
		p:SetMinimumSize(480,370)
		p.text = d
		p:Hide()
		function p:Paint(w,h)
			local s = "w: " .. self:GetWide() .. ", h: " .. self:GetTall()
			--draw.DrawText((self.text or "what") .. s,"default",10,10,Color(255,255,255),0)
		end
		function b.OnReleased() end
		function b:DoClick()
			_STORMFOX_CLMENU:SetTitle("Server Settings - " .. self.text)
			for k,v in pairs(self.menu.buttons) do
				v:DisableBackground(v==self)
				if v==self then
					cookie.Set("SF-MenuOption",k)
					menu.board[v.text]:Show()
					mgui.CallEvent("SF_SVMenu_Select",v.text)
				else
					menu.board[v.text]:Hide()
				end
			end
		end
	end
	local fill = mgui.Create("Panel",menu)
	fill:Dock(FILL)
	fill._palletecolor = "A500"
	function fill:Paint(w,h)
		local c = self:GetPalleteColor()
		surface.SetDrawColor(Color(c.r,c.g,c.b,255))
		surface.DrawRect(0,0,w,h)
	end
	local DPSwitch = mgui.Create("Button",menu)
		DPSwitch:Dock(BOTTOM)
		DPSwitch:SetText(dark and "Light Theme" or "Dark Theme")
		DPSwitch.s = dark
		DPSwitch.roundcornor = 0
		function DPSwitch:DoClick()
			self.s = not self.s
			cookie.Set("SF-DarkTheme",self.s and 1 or 0)
			local r = cookie.GetNumber("SF-ThemeR",30)
			local g = cookie.GetNumber("SF-ThemeG",136)
			local b = cookie.GetNumber("SF-ThemeB",229)
			_STORMFOX_CLMENU:SetPallete(Color(r, g, b),nil,self.s)
			self:SetText(self.s and "Light Theme" or "Dark Theme")
		end
	-- Menus (480, )
		-- Dashboard
			local panel = menu.board["Dashboard"]
		-- Time
			local panel = menu.board["Time"]
			local time = mgui.Create("Label",panel)
				time:SetPos(panel:GetWide() - 140,10)
				time:SetSize(140,20)
				time:SetTextAlingn(1)
			function time:Think()
				self:SetText(StormFox.GetRealTime() .. " - " .. StormFox.GetRealTime(nil,true))
			end
			local sunmoon = mgui.Create("Panel",panel)
				sunmoon:SetSize(140,140)
				sunmoon:SetPos(panel:GetWide() - 140,30)
				function sunmoon:Paint(w,h)
					local s = w / 3
					local tc = self:GetTextColor()
					local c = self:GetPalleteColor()
					for i=1,5 do
						surface.DrawCircle(w / 2,h / 2, s + i / 4,Color(tc.r,tc.g,tc.b,80 + i))
					end
					-- BG
						local suna = rad(StormFox.GetSunAngle().p)
						local sunx,suny = w / 2 + cos(suna) * s, h / 2 + sin(suna) * s

						local moonang = Angle(StormFox.GetMoonAngle().p,StormFox.GetMoonAngle().y,0)
						local moonpos = moonang:Forward()
						local x = moonpos.x * cos(rad(StormFox.GetSunMoonAngle())) + moonpos.y * sin(rad(StormFox.GetSunMoonAngle()))
						local y = -moonpos.z
						local moonx,moony = w / 2 + x * s, h / 2 + y * s
							surface.SetMaterial(m_circle)
							surface.SetDrawColor(self:GetParentColor())
							surface.DrawTexturedRect(moonx - 20, moony - 20 , 40,40)
							surface.DrawTexturedRect(sunx - 20, suny - 20 , 40,40)
					-- Moon
						local moonMat = Material(StormFox.GetData("MoonTexture") or "stormfox/effects/moon.png")
						surface.SetMaterial(moonMat)
						surface.SetDrawColor(Color(0,0,0,200))
						surface.DrawTexturedRect(moonx - 18, moony - 18 , 36,36)

						surface.SetDrawColor( StormFox.GetData("MoonColor",Color(205,205,205)) )
						surface.DrawTexturedRect(moonx - 16, moony - 16 , 32,32)
					-- Sun
						surface.SetMaterial(Material("stormfox/symbols/Sunny.png"))
						surface.SetDrawColor(Color(0,0,0,200))
						surface.DrawTexturedRect(sunx - 18, suny - 18 , 36,36)
						surface.SetDrawColor(Color(255,255,0))
						surface.DrawTexturedRect(sunx - 16, suny - 16 , 32,32)
				end
			-- Time
				local t = makeTitle(panel,"Time")
					t:SetSize(340,20)
					t:SetPos(0,10)
				-- sf_realtime
					local realtimevar 
					local realtime,label = serverToggle(panel,"sf_realtime")
						realtime:SetPos(20,10 + element_size)
						label:SetPos(30 + realtime:GetWide(),10 + element_size)
						label:SetTall(realtime:GetTall())
				-- sf_timespeed
					local timespeed,label = serverText(panel,"sf_timespeed",true)
						timespeed:SetSize(34,20)
						timespeed:SetPos(20,10 + element_size * 2)
						timespeed:SetDisabled(realtime.state)
						timespeed:AddEvent("sf_realtime_set",function(self,bool)
							if bool then
								self:SetValue(1)
							end
							self:SetDisabled(bool)
						end)
						label:SetPos(30 + timespeed:GetWide(),10 + element_size * 2)
						label:SetTall(20)
						--timespeed:SetSize(24,24)
						--timespeed:SetText("30")
						function timespeed:OnEdit()
							if not self.value then
								self.value = tonumber( GetConVar("sf_timespeed"):GetDefault() )
							end
							if self.value < 0 then
								self.value = 0
							elseif self.value > 3960 then
								self.value = 3960
							end
							StormFox.SetConvarSetting(self.setting,self.value or 60)
						end
				-- sf_start_time
					local starttime,label = serverText(panel,"sf_start_time")
						label:SetTall(20)
						starttime:SetPos(20,10 + element_size * 3)
						starttime:SetDisabled(realtime.state)
						starttime:AddEvent("sf_realtime_set",function(self,bool)
							self:SetDisabled(bool)
						end)
						starttime:SetSize(84,20)
						-- Display empty value
							function starttime:TextEditor(str)
								if str == "" then
									return "Save on exit"
								end
							end
						-- Choose what can be entered
							function starttime:CanAdd(str)
								local n = string.byte(str)
								if string.len(self.value) <= 0 then -- First var have to be 1 or 2
									if n~=48 and n~=49 and n~=50 then return false end
								end
								if (n >= 48 and n <= 58) and string.len(self.value) < 5 then
									if string.len(self.value) == 2 then
										return ":"..str
									else
										return str
									end
								end
								if string.len(self.value) == 5 and string.sub(self.value,0,1) ~= "2" and tonumber(string.sub(self.value,0,2)) < 13 then
									if str == "a" then 
										return "AM"
									elseif str == "p" then 
										return "PM" 
									end
								end
								return false
							end
						-- Check if valid
							function starttime:OnEdit()
								if string.len(self.value) > 0 and not string.match(self.value,"^%d%d:%d%d$") and not string.match(self.value,"^%d%d:%d%d[AP]M$") then
									local c = GetConVar("sf_start_time")
									self.value = c:GetString()
									return
								end
								StormFox.SetConvarSetting(self.setting,self.value or 60)
							end
						label:SetPos(30 + starttime:GetWide(),10 + element_size * 3)
			-- Moon / Sun
				local t = makeTitle(panel,"Sun / Moon")
					t:SetPos(0,10 + element_size * 4)
					t:SetSize(340,20)
				-- sf_sunmoon_yaw 
					local yaw,label = serverText(panel,"sf_sunmoon_yaw",true)
					label:SetTall(20)
					local set_to_look = mgui.Create("Button",panel)
						set_to_look:SetText("Set to Eye Angle")
						yaw:SetSize(40,20)
						yaw:SetPos(20,10 + element_size * 5)
						set_to_look:SetPos(70,10 + element_size * 5)
						set_to_look:SetSize(100,20)
						function set_to_look:DoClick()
							local n = math.Round(LocalPlayer():EyeAngles().yaw) % 360
							StormFox.SetConvarSetting("sf_sunmoon_yaw",n)
							yaw.value = n
						end
						function yaw:CanAdd(str)
							if str == "-" then return false end
							local newnum = tonumber(self.value .. str)
							if newnum%360~=newnum then
								self.value = newnum%360
								return false
							end
							return str
						end
						label:SetPos(180,10 + element_size * 5)
				-- sf_moonscale
					local moonscale,label = serverText(panel,"sf_moonscale",true)
					label:SetTall(20)
					moonscale:SetPos(20,10 + element_size * 6)
					moonscale:SetSize(40,20)
					function moonscale:CanAdd(str)
						if str == "-" then return false end
						local newnum = tonumber(self.value .. str .."")
						if newnum > 64 then
							self.value = "64"
							return false
						end
						return str
					end
					function moonscale:OnEdit()
						if not self.value then
							self.value = tonumber( GetConVar("sf_moonscale"):GetDefault() )
						end
						if self.value < 0 then
							self.value = 0
						elseif self.value > 64 then
							self.value = 64
						end
						StormFox.SetConvarSetting(self.setting,self.value)
					end
					label:SetPos(30 + moonscale:GetWide(),10 + element_size * 6)
				-- sf_moonphase
					local lock_moon,label = serverToggle(panel,"sf_moonphase")
					label:SetTall(20)
					lock_moon:SetPos(20,10 + element_size * 7)
					label:SetPos(70,10 + element_size * 7)
			-- Light
				-- minlight,maxlight
					local t = makeTitle(panel,"Light")
					t:SetSize(340,20)
					t:SetPos(0,10 + element_size * 8)
					--minlight, maxlight		
					local l = mgui.Create("Label",panel)
						l:SetText("Light range: ")
						l:SetPos(20,10 + element_size * 9)
						l:SizeToContentsX(2)
						l:SetTall(20)
					local sp = mgui.Create("DoubleSlider",panel)
					sp:SetPos(20 + l:GetWide(),10 + element_size * 9)
					sp:SetSize(260,20)
					sp.var = StormFox.GetMapSetting("minlight",4)
					sp.var2 = StormFox.GetMapSetting("maxlight",80)
					function sp:TextEditor(str)
						local n = math.max(4,tonumber(str))
						return math.Round(n / 4) * 4 .. "%"
					end
					function sp:OnReleased()
						local minlight = math.max(4,tonumber(self.var))
							minlight = math.Round(minlight / 4) * 4
							setmapdata("minlight",minlight)
						local maxlight = math.max(4,tonumber(self.var2))
							maxlight = math.Round(maxlight / 4) * 4
							setmapdata("maxlight",maxlight)
						mgui.AccpetSnd()
					end
				-- Dynamic light -- dynamiclight
					local dynamiclight = serverMapToggle(panel,"dynamiclight")
						dynamiclight:SetPos(20,10 + element_size * 10)
					local l = mgui.Create("Label",panel)
						l:SetPos(30 + dynamiclight:GetWide(),10 + element_size * 10)
						l:SetText("Allow dynamiclight for all clients.")
						l:SizeToContentsX(5)
						l:SetTall(20)
		-- Weather
			local panel = menu.board["Weather"]
				local t = makeTitle(panel,"Weather")
					t:SetSize(340,20)
					t:SetPos(0,10)
				local weatherinfo = mgui.Create("Panel",panel)
				weatherinfo:SetSize(140,140)
				weatherinfo:SetPos(panel:GetWide() - 140,30)
				function weatherinfo:Paint(w,h)
					local s = w / 3
					local tc = self:GetTextColor()
					local c = self:GetPalleteColor()
					surface.SetMaterial(StormFox.Weather:GetIcon())
					surface.SetDrawColor(tc)
					local s = 64
					surface.DrawTexturedRect(w / 2 - s / 2, 0,s,s)
					surface.SetTextColor(tc)
					surface.SetFont("mgui_default")
					local t = StormFox.GetWeather()
					local tw,th = surface.GetTextSize(t)
					surface.SetTextPos(w / 2 - tw / 2, s + th)
					surface.DrawText(t)
				end
				-- Disable autoweather
					local auto_weather,label = serverToggle(panel,"sf_autoweather")
					auto_weather:SetPos(20,10 + element_size * 3)
					label:SetPos(30 + realtime:GetWide(),10 + element_size * 3)
					label:SetTall(realtime:GetTall())
				-- Disable fog
					local auto_weather,label = serverToggle(panel,"sf_enablefog")
					auto_weather:SetPos(20,10 + element_size * 1)
					label:SetPos(30 + realtime:GetWide(),10 + element_size * 1)
					label:SetTall(realtime:GetTall())
				-- Disable lightning strikes
					local auto_weather,label = serverToggle(panel,"sf_lightningbolts")
					auto_weather:SetPos(20,10 + element_size * 2)
					label:SetPos(30 + realtime:GetWide(),10 + element_size * 2)
					label:SetTall(realtime:GetTall())
			-- Temperature
				local mintemp = mgui.Create("TextBox",panel)
				local mintempl = mgui.Create("DLabel",panel)
					mintemp:SetPos(20, 10 + element_size * 4)
					mintempl:SetPos(20, 10 + element_size * 5)

					mintemp:SetSize(40,20)
					mintempl:SetSize(40,20)
					mintemp:SetValue(StormFox.GetMapSetting("mintemp",-10))
					mintemp:SetNumeric(true)
					mintempl:SetTextAlingn(1)
					function mintemp:OnEdit()
						setmapdata("mintemp",tonumber(self.value))
					end
					function mintemp:TextEditor(str)
						mintempl:SetText(StormFox.CelsiusToFahrenheit(tonumber(str) or 0) .. "°F")
						return str .. "°C"
					end
				local l = mgui.Create("Label",panel)
					l:SetText("Temperature range")
					l:SizeToContentsX(4)
					l:SetPos(70,10 + element_size * 4)
					l:SetTall(20)
				local maxtemp = mgui.Create("TextBox",panel)
				local maxtempl = mgui.Create("DLabel",panel)
					maxtemp:SetPos(70 + l:GetWide() + 10, 10 + element_size * 4)
					maxtempl:SetPos(70 + l:GetWide() + 10, 10 + element_size * 5)
					maxtempl:SetTextAlingn(1)
					maxtemp:SetSize(40,20)
					maxtempl:SetSize(40,20)
					maxtemp:SetValue(StormFox.GetMapSetting("maxtemp",-10))
					maxtemp:SetNumeric(true)
					function maxtemp:OnEdit()
						setmapdata("maxtemp",tonumber(self.value))
					end
					function maxtemp:TextEditor(str)
						maxtempl:SetText(StormFox.CelsiusToFahrenheit(tonumber(str) or 0) .. "°F")
						return str .. "°C"
					end
				mintemp:AddEvent("sf_autoweather_set",function(self,b)
					self:SetDisabled(not b)
				end)
				maxtemp:AddEvent("sf_autoweather_set",function(self,b)
					self:SetDisabled(not b)
				end)
				l:AddEvent("sf_autoweather_set",function(self,b)
					self:SetDisabled(not b)
				end)
				mintempl:AddEvent("sf_autoweather_set",function(self,b)
					self:SetDisabled(not b)
				end)
				maxtempl:AddEvent("sf_autoweather_set",function(self,b)
					self:SetDisabled(not b)
				end)
			-- Weathers
				local element_id = 6
				local t = makeTitle(panel,"Auto Weather")
					t:SetSize(340,20)
					t:SetPos(0,10 + element_size * element_id)
				element_id = element_id + 1
				local x,y = -1,0
				for id,data in pairs(StormFox.WeatherTypes) do
					local pnl = mgui.Create("Panel",panel)
					pnl.id = id
					pnl.mat = data.GetStaticIcon()
					pnl:SetSize(80,60)
					x = x + 1
					if x > 3 then
						y = y + 1
						x = 0
					end
					pnl:SetPos(20 + x * 80,y * 70 + 10 + element_size * element_id)
					function pnl:Paint(w,h)
						local c = self:GetTextColor()
						surface.SetMaterial(self.mat)
						surface.SetDrawColor(c)
						surface.DrawTexturedRect(2,2,32,32)
					end

					local p = serverMapToggle(pnl,"weather_" .. id)
					if id == "clear" then
						p:SetDisabled(true)
					end
					local l = mgui.Create("DLabel",pnl)
					l.setting = "weather_" .. id
					if id ~= "clear" then
						p:AddEvent("sf_autoweather_set",function(self,b)
							self:SetDisabled(not b)
						end)
						l:AddEvent("weather_" .. id .. "_set",function(self,b)
							self:SetDisabled(not b)
						end)
					end
					l:AddEvent("sf_autoweather_set",function(self,b)
						if not b then
							self:SetDisabled(not b)
							return
						end
						local bb = StormFox.GetMapSetting(self.setting,false)
						self:SetDisabled(not bb)
					end)
					p:SetPos(36,10)
			
					local t = string.upper(string.sub(id,0,1)) .. string.sub(id,2)
					l:SetText(t)
					l:SetTextAlingn(2)
					l:SetPos(40 - l:GetWide() / 2,40)
				end
				element_id = element_id + y * 5 + 1
			-- Material 
				--replacment material_replacment
				local t = makeTitle(panel,"Material replacment")
					t:SetSize(340,20)
					t:SetPos(0,10 + element_size * element_id)
					local s = serverMapToggle(panel,"material_replacment")
					element_id = element_id + 1
					s:SetPos(20,10 + element_size * element_id)
					local l = mgui.Create("DLabel",panel)
					l:SetText("Allow weather to replace materials.")
					l:SizeToContentsX(2)
					l:SetTall(20)
					l:SetPos(30 + s:GetWide(),10 + element_size * element_id)
				--replace_dirtgrassonly
					local s = serverMapToggle(panel,"replace_dirtgrassonly")
					element_id = element_id + 1
					s:SetPos(20,10 + element_size * element_id)
					local l = mgui.Create("DLabel",panel)
					l:SetText("Only replace dirt and grass.")
					l:SizeToContentsX(2)
					l:SetTall(20)
					l:SetPos(30 + s:GetWide(),10 + element_size * element_id)
					s:AddEvent("material_replacment_set",function(self,b)
						self:SetDisabled(not b)
					end)
					l:AddEvent("material_replacment_set",function(self,b)
						self:SetDisabled(not b)
					end)
			-- Wind
				local t = makeTitle(panel,"Wind")
				element_id = element_id + 1
					t:SetSize(340,20)
					t:SetPos(0,10 + element_size * element_id)
				-- Windrange
				local la = mgui.Create("DLabel",panel)
					element_id = element_id + 1
					la:SetText("Max wind")
					la:SizeToContentsX(2)
					la:SetPos(20,10 + element_size * element_id)

				local windspeed = StormFox.GetMapSetting("maxwind",20)
				local wr = mgui.Create("Slider",panel)
					wr:SetSize(200,20)
					wr:SetPos(20 + la:GetWide(),10 + element_size * element_id)
					wr:SetValue(windspeed)
					wr.show_number = false
					wr:SetMax(50)
				local l = mgui.Create("DLabel",panel)
					l:SetPos(220 + la:GetWide(),10 + element_size * element_id)
					l:SetText( windspeed .. "ms" .. " / " .. math.Round(windspeed * 2.236936) .. "mph")
					l:SetWide(200)
					function l:Think()
						windspeed = wr.var
						local b,d = StormFox.GetBeaufort(windspeed)
						self:SetText( windspeed .. "ms" .. " / " .. math.Round(windspeed * 2.236936) .. "mph" .. " / " .. d)
					end
				function wr:OnReleased()
					setmapdata("maxwind",tonumber(self.var))
					mgui.AccpetSnd()
				end
				wr:AddEvent("sf_autoweather_set",function(self,b)
					self:SetDisabled(not b)
				end)
				l:AddEvent("sf_autoweather_set",function(self,b)
					self:SetDisabled(not b)
				end)
				la:AddEvent("sf_autoweather_set",function(self,b)
					self:SetDisabled(not b)
				end)
			-- Disable wind push
				local auto_weather,label = serverToggle(panel,"sf_windpush")
				element_id = element_id + 1
				auto_weather:SetPos(20,10 + element_size * element_id)
				label:SetPos(30 + realtime:GetWide(),10 + element_size * element_id)
				label:SetTall(realtime:GetTall())
			-- Disable windbreakconstrains
				local auto_weather = serverMapToggle(panel,"wind_breakconstraints")
				local label = mgui.Create("DLabel",panel)
					label:SetText("Break constraints and unfreeze props in strong wind.")
					label:SizeToContentsX(2)
				element_id = element_id + 1
				auto_weather:SetPos(20,10 + element_size * element_id)
				label:SetPos(30 + realtime:GetWide(),10 + element_size * element_id)
				label:SetTall(realtime:GetTall())
				label:AddEvent("sf_windpush_set",function(self,b)
					self:SetDisabled(not b)
				end)
				auto_weather:AddEvent("sf_windpush_set",function(self,b)
					self:SetDisabled(not b)
				end)

				
			-- Disable foliagesway
				local foliagesway,label = serverToggle(panel,"sf_foliagesway")
				element_id = element_id + 1
				foliagesway:SetPos(20,10 + element_size * element_id)
				
				label:SetPos(30 + realtime:GetWide(),10 + element_size * element_id)
				label:SetTall(realtime:GetTall())

		-- Misc
			local panel = menu.board["Misc"]
			local t = makeTitle(panel,"Map")
					t:SetSize(340,20)
					t:SetPos(0,10)
			-- Mapsupport
				local auto_weather,label = serverToggle(panel,"sf_enable_mapsupport")
				auto_weather:SetPos(20,10 + element_size)
				label:SetPos(30 + realtime:GetWide(),10 + element_size)
				label:SetTall(realtime:GetTall())
			-- Skybox
				local auto_weather,label = serverToggle(panel,"sf_skybox")
				auto_weather:SetPos(20,10 + element_size * 2)
				label:SetPos(30 + realtime:GetWide(),10 + element_size * 2)
				label:SetTall(realtime:GetTall())
				label:SetText(label:GetText() .. "(Requires mapchange)")
				label:SizeToContentsX(5)
			-- Disable 
				local auto_weather,label = serverToggle(panel,"sf_mapbloom")
				auto_weather:SetPos(20,10 + element_size * 3)
				label:SetPos(30 + realtime:GetWide(),10 + element_size * 3)
				label:SetTall(realtime:GetTall())
				label:SizeToContentsX(5)
			local t = makeTitle(panel,"Clients")
					t:SetSize(340,20)
					t:SetPos(0,element_size * 4 + 10)
			-- Disable 
				local auto_weather,label = serverToggle(panel,"sf_allowcl_disableeffects")
				auto_weather:SetPos(20,10 + element_size * 5)
				label:SetPos(30 + realtime:GetWide(),10 + element_size * 5)
				label:SetTall(realtime:GetTall())
				label:SizeToContentsX(5)
			-- Disable 
				local auto_weather,label = serverToggle(panel,"sf_enable_mapbrowser")
				auto_weather:SetPos(20,10 + element_size * 6)
				label:SetPos(30 + realtime:GetWide(),10 + element_size * 6)
				label:SetTall(realtime:GetTall())
				label:SizeToContentsX(5)
			local t = makeTitle(panel,"Other")
					t:SetSize(340,20)
					t:SetPos(0,element_size * 7 + 10)
			-- Disable 
				local auto_weather,label = serverToggle(panel,"sf_debugcompatibility")
				auto_weather:SetPos(20,10 + element_size * 8)
				label:SetPos(30 + realtime:GetWide(),10 + element_size * 8)
				label:SetTall(realtime:GetTall())
				label:SizeToContentsX(5)
			-- Disable 
				local auto_weather,label = serverToggle(panel,"sf_weatherdebuffs")
				auto_weather:SetPos(20,10 + element_size * 9)
				label:SetPos(30 + realtime:GetWide(),10 + element_size * 9)
				label:SetTall(realtime:GetTall())
				label:SizeToContentsX(5)
				--[[
					sf_enable_mapsupport 			(sf_block_lightenvdelete)
					sf_skybox
					sf_disable_ekstra_lightsupport
					sf_mapbloom
				]]
				local r = cookie.GetNumber("SF-ThemeR",30)
				local g = cookie.GetNumber("SF-ThemeG",136)
				local b = cookie.GetNumber("SF-ThemeB",229)
				local DRGBPicker = vgui.Create( "DRGBPicker", panel )
			--	DermaColorCombo:SetAlphaBar(false)
			--	DermaColorCombo:SetPalette(false)
				DRGBPicker:SetSize(20,140)

				DRGBPicker:SetPos( 420,10 + element_size * 0 )
				local h = ColorToHSV( Color( r, g, b ) )
				DRGBPicker.LastY = DRGBPicker:GetTall()*( 1-( h/360 ) )
				DRGBPicker:SetRGB( Color( r, g, b ) )
				function DRGBPicker:OnChange( col )
					local dark = cookie.GetNumber("SF-DarkTheme",1) == 1
					local r = cookie.Set("SF-ThemeR",col.r)
					local g = cookie.Set("SF-ThemeG",col.g)
					local b = cookie.Set("SF-ThemeB",col.b)
					_STORMFOX_CLMENU:SetPallete(Color(col.r, col.g, col.b),nil,dark)
				end
				local reset = mgui.Create("Button",panel)
				reset:SetText("Reset")
				reset:SetPos(500 - 100,154)
				function reset:DoClick()
					local dark = cookie.GetNumber("SF-DarkTheme",1) == 1
					cookie.Set("SF-ThemeR",30)
					cookie.Set("SF-ThemeG",136)
					cookie.Set("SF-ThemeB",229)
					local h = ColorToHSV( Color( 30, 136, 229 ) )
					DRGBPicker.LastY = DRGBPicker:GetTall()*( 1-( h/360 ) )
					_STORMFOX_CLMENU:SetPallete(Color(30,136,229),nil,dark)
				end
		-- Conflicts
			local panel = menu.board["Troubleshooting"]
			local t = makeTitle(panel,"Troubleshooting")
					t:SetSize(340,20)
					t:SetPos(0,10)
				local t = mgui.Create("DLabel",panel)
					t:SetPos(20,30)
					t:SetText("This will display the most common problems with the current settings.")
					t:SizeToContentsX(4)
				local problemlist = mgui.Create("DScrollPanel",panel)
					problemlist:SetPos(20,50)
					problemlist:SetSize(panel:GetWide() - 40,panel:GetTall() - 60)
					function problemlist:UpdateList()
						for k,v in pairs(self:GetCanvas():GetChildren()) do
							v:Remove()
						end
						local i = 0
						for id,v in pairs(p_list) do
							if v[1]() then
								i = i + 1
								local des,solution = v[2],v[3]
								local panel = mgui.Create("Button",self)
									panel:SetSize(self:GetWide(),30)
									self:AddItem(panel)
									panel:SetText(des)
									panel:SetPos(0,30 * (i - 1))
									panel.DoClick = function()
										panel:SetDisabled(true)
										v[3]()
									end
							end
						end
					end
					problemlist:AddEvent("SF_SVMenu_Select",function(self)
						self:UpdateList()
					end)
		-- Changelog
			--local panel = menu.board["Changelog"]
			menu.buttons[5].DoClick = function()
				gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/changelog/1132466603")
			end
	menu.buttons[math.Clamp(cookie.GetNumber("SF-MenuOption",1),1,5)]:DoClick()
	-- Trigger settings
		for setting,t in pairs(settingList) do
			local c = GetConVar(setting)
			if t == 1 then
				mgui.CallEvent(setting .. "_set",c:GetInt() == 1)
			else
				mgui.CallEvent(setting .. "_set",c:GetString() or c:GetDefault())
			end
		end
		for setting,t in pairs(mapsettingList) do
			mgui.CallEvent(setting .. "_set",StormFox.GetMapSetting(setting))
		end
end
local function AddCommenProblem(func_detect,description,func_solution)
	table.insert(p_list,{func_detect,description,func_solution})
end
local function convar_check(str,var)
	local c = GetConVar(str)
	if not c then ErrorNoHalt("Unknown convar: " .. str) return end
	return c:GetString() == var
end
-- Commen problems:
	-- sf_enable_ekstra_lightsupport on huge maps
	AddCommenProblem(function()
		local mapsize = StormFox.MapOBBMaxs() - StormFox.MapOBBMins()
		local unit = mapsize:Length()
		return unit > 30000
		end,"Source lightsupport on large maps can lag clients (No fixes)",function()
	end)
	-- sf_enable_mapsupport being disabled
	AddCommenProblem(function() 
		return convar_check("sf_enable_mapsupport","0") 
		end,"All map-support is disabled [sf_enable_mapsupport 0]",function()
		StormFox.SetConvarSetting("sf_enable_mapsupport",1)
	end)
	-- sf_disable_mapsupport being enabled
	AddCommenProblem(function() 
		return convar_check("sf_skybox","0") 
		end,"Skybox-support is disabled. [sf_skybox 0] (Requires a restart to fix)",function()
		StormFox.SetConvarSetting("sf_skybox",1)
	end)

	-- Dynamic light on a 2D map
	AddCommenProblem(function() 
		return StormFox.GetMapSetting("dynamiclight") and not StormFox.Is3DSkybox() 
		end,"Dynamic light on a 2D map can cause black triangles in the sky.",function()
		StormFox.SetMapSetting("dynamiclight",false)
	end)
	-- Dynamic light with treesway
	AddCommenProblem(function() 
		return StormFox.GetMapSetting("dynamiclight") and convar_check("sf_foliagesway","1") 
		end,"Dynamic light and foliagesway can cause materials flickering.",function()
		StormFox.SetMapSetting("dynamiclight",false)
	end)

