--[[
	--("sf_disableeffects","0",true,false,"Disable all effects.")
	--("sf_exspensive","0",true,false,"[0-7+] Enable exspensive weather calculations.")
	--("sf_material_replacment","1",true,false,"Enable material replacment for weather effects.")
	--("sf_allow_rainsound","1",true,false,"Enable rain-sounds.")
	--("sf_allow_windsound","1",true,false,"Enable wind-sounds.")
	--("sf_allow_dynamiclights","1",true,false,"Enable lamp-lights from SF.")
	--("sf_allow_sunbeams","1",true,false,"Enable sunbeams.")
	--("sf_allow_dynamicshadow","0",true,false,"Enable dynamic light/shadows.")
	--("sf_dynamiclightamount","0",true,false,"Controls the dynamic-light amount.")
	--("sf_redownloadlightmaps","1",true,false,"Update lightmaps (Can lag on large maps)")
	--("sf_allow_raindrops","1",true,false,"Enable raindrops on the screen")
	--("sf_renderscreenspace_effects","1",true,false,"Enable RenderScreenspaceEffects")
	--("sf_enable_breath","1",true,false,"Enable cold breath-effect.")
	("sf_useAInode","1",true,false,"Use AI nodes for more reliable sounds and effects.") People don't know what this is.
]]
local function makeTitle(parent,text)
	local p = mgui.Create("Panel",parent)
	p.text = StormFox.Language.Translate(text)
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
local settingList = {}
local function clientToggle(parent,setting)
	settingList[setting] = 1
	local p = mgui.Create("Switch",parent)
		p.setting = setting
	local l = mgui.Create("DLabel",parent)
	local c = GetConVar(setting)
		p:Toggle(c:GetInt() == 1)
	function p:DoClick()
		local b = self.state
		mgui.CallEvent(self.setting .. "_set",self.state)
		RunConsoleCommand(self.setting,self.state and "1" or "0")
	end
	if not c then
		l:SetText("Missing convar")
	else
		l:SetText(StormFox.Language.Translate(c:GetHelpText()))
	end
		l:SizeToContentsX( 10 )
	return p,l
end
concommand.Add("sf_openclsettings",function()
	if StormFox.OpenClientSettings then
		StormFox.OpenClientSettings()
	end
end,nil,"Opens the client-settings.")

local element_size = 24

