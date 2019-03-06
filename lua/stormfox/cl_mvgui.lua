--[[-------------------------------------------------------------------------
Created by Nak
	Material GUI
	Sound only if no visuals
---------------------------------------------------------------------------]]
--	if mgui then return end
	mgui = {}
	mgui = table.Copy(vgui)
local clamp,min,max,abs,lerp,cos,sin,rad,round = math.Clamp,math.min,math.max,math.abs,Lerp,math.cos,math.sin,math.rad,math.Round
-- Event system (Much better than shitty think functions)
	local events = {}
	function mgui.CallEvent(name,...)
		if not events[name] then return end
		for panel,func in pairs(events[name]) do
			if not IsValid(panel) then
				events[name][panel] = nil
			else
				func(panel,...)
			end
		end
	end
-- New color functions
	-- HSL support
		local function HSLToColor(H,S,L)
			H = clamp(H,0,360)
			S = clamp(S,0,1)
			L = clamp(L,0,1)
			local C = (1-abs(2 * L-1)) * S
			local X = C * (1-abs((H / 60) % 2 - 1))

			local m = L-C / 2
			local R1,G1,B1 = 0,0,0

			if H < 60 or H >= 360 then R1,G1,B1 = C,X,0
			elseif H < 120 		then R1,G1,B1 = X,C,0
			elseif H < 180 		then R1,G1,B1 = 0,C,X
			elseif H < 240 		then R1,G1,B1 = 0,X,C
			elseif H < 300 		then R1,G1,B1 = X,0,C
			else  --[[ H<360 ]] 	 R1,G1,B1 = C,0,X
			end
			return Color((R1 + m) * 255,(G1 + m) * 255,(B1 + m) * 255)
		end
		local function ColorToHSL(col)
			local R,G,B = clamp(col.r,0,255) / 255,clamp(col.g,0,255) / 255,clamp(col.b,0,255) / 255
			local mmax,mmin = max(R,G,B),min(R,G,B)
			local del = mmax-mmin
			-- Hue
			local H = 0
			if del <= 0 then H = 0
			elseif mmax == R then 	H = 60 * ( ( (G-B) / del ) % 6 )
			elseif mmax == G then 	H = 60 * ( ( (B-R) / del + 2) % 6 )
			else--[[max==B]]	H = 60 * ( ( (R-G) / del + 4) % 6 )
			end

			-- Lightness
			local L = (mmax + mmin) / 2

			-- Saturation
			local S = 0
			if del ~= 0 then
				S = del / (1 - abs(2 * L - 1))
			end
			return H,S,L
		end
	-- Lighten
		local function lighten(self,num)
			local h,s,l = ColorToHSL(self)
			return HSLToColor(h,s,l + num)
		end
		local function darken(self,num)
			local h,s,l = ColorToHSL(self)
			return HSLToColor(h,s,l - num)
		end
	-- Luminance
		-- returns luminance [0-255] (The cheap) function based on the human eye
		local function ColorToLuminance(Col)
			return 0.2126 * Col.r + 0.7152 * Col.g + 0.0722 * Col.b
		end
-- Fonts
	surface.CreateFont( "mgui_default", {
		font = "Roboto",
		extended = false,
		size = 14,
		weight = 500,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
-- Materials
	local grad = Material("gui/gradient_up")
	local noicon = Material("gui/noicon.png","noclamp")
-- local functions
	local function hex(str)
		str = string.gsub(str,"#","")
		return Color(tonumber("0x"..string.sub(str,1,2)), tonumber("0x"..string.sub(str,3,4)), tonumber("0x"..string.sub(str,5,6)))
	end
	local function Circle( x, y, radius, seg,h )
		draw.NoTexture()
		if not h then h = 1 end
		local cir = {}
		--table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
		for i = 0, seg do
			local a = math.rad( ( i / seg ) * -360 )
			table.insert( cir, { x = x + math.sin( a ) * radius * h, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
		end
		local a = math.rad( 0 ) -- This is needed for non absolute segment counts
		table.insert( cir, { x = x + math.sin( a ) * radius * h, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
		surface.DrawPoly( cir )
	end
	local function circleBox( x, y, w, h )
		if w <= 0 then return end
		draw.NoTexture()
		if not h then h = 1 end
		local rbox = {}
		local h2 = h / 2
		table.insert( rbox, { x = x + h / 2, y = y } )
		table.insert( rbox, { x = x + w - h / 2, y = y } )
		for i=1,10 do
			local a = rad(i * 18) - 90
			table.insert( rbox, { x = x + w - h / 2 + cos(a) * h2, y = y + sin(a) * h2 + h2} )
		end
		table.insert( rbox, { x = x + w - h / 2, y = y + h } )
		table.insert( rbox, { x = x + h / 2, y = y + h } )
		for i=1,10 do
			local a = rad(i * 18) - 90
			table.insert( rbox, { x = x + h / 2 - cos(a) * h2, y = y + h - sin(a) * h2 - h2 } )
		end
		surface.DrawPoly( rbox )
	end
	local function playSnd(snd,pitch,volume)
		if not LocalPlayer() then return end
		LocalPlayer():EmitSound(snd,75,pitch or 100, volume or 1)
	end
	local function RoundedBoxOutline(x,y,w,h,thickness)
		local thickness = thickness or 1.5
		local thickness2 = thickness * 2
		draw.NoTexture()
		local rbox = {}
			table.insert( rbox, { x = x + thickness, y = y } )
			table.insert( rbox, { x = x + w - thickness, y = y } )
			table.insert( rbox, { x = x + w, y = y + thickness} )
			table.insert( rbox, { x = x + w, y = y + thickness2} )
			table.insert( rbox, { x = x , y = y + thickness2} )
			table.insert( rbox, { x = x , y = y + thickness } )
		surface.DrawPoly( rbox )

		local rbox = {}
			table.insert( rbox, { x = x + w - thickness2, y = y + thickness2} )
			table.insert( rbox, { x = x + w, y = y + thickness2} )
			table.insert( rbox, { x = x + w, y = y + h - thickness} )
			table.insert( rbox, { x = x + w - thickness, y = y + h} )
			table.insert( rbox, { x = x + w - thickness2, y = y + h} )
		surface.DrawPoly( rbox )

		local rbox = {}
			table.insert( rbox, { x = x , y = y + thickness2 } )
			table.insert( rbox, { x = x + thickness2 , y = y + thickness2 } )
			table.insert( rbox, { x = x + thickness2 , y = y + h } )
			table.insert( rbox, { x = x + thickness , y = y + h } )
			table.insert( rbox, { x = x , y = y + h - thickness } )
		surface.DrawPoly( rbox )

		local rbox = {}
			table.insert( rbox, { x = x + thickness2 , y = y + h - thickness2  } )
			table.insert( rbox, { x = x + w - thickness2 , y = y + h - thickness2  } )
			table.insert( rbox, { x = x + w - thickness2 , y = y + h  } )
			table.insert( rbox, { x = x + thickness2 , y = y + h  } )
		surface.DrawPoly( rbox )
	end
	local function RoundedBox(x,y,w,h,thickness) -- Not so smooth
		local thickness = thickness or 1.5
		local thickness2 = thickness * 2

		draw.NoTexture()
		local rbox = {}
			table.insert( rbox, { x = x + thickness, y = y } )
			table.insert( rbox, { x = x + w - thickness, y = y } )
			table.insert( rbox, { x = x + w, y = y + thickness} )

			table.insert( rbox, { x = x + w, y = y + h - thickness} )
			table.insert( rbox, { x = x + w - thickness, y = y + h} )
			table.insert( rbox, { x = x + thickness, y = y + h } )
			table.insert( rbox, { x = x, y = y + h - thickness } )
			table.insert( rbox, { x = x, y = y + thickness } )
		surface.DrawPoly( rbox )
	end
	local function pressAble(self)
		self._down = false
		self._ringsize = 0
		self._ringx = 0
		self._ringy = 0
	end
	local function deemphasized(col,procent)
		local h,s,v = ColorToHSV(col)
		local c = HSVToColor(h,0,v)
		c.a = (procent or 100) * 2.55
		return c
	end
	local function RenderRing(panel)
		if panel:GetDisabled() then return end
		local color = deemphasized(panel:GetTextColor(),16)
		if panel:IsDown() and not panel._down then
			panel._down = true
			panel._alp = 1
			panel._ringsize = 6
			panel._ringx,panel._ringy = panel:LocalCursorPos()
		elseif not panel:IsDown() and panel._down then
			panel._down = false
		elseif not panel._down and panel:IsHovered() then
			local c = deemphasized(panel:GetTextColor(),8)
			surface.SetDrawColor(c)
			surface.DrawRect(0,0,panel:GetWide(),panel:GetTall())
		end
		if not panel._ringsize then panel._ringsize = 0 end
		if panel._ringsize <= 0 then return end

		local ring_max = max(panel:GetWide(),panel:GetTall()) * 1.5
		if panel._ringsize >= ring_max and not panel:IsDown() then
			panel._ringsize = 0
		elseif panel._ringsize < ring_max then
			panel._ringsize = min(ring_max,panel._ringsize + FrameTime() * 200)
		end

		if not panel._down then
			panel._alp = max(0,(panel._alp or 0) - FrameTime() * 10)
		end
		local c = color
			c.a = c.a * panel._alp
		surface.SetDrawColor(c)
		Circle( panel._ringx,panel._ringy, panel._ringsize, 20 )
	end
	local function GeneratePallete(primarycolor,secondarycolor,darktheme)
		local h,s = ColorToHSL(primarycolor)
		primarycolor = HSLToColor(h,s,.48)
		if secondarycolor then
			local h,s = ColorToHSL(secondarycolor)
			secondarycolor = HSLToColor(h,s,.48)
		else
			secondarycolor = primarycolor
		end
		local T = {}
			T.DarkTheme = darktheme and true or false
		if not darktheme then
			T["50"] = lighten(primarycolor,.52)
			T["100"] = lighten(primarycolor,.37)
			T["200"] = lighten(primarycolor,.26)
			T["300"] = lighten(primarycolor,.12)
			T["400"] = lighten(primarycolor,.06)
			T["500"] = primarycolor
			T["600"] = lighten(primarycolor,-.09)
			T["700"] = lighten(primarycolor,-.18)
			T["800"] = lighten(primarycolor,-.28)
			T["900"] = lighten(primarycolor,-.34)
			T["A100"] = lighten(secondarycolor,.52)
			T["A200"] = lighten(secondarycolor,.37)
			T["A400"] = lighten(secondarycolor,.06)
			T["A500"] = secondarycolor
			T["A700"] = lighten(secondarycolor,-.12)
		else
			T["50"] = lighten(primarycolor,-.405)	-- 850 (The background. This is dark in the dark theme)

			T["100"] = lighten(primarycolor,-.30)
			T["200"] = lighten(primarycolor,-.322)
			T["300"] = lighten(primarycolor,-.345)
			T["400"] = lighten(primarycolor,-.367)
			T["500"] = lighten(primarycolor,-.39) 	-- 800
			T["600"] = lighten(primarycolor,-.405)
			T["700"] = lighten(primarycolor,-.42)
			T["800"] = lighten(primarycolor,-.45)	-- A tiny bit of color
			T["900"] = Color(0,0,0)					--lighten(primarycolor,-.48) -- This is always black
			local b = -0.
			T["A100"] = lighten(secondarycolor,-.30 + b)
			T["A200"] = lighten(secondarycolor,-.33 + b)
			T["A400"] = lighten(secondarycolor,-.36 + b)
			T["A500"] = lighten(secondarycolor,-.39 + b)
			T["A700"] = lighten(secondarycolor,-.42 + b)
		end
		return T
	end
	local function GetDFrame(self)
		if not self then return "No self" end
		if self:GetName() == "DFrame" then return self end
		local parent = self:GetParent()
		if not parent then return nil end
		for i=1,10 do
			if parent:GetName() == "DFrame" then
				return parent
			else
				parent = parent:GetParent()
				if not parent then break end
			end
		end
	end
-- Sound
	local acceptsnd = "ui/buttonclick.wav"
	local rollsnd = "ui/buttonrollover.wav"
	local rejectsnd = "common/wpn_denyselect.wav"
	function mgui.AccpetSnd()
		playSnd(acceptsnd)
	end
	function mgui.RollSnd()
		playSnd(rollsnd)
	end
	function mgui.RejectSnd()
		playSnd(rejectsnd)
	end
-- mgui Create
	local function DarkDesignHelper(pallete,pn)
		if not pallete:IsDarkDesign() then return pn end
		if pn == "A700" then
			return "A100"
		end
		if pn == "A500" then
			return "A400"
		end
		if pn == "A400" then
			return "A400"
		end
		if pn == "A200" then
			return "A500"
		end
		if pn == "A100" then
			return "A700"
		end
		return pn
	end
	local defaultPallete = GeneratePallete(hex("#2196F3"),nil,false)
	local classes = {}
	local panelg = nil
	function mgui.Create(classname, parent, name)
		--vgui.CreateX = mgui.CreateX
		local p = nil
		if classes[classname] then
			p = classes[classname](parent,name)

			panelg = nil
		else
			p = vgui.Create(classname, parent, name)
		end
		if not IsValid(p) then print("ERROR") return end
		-- mgui global functions
			p._DFrame = GetDFrame(p)
			if not p._palletecolor then
				p._palletecolor = "50"
			end
			function p:AddEvent(name,func)
				if not events[name] then events[name] = {} end
				events[name][self] = func
			end
			function p:GetFrame(self)
				return self._DFrame
			end
			function p:GetParentPallete()
				if not self:GetParent() then return self._palletecolor or "50" end
				return self:GetParent()._palletecolor or "50"
			end
			function p:GetParentLuminance()
				local c = self:GetPallete(self:GetParentPallete())
				return ColorToLuminance(c)
			end
			function p:GetParentColor()
				return self:GetPallete(self:GetParentPallete())
			end
			function p:GetPallete(str)
				if type(str) == "number" then str = str .. "" end
				if not self._DFrame then return defaultPallete[str] end
				if not self._DFrame.pallete then return defaultPallete[str] end
				return self._DFrame.pallete[str]
			end
			function p:GetPalleteColor()
				local pallete = DarkDesignHelper(self,self._palletecolor or "50")
				return self:GetPallete(pallete)
			end
			function p:GetPalleteLuminance(str)
				local c = self:GetPallete(str or self._palletecolor or "50")
				return ColorToLuminance(c)
			end
			function p:IsDarkDesign()
				if not self._DFrame then return false end
				if not self._DFrame.pallete then return false end
				return self._DFrame.pallete.DarkTheme or false
			end
			function p:GetTextColor(col)
				local lum = nil
				if col then
					lum = ColorToLuminance(col)
				else
					lum = self:GetPalleteLuminance(col)
				end
				local a = 255
				if self.GetDisabled then
					a = self:GetDisabled() and 100 or 255
				end
				if lum < 145 then --155
					return Color(255,255,255,a)
				else
					return Color(0,0,0,a)
				end
			end
		return p
	end

--[[-------------------------------------------------------------------------
Color help
	- Bar = 700
	- Base_color = 500
	- Button = A200 (500 if its something to do with the window itself)

	- Error = HEX(#B00020)
	- Text is white or black. Depending on the lum behind

---------------------------------------------------------------------------]]
-- Classes
	classes["DFrame"] = function(parent,name)
		local p = vgui.Create("DFrame",parent,name)
			p.pallete = defaultPallete
			p:SetTitle("")
			p.text = "DFrame"
			p.font = "mgui_default"
			p.icon = nil
			function p:SetIcon(mat)
				p.icon = mat
			end
			function p:GetFont()
				return self.font
			end
			function p:SetFont(str)
				self.font = str or "mgui_default"
			end
			function p:SetTitle(str)
				self.text = str
			end
			function p:SetPallete(primary_color,secondary_color,darktheme)
				if not primary_color then
					primary_color = self.pallete["500"]
				end
				self.pallete = GeneratePallete(primary_color,secondary_color,darktheme)
			end
		function p:Paint(w,h)
			surface.SetDrawColor(self:GetPallete("50"))
			surface.DrawRect(0,0,w,h)
			if self:IsDarkDesign() then
				surface.SetDrawColor(self:GetPallete("700"))
				surface.DrawRect(0,0,w,24)
			else
				surface.SetDrawColor(self:GetPallete("700"))
				surface.DrawRect(0,0,w,24)
			end
			--if not self.text then return end
			surface.SetTextColor(self:GetTextColor(self:GetPallete("700")))
			surface.SetFont(self:GetFont())
			local text = self.text
				text = StormFox.Language.Translate(text)
			local tw,th = surface.GetTextSize(text)
			if self.icon then
				surface.SetTextPos(32,12 - th / 2)
				surface.SetDrawColor(255,255,255)
				surface.SetMaterial(self.icon)
				surface.DrawTexturedRect(6,2,20,20)
			else
				surface.SetTextPos(12,12 - th / 2)
			end
			surface.DrawText(text)
		end
		p:SetSize(ScrW() / 3, ScrH() / 3)
		return p
	end
	classes["Frame"] = classes["DFrame"]

	classes["Panel"] = function(parent,name)
		local p = vgui.Create("Panel",parent,name)
		function p:SetPallete(primary_color,secondary_color,darktheme)
			if not primary_color then
				primary_color = self.pallete["500"]
			end
			self.pallete = GeneratePallete(primary_color,secondary_color,darktheme)
		end
		function p:Paint(w,h)
			surface.SetDrawColor(self:GetPallete("50"))
			surface.DrawRect(0,0,w,h)
		end
		p:SetSize(ScrW() / 3, ScrH() / 3)
		return p
	end
	classes["DPanel"] = classes["Panel"]
	
	classes["DButton"] = function(parent,name)
		local panel = vgui.Create("DButton",parent,name)
		panel:SetText("")
		panel:SetSize(60,24)
		panel.text = "Button"
		panel.icon = nil
		panel.textalign = 1
		panel.bgenabled = true
		panel.roundcornor = 1
		function panel:DisableBackground(b)
			self.bgenabled = not b
		end
		panel._palletecolor = "A500"
		panel:SetFont("mgui_default")
		pressAble(panel)
		function panel:SetTextAlingn(n)
			self.textalign = n or 1
		end
		function panel:SetText(text) self.text = text end
		function panel:Paint(w,h)
			if self.bgenabled then
				self._palletecolor = DarkDesignHelper(self,"A500")
				local c
				if self:GetDisabled() then
					local _h,s,l = ColorToHSL(self:GetPalleteColor())
						c = HSLToColor(_h,0,l)
						c.a = 96.9
					surface.SetDrawColor(c) --96.9
					RoundedBox(0,0,w,h,self.roundcornor)
				else
					surface.SetDrawColor(self:GetPalleteColor())
					RoundedBox(0,0,w,h,self.roundcornor)
				end
			end
			if self.text then
				local text = self.text
				if StormFox.Language.Translate then
					text = StormFox.Language.Translate(text)
				end
				if self:GetDisabled() then
					local parent = self:GetParent()
					if parent.GetPalleteColor then
						local cc = parent:GetPalleteColor()
						local c = self:GetTextColor(cc)
						surface.SetTextColor(Color(c.r,c.g,c.b,100))
					else
						surface.SetTextColor(Color(155,155,155,100))
					end

				elseif not self.bgenabled then
					local cc = self:GetParentColor()
					local c = self:GetTextColor(cc)
					surface.SetTextColor(Color(c.r,c.g,c.b,255))
				else
					surface.SetTextColor(self:GetTextColor())
				end
				surface.SetFont(self:GetFont())
				local tw,th = surface.GetTextSize(text)
				if self.textalign == 0 then
					surface.SetTextPos(10,h / 2 - th / 2)
				elseif self.textalign == 2 then
					surface.SetTextPos(w - 10 - tw,h / 2 - th / 2)
				else
					surface.SetTextPos(w / 2 - tw / 2,h / 2 - th / 2)
				end
				surface.DrawText(text)
			end
			RenderRing(self)
		end
		function panel:OnReleased()
			playSnd(acceptsnd)
		end
		return panel
	end
	classes["Button"] = classes["DButton"]

	classes["Switch"] = function(parent,name)
		local panel = vgui.Create("DPanel",parent)
		panel.button = vgui.Create("DButton",panel)
		panel.button:SetSize(20,20)
		panel.button.panel = panel
		panel.button:SetText("")
		panel.button.t = false
		panel.button.s = 0
		panel.button.shake = 0
		panel._palletecolor = "A500"

		panel:SetSize(36,20)
		panel.state = false
		panel.SetSetting = setsetting
		function panel:Paint(w,h)
			self._palletecolor = DarkDesignHelper(self,"A500")
			local c
			if self:GetDisabled() then
				local _h,s,l = ColorToHSL(self:GetPalleteColor())
					c = HSLToColor(_h,0,l)
					c.a = 96.9
			elseif self.state and not self.button.m_AnimQueue   then
				local cc = self:GetPalleteColor()
				c = Color(cc.r,cc.g,cc.b,255)
			else
				local _h,s,l = ColorToHSL(self:GetPalleteColor())
					c = HSLToColor(_h,0,l)
					c.a = 96.9
			end
			surface.SetDrawColor(c)
			circleBox( 2, 2, w - 4, h - 4 )
			--draw.RoundedBox(10,2,2,w - 4,h - 4,c)
		end
		function panel.button:Paint(w,h)
			local c = self.panel:GetPallete(DarkDesignHelper(self.panel,"A700"))
			if not self.panel.state and not self.panel.disabled then
				if self.panel:IsDarkDesign() then
					c = self.panel:GetPallete("A200")
				else
					c = self.panel:GetPallete(DarkDesignHelper(self.panel,"A100"))
				end
			end
			if self.panel.disabled then
				c = deemphasized(c)
			end
			local x,y = 0,0
			if self.shake > CurTime() then
				local a = CurTime()
				x = cos(a * 100)
			end
			surface.SetDrawColor(Color(0,0,0,55))
			Circle(x + w/2 + 0.1,y + h/2 + 0.9,w / 2 + 1,30)
			surface.SetDrawColor(c)
			Circle(x + w/2,h/2,y + w / 2,30)
			if self:IsHovered() and not self.panel.disabled then
				surface.SetDrawColor(deemphasized(panel:GetTextColor(c),16))
				Circle(x + w/2,h/2,y + w / 2,30)
			end
		end
		function panel.button:Think()
			if self.t == self.panel.state then return end
			self.t = self.panel.state
			local x,y = self.panel:GetPos()
			local ex = self.t and 16 or 0
			self:MoveTo(ex,0,0.2,0,-1)
		end
		function panel.button:DoClick()
			self.panel:Toggle()
		end
		function panel:SetDisabled(b)
			self.disabled = b
		end
		function panel:GetDisabled()
			return self.disabled
		end
		function panel:GetState()
			return self.state
		end
		function panel:Toggle(b)
			if self:GetDisabled() then
				self.button.shake = CurTime() + 0.5
				playSnd(rejectsnd)
				return false
			end
			if b==nil then b = not self.state end
			self.state = b
			playSnd(acceptsnd)
			if self.DoClick then
				self:DoClick()
			end
			return true
		end
		return panel
	end

	classes["Slider"] = function(parent,name)
		local p = vgui.Create("DButton",parent,name)
			p.decimals = 1
			p:SetFont("mgui_default")
			p:SetText("")
			p.var = 70
			p.svar = 0
			p.min = 0
			p.max = 100
			p.show_number = true
			p.icon = nil
			p._s = 0
			p._palletecolor = parent._palletecolor or "500"
			function p:SetValue(n)	self.var = n	end
			function p:SetMax(n)	self.max = n	end
			function p:SetMin(n)	self.min = n	end
			function p:SetDecimals(n)	self.decimals = n	end
			function p:SetIcon(mat) 
				self.icon = mat 
			end
			local function getProcent(self)
				return (self.svar - self.min) / (self.max - self.min)
			end
			local function fromProcent(self,pro)
				return (pro * (self.max - self.min)) + self.min
			end

			function p:Paint(w,h)
				if self:IsDarkDesign() then
					self._palletecolor = "A100"
				else
					self._palletecolor = "A500"
				end
				if self.svar~=self.var then
					self.svar = lerp(max(0.1,abs(self.svar - self.var) * FrameTime() / 8) ,self.svar,self.var)
				end
				local bar_wide = w - 15
				if self.show_number then
					local c = self:GetParent()
					if c then
						surface.SetTextColor(self:GetTextColor(self:GetParentColor()))
					else
						surface.SetTextColor(self:GetTextColor())
					end
					surface.SetFont(self:GetFont())
					local t = self.var
					if self.TextEditor then
						t = self:TextEditor(t)
					end
					local tw,th = surface.GetTextSize(t)
					surface.SetTextPos(w - tw / 2  - 13,h / 2 - th/2)
					surface.DrawText(t)
					bar_wide = bar_wide - 26
				end
				-- bar
					local circle_xpos = bar_wide * getProcent(self)
					local p1 = self:GetPallete(self._palletecolor)
					local gab = 5
					if self:GetDisabled() then
						p1 = deemphasized(p1,100)
						gab = 8
					end
					-- Dis	
						local c = Color(p1.r,p1.g,p1.b, 100)
						surface.SetDrawColor(c)
						circleBox( 10 + gab + circle_xpos, h/2 - 1, bar_wide - circle_xpos - gab, 2 )
					-- Fill
						local c = Color(p1.r,p1.g,p1.b,255)
						surface.SetDrawColor(c)
						circleBox( 10, h/2 - 1, circle_xpos - gab, 2 )
					-- Button
						if self:GetDisabled() then
							Circle(10 + circle_xpos,h/2,4,30)
						else
							Circle(10 + circle_xpos,h/2,6,30)
							if self:IsDown() then
								self._s = min(self._s + FrameTime() * 5,1)
								local c = Color(p1.r,p1.g,p1.b,100 * self._s)
								surface.SetDrawColor(c)
								Circle(10 + circle_xpos,h/2,12 * self._s,38)
							else
								self._s = 0
							end
							if self:IsHovered() then
								surface.SetDrawColor(deemphasized(self:GetTextColor(),8))
								Circle(10 + circle_xpos,h/2,6,30)
							end
						end
				-- Hold
					if not self:IsDown() then return end
					local x,y = self:CursorPos()
					local holdPr = clamp((x - 10) / bar_wide,0,1)
					self.var = round(fromProcent(self,holdPr),self.decimals)
			end
			function p:OnReleased()
				playSnd(acceptsnd)
			end
			p:SetSize(140,20)
		return p
	end

	classes["CheckBox"] = function(parent,name)
		local panel = vgui.Create("DButton",parent,name)
		panel:SetText("")
		panel:SetSize(24,24)
		panel.state = false
		panel._palletecolor = "A500"
		panel:SetFont("mgui_default")
		function panel:Paint(w,h)
			if parent:IsDarkDesign() then
				panel._palletecolor = "A100"
			else
				panel._palletecolor = "A500"
			end
			local col = self:GetPalleteColor()
			if self:GetDisabled() then
				local _h,s,l = ColorToHSL(self:GetPalleteColor())
					c = HSLToColor(_h,0,l)
					c.a = 96.9
				col = c
			end
			surface.SetDrawColor(col)
			if self.state then
				RoundedBox(0,0,w,h,1.4)
				if self:GetDisabled() then
					local parent = self:GetParent()
					local cc = parent:GetPalleteColor()
					local c = self:GetTextColor(cc)
					c.a = 100
					draw.DrawText("✔","SkyFox-Console",w/2,1,c,1)
				else
					local c = self:GetTextColor()
					draw.DrawText("✔","SkyFox-Console",w/2,1,c,1)
				end
			else
				RoundedBoxOutline(0,0,w,h,1.4)
			end
		end
		function panel:OnReleased()
			if not self:IsHovered() then return end
			playSnd(acceptsnd)
			--self:Toggle()
		end
		function panel:Toggle(b)
			if b==nil then b = not self.state end
			self.state = b
		end
		return panel
	end

	classes["Label"] = function(parent,name)
		local panel = vgui.Create("DLabel",parent,name)
		panel:SetFont("mgui_default")
		panel.textalign = 0
		panel.text = "Label"
		panel:SetText("")
		panel.disabled = false
		function panel:SetDisabled(b)
			self.disabled = b
		end
		function panel:SetText(str)
			self.text = str
		end
		function panel:GetText()
			return self.text
		end
		function panel:SizeToContentsX( n )
			surface.SetFont(self:GetFont())
			local text = StormFox.Language.Translate(self.text) or self.text
			local tw,th = surface.GetTextSize(text)
			self:SetSize(tw + n,th)
		end
		function panel:SetTextAlingn(n)
			self.textalign = n or 1
		end
		function panel:Paint(w,h)
			local cc = self:GetParentColor()
			local c = self:GetTextColor(cc)
			surface.SetTextColor(Color(c.r,c.g,c.b,self.disabled and 100 or 255))
			surface.SetFont(self:GetFont())
			local t = self.text
			if StormFox.Language.Translate then
				t = StormFox.Language.Translate(t)
			end
			local tw,th = surface.GetTextSize(t)
			if self.textalign == 0 then
				local s = min((w - tw) / 2,2)
				surface.SetTextPos(s,h / 2 - th / 2)
			elseif self.textalign == 2 then
				local s = min((w - tw) / 2,2)
				surface.SetTextPos(w - s - tw,h / 2 - th / 2)
			else
				surface.SetTextPos(w / 2 - tw / 2,h / 2 - th / 2)
			end
			surface.DrawText(t)
		end

		return panel
	end
	classes["DLabel"] = classes["Label"]

	local s_keys = {47,48,49,50,51,52,56,57,58,59,60,62,65}
	classes["TextBox"] = function(parent,name)
		local p = mgui.Create( "Button" , parent)
			p._palletecolor = "A500"
			pressAble(p)
			p.le = 0
			p.n = true
			p.value = ""
			p.editing = false
			p.numeric = false
			function p:SetNumeric(b) self.numeric = b end
			function p:GetValue() return self.value end
			function p:SetValue(str) self.value = str end
			function p:IsEditing() return self.editing end
		-- Button support
			p.lastkey = -1
		function p:DoClick()
			self.editing = not self.editing
			if self.editing then
				input.StartKeyTrapping()
				self.lastkey = input.CheckKeyTrapping()
			end
		end
		function p:OnEdit()

		end
		function p:Think()
			if not self.editing then return end
			if not input.IsKeyTrapping() then
				input.StartKeyTrapping()
			end
			local ck = input.CheckKeyTrapping()
			if not ck then return end
			
			-- Keypad support
				if ck >= 37 and ck <= 46 then
					ck = ck - 36
				end
			-- Escape, Enter and mouse
			if ck == KEY_ESCAPE or ck == 51 or ck == 64 or ck == 107 then 
				self.editing = false
				if self.numeric then
					self.value = tonumber(self.value)
				end
				self:OnEdit()
				return 
			end
			if ck == 66 or ck == 73 then
				-- Delete
				self.value = string.sub(self.value or "",0,string.len(self.value or "") - 1)
				return
			elseif self.numeric then
				if ck > 10 then
					if string.len(self.value) > 0 then
						return
					elseif ck ~= 49 and ck ~= 62 then
						return
					end
				end
			elseif ck > 36 and not table.HasValue(s_keys,ck) then
				return
			end
			-- Special keys
			--if ck 
			local k = input.GetKeyName(ck)
			if ck == 48 then
				k = "*"
			elseif ck == 49 then
				k = "-"
			elseif ck == 50 then
				k = "+"
			end
			if self.CanAdd and k then
				local r = self:CanAdd(k)
				if not r then return end
				k = r
			end
			self.value = self.value .. k
		end
			
		function p:Paint(w,h)
			self._palletecolor = DarkDesignHelper(self,"A500")
			local c
			if self:GetDisabled() then
				local _h,s,l = ColorToHSL(self:GetPalleteColor())
					c = HSLToColor(_h,0,l)
					c.a = 96.9
				surface.SetDrawColor(c) --96.9
				RoundedBox(0,0,w,h,self.roundcornor)
			else
				surface.SetDrawColor(self:GetPalleteColor())
				RoundedBox(0,0,w,h,self.roundcornor)
			end
			if self:GetDisabled() then
				local parent = self:GetParent()
				if not parent.GetPalleteColor then -- No idea .. lets go a layer deeper
					if parent:GetParent().GetPalleteColor then
						local cc = parent:GetParent():GetPalleteColor()
						local c = self:GetTextColor(cc)
						surface.SetTextColor(Color(c.r,c.g,c.b,100))
					else
						-- No idea .. lets go with the lowest
						self:GetTextColor(self:GetPallete(str or self._palletecolor or "50"))
						surface.SetTextColor(Color(255,0,0,100))
					end
				else
					local cc = parent:GetPalleteColor()
					local c = self:GetPalleteLuminance(cc)
					surface.SetTextColor(Color(c.r,c.g,c.b,100))
				end
			else
				surface.SetTextColor(self:GetTextColor())
			end
			surface.SetFont(self:GetFont())
			local t = self:GetValue() or ""
			if StormFox.Language.Translate then
				t = StormFox.Language.Translate(t)
			end
			if self.TextEditor then
				local r = self:TextEditor(t)
				if r then t = r end
			end
			local tw,th = surface.GetTextSize(t)
			if self:IsEditing() and math.Round(CurTime()%1) == 0 then
				t = t .. "_"
			end
			surface.SetTextPos(w / 2 - tw / 2,h / 2 - th / 2)
			
			surface.DrawText(t)
			RenderRing(self)
		end
		return p
	end

	classes["DoubleSlider"] = function(parent,name)
		local p = vgui.Create("DButton",parent,name)
			p.decimals = 1
			p:SetFont("mgui_default")
			p:SetText("")
			p.var = 20
			p.var2 = 70
			p.svar = 0
			p.svar2 = 0
			p.min = 0
			p.max = 100
			p.show_number = true
			p._s = 0
			p.text_len = 36
			p._palletecolor = parent._palletecolor or "500"
			function p:SetValue(n)	self.var = n	end
			function p:SetValue2(n)	self.var2 = n	end
			function p:SetMax(n)	self.max = n	end
			function p:SetMin(n)	self.min = n	end
			function p:SetDecimals(n)	self.decimals = n	end
			function p:SetIcon(mat) 
				self.icon = mat 
			end
			local function getProcent(self)
				return (self.svar - self.min) / (self.max - self.min)
			end
			local function getProcent2(self)
				return (self.svar2 - self.min) / (self.max - self.min)
			end
			local function getNProcent(self)
				return (self.var - self.min) / (self.max - self.min)
			end
			local function getNProcent2(self)
				return (self.var2 - self.min) / (self.max - self.min)
			end
			local function fromProcent(self,pro)
				return (pro * (self.max - self.min)) + self.min
			end

			function p:Paint(w,h)
				if self:IsDarkDesign() then
					self._palletecolor = "A100"
				else
					self._palletecolor = "A500"
				end
				if self.svar~=self.var then
					self.svar = lerp(max(0.1,abs(self.svar - self.var) * FrameTime() / 8) ,self.svar,self.var)
				end
				if self.svar2~=self.var2 then
					self.svar2 = lerp(max(0.1,abs(self.svar2 - self.var2) * FrameTime() / 8) ,self.svar2,self.var2)
				end
				local bar_wide = w - 15
				

				if self.show_number then
					local c = self:GetParent()
					if c then
						surface.SetTextColor(self:GetTextColor(self:GetParentColor()))
					else
						surface.SetTextColor(self:GetTextColor())
					end
					surface.SetFont(self:GetFont())
					local t = self.var
					local t2 = self.var2
					if self.TextEditor then
						t = self:TextEditor(t)
						t2 = self:TextEditor(t2)
					end
					local tw,th = surface.GetTextSize(t)
					local tw2,th2 = surface.GetTextSize(t2)
					surface.SetTextPos(w - tw2 / 2  - self.text_len / 2,h / 2 - th2/2)
					surface.DrawText(t2)

					surface.SetTextPos(self.text_len / 2 - tw / 2,h / 2 - th/2)
					surface.DrawText(t)
					bar_wide = bar_wide - self.text_len * 2
				end
				-- bar
					local barstart = self.show_number and self.text_len or 10
					local circle_xpos = bar_wide * getNProcent(self)
					local circle_xpos2 = bar_wide * getNProcent2(self)
					local selected = 0
					if not self.selected and self:IsHovered() then
						local x,y = self:CursorPos()
						local holdPr = clamp((x - barstart) / bar_wide,0,1)
						local c_pos = barstart + circle_xpos + (circle_xpos2 - circle_xpos) / 2
						if x < circle_xpos + barstart or x < c_pos then
							selected = 1
						elseif x > circle_xpos2 + barstart or x > c_pos then
							selected = 2
						end
						if self:IsDown() then
							self.selected = selected
						end
					elseif self.selected then
						if self:IsDown() then
							selected = self.selected
						else
							self.selected = nil
						end
					end
					local p1 = self:GetPallete(self._palletecolor)
					local gab = 5
					if self:GetDisabled() then
						p1 = deemphasized(p1,100)
						gab = 8
					end
					-- Dis	
						local c = Color(p1.r,p1.g,p1.b, 100)
						surface.SetDrawColor(c)
						circleBox( barstart, h/2 - 1, circle_xpos - gab, 2 )
						circleBox( barstart + circle_xpos2 + gab, h/2 - 1, bar_wide - (circle_xpos2 + gab), 2 )
					-- Fill
						local c = Color(p1.r,p1.g,p1.b,255)
						surface.SetDrawColor(c)
						circleBox( barstart + circle_xpos + gab, h/2 - 1, circle_xpos2 - circle_xpos - gab * 2, 2 )
					-- Button
						if self:GetDisabled() then
							Circle(barstart + circle_xpos,h/2,4,30)
							Circle(barstart + circle_xpos2,h/2,4,30)
						else
							Circle(barstart + circle_xpos,h/2,6,30)
							Circle(barstart + circle_xpos2,h/2,6,30)
							if self:IsDown() then
								self._s = min(self._s + FrameTime() * 5,1)
								local c = Color(p1.r,p1.g,p1.b,100 * self._s)
								surface.SetDrawColor(c)
								if selected == 1 then
									Circle(barstart + circle_xpos,h/2,12 * self._s,38)
								elseif selected == 2 then
									Circle(barstart + circle_xpos2,h/2,12 * self._s,38)
								end
							else
								if selected == 1 then
									surface.SetDrawColor(deemphasized(self:GetTextColor(),8))
									Circle(barstart + circle_xpos,h/2,6,30)
								elseif selected == 2 then
									surface.SetDrawColor(deemphasized(self:GetTextColor(),8))
									Circle(barstart + circle_xpos2,h/2,6,30)
								end
								self._s = 0
							end
							
						end
				-- Hold
					if not self:IsDown() then return end
					local x,y = self:CursorPos()
					local holdPr = clamp((x - barstart) / bar_wide,0,1)
					if selected == 1 then
						self.var = math.min(round(fromProcent(self,holdPr),self.decimals),self.var2)
					elseif selected == 2 then
						self.var2 = math.max(round(fromProcent(self,holdPr),self.decimals),self.var)
					end
			end
			function p:OnReleased()
				playSnd(acceptsnd)
			end
			p:SetSize(140,20)
		return p
	end

	classes["DScrollPaneldis"] = function(parent,name)
		local p = mgui.Create("DPanel",parent,name)
			p.pnlCanvas = mgui.Create("DPanel",p)
			p.pnlCanvas.OnMousePressed = function( p, code ) p:GetParent():OnMousePressed( code ) end
			p.pnlCanvas:SetMouseInputEnabled( true )
			p.pnlCanvas.PerformLayout = function( pnl )
				p:PerformLayout()
				p:InvalidateParent()
			end
			p.VBar = mgui.Create( "DVScrollBar", p )
			p.VBar:Dock( RIGHT )

			p:SetPadding( 0 )
			p:SetMouseInputEnabled( true )

			-- This turns off the engine drawing
			p:SetPaintBackgroundEnabled( false )
			p:SetPaintBorderEnabled( false )
			p:SetPaintBackground( false )

		return p
	end