function StormFox.OpenClientSettings()
	-- Build the menu
		if _STORMFOX_CLMENU then
			_STORMFOX_CLMENU:Remove()
		end
		local dark = cookie.GetNumber("SF-DarkTheme",1) == 1
		_STORMFOX_CLMENU = mgui.Create("DFrame")
		local r = cookie.GetNumber("SF-ThemeR",30)
		local g = cookie.GetNumber("SF-ThemeG",136)
		local b = cookie.GetNumber("SF-ThemeB",229)

		_STORMFOX_CLMENU:SetPallete(Color(r, g, b),nil,dark)
		_STORMFOX_CLMENU:SetTitle("StormFox - v" .. StormFox.Version)
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
		local l = {"StormFox","Effects","Troubleshooter","Changelog"}

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
				for k,v in pairs(self.menu.buttons) do
					v:DisableBackground(v==self)
					if v==self then
						cookie.Set("SF-MenuOption_CL",k)
						menu.board[v.text]:Show()
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
			DPSwitch:SetText(StormFox.Language.Translate(dark and "sf_interface_lighttheme" or "sf_interface_darktheme"))
			DPSwitch.s = dark
			DPSwitch.roundcornor = 0
			function DPSwitch:DoClick()
				self.s = not self.s
				cookie.Set("SF-DarkTheme",self.s and 1 or 0)
				local r = cookie.GetNumber("SF-ThemeR",30)
				local g = cookie.GetNumber("SF-ThemeG",136)
				local b = cookie.GetNumber("SF-ThemeB",229)
				_STORMFOX_CLMENU:SetPallete(Color(r, g, b),nil,self.s)
				self:SetText(StormFox.Language.Translate(self.s and "sf_interface_lighttheme" or "sf_interface_darktheme"))
			end
	-- Settings
		local panel = menu.board["StormFox"]
		-- Menu color picker
			local r = cookie.GetNumber("SF-ThemeR",30)
			local g = cookie.GetNumber("SF-ThemeG",136)
			local b = cookie.GetNumber("SF-ThemeB",229)
			local DRGBPicker = vgui.Create( "DRGBPicker", panel )
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
		local t = makeTitle(panel,"StormFox")
			t:SetSize(340,20)
			t:SetPos(0,10)
		-- Disable SF
			local p,label = clientToggle(panel,"sf_disableeffects")
				p:SetPos(20,10 + element_size)
				label:SetPos(30 + p:GetWide(),10 + element_size)
				label:SetTall(p:GetTall())
				settingList["sf_allowcl_disableeffects"] = 1
				p:AddEvent("sf_allowcl_disableeffects_set",function(self,bool)
					self:SetDisabled(not bool)
					if not bool then
						label:SetText(StormFox.Language.Translate("sf_description.disableeffects") .. "(" .. StormFox.Language.Translate("sf_description.disabled_on_server") .. ")")
					else
						label:SetText("sf_description.disableeffects")
					end
					label:SizeToContentsX(5)
				end)
		-- SF Quality
			local t = makeTitle(panel,"Quality")
			t:SetSize(340,20)
			t:SetPos(0,10 + element_size * 2)
			settingList["sf_exspensive"] = true -- call this
			-- Auto
				local p = mgui.Create("Switch",panel)
					p:SetPos(20,10 + element_size * 3)
				local l = mgui.Create("DLabel",panel)
					l:SetText("sf_description.exspensive_fps")
					l:SizeToContentsX(5)
					l:SetPos(30 + p:GetWide(),10 + element_size * 3)
				function p:DoClick()
					local b = self.state
					local n = math.Round(StormFox.GetExspensive(),1) .. ""
					mgui.CallEvent("sf_exspensive_set",self.state and "0" or n)
					RunConsoleCommand("sf_exspensive",self.state and "0" or n)
				end
				local convar = GetConVar("sf_exspensive")
				p.state = convar:GetInt() == 0
			-- Manually
				local l = mgui.Create("DLabel",panel)
					l:SetText("sf_description.exspensive_manually")
					l:SizeToContentsX(5)
					l:SetPos(20,10 + element_size * 4)
				local wr = mgui.Create("Slider",panel)
					wr:SetPos(20 + l:GetWide(),10 + element_size * 4)
					wr:SetSize(200,20)
					wr:SetMax(20)
					wr:SetMin(1)
					wr:SetValue(convar:GetInt())
				function wr:OnReleased()
					RunConsoleCommand("sf_exspensive",self.var)
					mgui.AccpetSnd()
				end
				function wr:Think()
					local convar = GetConVar("sf_exspensive")
					if convar:GetInt() ~= 0 then return end
					self.var = math.Round(StormFox.GetExspensive(),1)
				end
				wr:AddEvent("sf_exspensive_set",function(self,str)
					self:SetDisabled(str == "0")
				end)
		-- SF Materials
			local t = makeTitle(panel,"Materials")
			t:SetSize(340,20)
			t:SetPos(0,10 + element_size * 5)
			-- sf_material_replacment
			local p,label = clientToggle(panel,"sf_material_replacment")
				p:SetPos(20,10 + element_size * 6)
				label:SetPos(30 + p:GetWide(),10 + element_size * 6)
				label:SetTall(p:GetTall())
		-- SF Light
			local t = makeTitle(panel,"sf_interface_light")
			t:SetSize(340,20)
			t:SetPos(0,10 + element_size * 7)
			--sf_allow_dynamicshadow
			settingList["sf_allow_dynamicshadow"] = 1
			local p,label = clientToggle(panel,"sf_allow_dynamicshadow")
				p:SetPos(20,10 + element_size * 8)
				label:SetPos(30 + p:GetWide(),10 + element_size * 8)
				label:SetTall(p:GetTall())
			if not StormFox.GetMapSetting("dynamiclight") then
				p:SetDisabled(true)
				label:SetText(label:GetText() .. " (" .. StormFox.Language.Translate("sf_description.disabled_on_server") .. ")")
				label:SizeToContentsX(5)
			end
			--sf_dynamiclightamount
				local label = mgui.Create("DLabel",panel)
				label:SetText("sf_description.dynamiclightamount")
				label:SizeToContentsX(5)
				label:SetPos(20,10 + element_size * 9)
				local convar = GetConVar("sf_dynamiclightamount")
				local wr = mgui.Create("Slider",panel)
					wr:SetPos(20 + label:GetWide(),10 + element_size * 9)
					wr:SetSize(200,20)
					wr:SetMax(5)
					wr:SetMin(1)
					wr:SetValue(convar:GetInt())
				function wr:OnReleased()
					RunConsoleCommand("sf_dynamiclightamount",self.var)
					mgui.AccpetSnd()
				end
				wr:AddEvent("sf_allow_dynamicshadow_set",function(self,bool)
					if not StormFox.GetMapSetting("dynamiclight") then
						self:SetDisabled( true )
						return
					end
					self:SetDisabled(not bool)
				end)
			--sf_allow_sunbeams
				local p,label = clientToggle(panel,"sf_allow_sunbeams")
				p:SetPos(20,10 + element_size * 10)
				label:SetPos(30 + p:GetWide(),10 + element_size * 10)
				label:SetTall(p:GetTall())
			--sf_allow_dynamiclights
				local p,label = clientToggle(panel,"sf_allow_dynamiclights")
				p:SetPos(20,10 + element_size * 11)
				label:SetPos(30 + p:GetWide(),10 + element_size * 11)
				label:SetTall(p:GetTall())
		-- SF Misc
			local t = makeTitle(panel,"Sound")
			t:SetSize(340,20)
			t:SetPos(0,10 + element_size * 12)
			--sf_allow_rainsound
			local p,label = clientToggle(panel,"sf_allow_rainsound")
				p:SetPos(20,10 + element_size * 13)
				label:SetPos(30 + p:GetWide(),10 + element_size * 13)
				label:SetTall(p:GetTall())
			--sf_allow_windsound
			local p,label = clientToggle(panel,"sf_allow_windsound")
				p:SetPos(20,10 + element_size * 14)
				label:SetPos(30 + p:GetWide(),10 + element_size * 14)
				label:SetTall(p:GetTall())
		-- Space
			--local p = mgui.Create("DPanel",panel)
			--p:SetSize(10,10)
			--p:SetPos(0,10 + element_size * 15)
			--function p:Paint() end
	-- Effects
		local panel = menu.board["Effects"]
		local t = makeTitle(panel,"Rain/Snow Effects")
			t:SetSize(340,20)
			t:SetPos(0,10)
			--sf_allow_raindrops (Rain on screen)
				local p,label = clientToggle(panel,"sf_allow_raindrops")
				p:SetPos(20,10 + element_size * 1)
				label:SetPos(30 + p:GetWide(),10 + element_size * 1)
				label:SetTall(p:GetTall())
			--sf_rainpuddle_enable (Enable rain puddles)
				local p,label = clientToggle(panel,"sf_rainpuddle_enable")
				p:SetPos(20,10 + element_size * 2)
				label:SetPos(30 + p:GetWide(),10 + element_size * 2)
				label:SetTall(p:GetTall())
				if not StormFox.AIAinIsValid() then
					p:SetDisabled(true)
				end
			--sf_footsteps_enable (Enable footprints in snow)
				local p,label = clientToggle(panel,"sf_footsteps_enable")
				p:SetPos(20,10 + element_size * 3)
				label:SetPos(30 + p:GetWide(),10 + element_size * 3)
				label:SetTall(p:GetTall())
			--sf_footsteps_max (Max footsteps)
				local label = mgui.Create("DLabel",panel)
					label:SetText(StormFox.Language.Translate("sf_interface_max_footprints") ..": ")
					label:SizeToContentsX(5)
					label:SetPos(20,10 + element_size * 4)
				local label2 = mgui.Create("DLabel",panel)
					label2:SetText(StormFox.Language.Translate("sf_interface_footprint_render") ..": ")
					label2:SizeToContentsX(5)
					label2:SetPos(20,10 + element_size * 5)
				local convar = GetConVar("sf_footsteps_max")
				local wr = mgui.Create("Slider",panel)
					wr:SetPos(20 + label:GetWide(),10 + element_size * 4)
					wr:SetSize(200 + (label2:GetWide() - label:GetWide()),20)
					wr:SetMax(500)
					wr:SetMin(30)
					wr.decimals = 0
					wr:SetValue(convar:GetInt())
				function wr:OnReleased()
					RunConsoleCommand("sf_footsteps_max",self.var)
					mgui.AccpetSnd()
				end
				wr:AddEvent("sf_footsteps_enable_set",function(self,bool)
					self:SetDisabled(not bool)
				end)
			--sf_footsteps_distance (Footstep renderdistance)
				local convar = GetConVar("sf_footsteps_distance")
				local wr = mgui.Create("Slider",panel)
					wr:SetPos(20 + label2:GetWide(),10 + element_size * 5)
					wr:SetSize(200,20)
					wr:SetMax(3000)
					wr:SetMin(400)
					wr.decimals = 0
					wr:SetValue(convar:GetInt())
				function wr:OnReleased()
					RunConsoleCommand("sf_footsteps_distance",self.var)
					mgui.AccpetSnd()
				end
				wr:AddEvent("sf_footsteps_enable_set",function(self,bool)
					self:SetDisabled(not bool)
				end)
			--sf_enable_windoweffect (Rain on window)
				local p,label = clientToggle(panel,"sf_enable_windoweffect")
				p:SetPos(20,10 + element_size * 6)
				label:SetPos(30 + p:GetWide(),10 + element_size * 6)
				label:SetTall(p:GetTall())
			--sf_enable_windoweffect_enable_tr (TR rain on window) 
				local p,label = clientToggle(panel,"sf_enable_windoweffect_enable_tr")
				p:SetPos(20,10 + element_size * 7)
				label:SetPos(30 + p:GetWide(),10 + element_size * 7)
				label:SetTall(p:GetTall())
				p:AddEvent("sf_enable_windoweffect_set",function(self,bool)
					self:SetDisabled(not bool)
				end)
		local t = makeTitle(panel,"Misc Effects")
			t:SetSize(340,20)
			t:SetPos(0,10 + element_size * 8)
			--sf_redownloadlightmaps
				local p,label = clientToggle(panel,"sf_redownloadlightmaps")
				p:SetPos(20,10 + element_size * 9)
				label:SetText(label:GetText() .."(" .. StormFox.Language.Translate("sf_warning_unsupportmap") ..")")
				label:SizeToContentsX(5)
				label:SetPos(30 + p:GetWide(),10 + element_size * 9)
				label:SetTall(p:GetTall())
			--sf_renderscreenspace_effects
				local p,label = clientToggle(panel,"sf_renderscreenspace_effects")
				p:SetPos(20,10 + element_size * 10)
				label:SetPos(30 + p:GetWide(),10 + element_size * 10)
				label:SetTall(p:GetTall())
			--sf_enable_breath
				local p,label = clientToggle(panel,"sf_enable_breath")
				p:SetPos(20,10 + element_size * 11)
				label:SetPos(30 + p:GetWide(),10 + element_size * 11)
				label:SetTall(p:GetTall())

	-- Toubleshooter
		local panel = menu.board["Troubleshooter"]
		local l = mgui.Create("DLabel",panel)
			l:SetText("sf_warning_unfinished_a")
			l:SizeToContentsX(5)
			l:SetPos(10,10)
			local button = mgui.Create("DButton",panel)
				button:SetText("sf_warning_unfinished_b")
				button:SetPos(240 - 170,30)
				button:SetSize(340,24)
				function button:DoClick()
					net.Start("sf_mapsettings")
						net.WriteString("menu")
						net.WriteInt(4,4)
					net.SendToServer()
				end

	-- Changelog
		menu.buttons[4].DoClick = function()
			gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/changelog/1132466603")
		end

	-- Trigger settings
		-- Trigger settings
		for setting,t in pairs(settingList) do
			local c = GetConVar(setting)
			if t == 1 then
				mgui.CallEvent(setting .. "_set",c:GetInt() == 1)
			else
				mgui.CallEvent(setting .. "_set",c:GetString() or c:GetDefault())
			end
		end
	-- Open the last page
		menu.buttons[math.Clamp(cookie.GetNumber("SF-MenuOption_CL",1),1,5)]:DoClick()
end