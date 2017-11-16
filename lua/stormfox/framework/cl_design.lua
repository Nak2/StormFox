-- Fonts
	surface.CreateFont( "SkyFox-Console_B", {
		font = "Arial",
		extended = false,
		size = 30,
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
	surface.CreateFont( "SkyFox-Console", {
		font = "Arial",
		extended = false,
		size = 20,
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
	surface.CreateFont( "SkyFox-Console_Medium", {
		font = "Arial",
		extended = false,
		size = 16,
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
	surface.CreateFont( "SkyFox-Console_Small", {
		font = "Arial",
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
	surface.CreateFont( "SkyFox-Console_Tiny", {
		font = "Arial",
		extended = false,
		size = 12,
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

local clamp,min,max,abs,lerp,cos,sin,rad = math.Clamp,math.min,math.max,math.abs,Lerp,math.cos,math.sin,math.rad

local colors = {}
	colors[1] = Color(241,223,221,255)
	colors[2] = Color(78,85,93,255)
	colors[3] = Color(51,56,60)
	colors[4] = Color(47,50,55)

local function lerpColor(amount,c,c2)
	if amount == 0 then return c end
	if amount == 1 then return c2 end
	local r = lerp(amount,c.r,c2.r)
	local g = lerp(amount,c.g,c2.g)
	local b = lerp(amount,c.b,c2.b)
	local a = lerp(amount,c.a,c2.a)
	return Color(r,g,b,a)
end

-- Materials
local grad = Material("gui/gradient_up")
local noicon = Material("gui/noicon.png","noclamp")
local t_override = {}
	t_override["Frame"] = "DFrame"
	t_override["Button"] = "DButton"
	t_override["SmallButton"] = "DButton"
	t_override["Slider"] = "DButton"
	t_override["Toggle"] = "DButton"

local vgui_types = {}
local function CreateSFType(str,func,dtype)
	vgui_types[str] = {func,dtype}
end

local function DoSound(str,lvl,pitch,vol,channel)
	if not LocalPlayer() then return end
	LocalPlayer():EmitSound(str,lvl,pitch,vol,channel)
end

CreateSFType("Frame",function(panel)
	panel:SetSize(ScrW() / 3,ScrH() / 3)
	function panel.Paint(self,w,h)
		surface.SetDrawColor(colors[2])
		surface.DrawRect(0,0,w,h)
		surface.SetDrawColor(colors[4])
		surface.DrawRect(0,0,w,24)
	end
end,"DFrame")

local m_cir = Material("vgui/circle")
CreateSFType("Toggle",function(panel)
	panel:SetSize(40,22)
	panel:SetText("")
	panel.var = false
	panel.vvar = 0
	function panel:SetText() end
	function panel:SetToggle(bool)
		panel.var = bool == nil and not panel.var or bool
	end

	function panel.Paint(self,w,h)
		local tv = panel.var and 1 or 0
		local d = self:GetDisabled()
		if self.vvar ~= tv then
			local a = math.max(0.4,abs(self.vvar - tv) / 1.1)
			self.vvar = lerp(RealFrameTime() * a * 10,self.vvar,tv)
		end
		draw.NoTexture()
		if d then
			surface.SetDrawColor(colors[3])
		else
			surface.SetDrawColor(lerpColor(self.vvar,colors[3],Color(100,100,200)))
		end
		local poly = {}
		local corner = h / 2
		table.insert(poly,{x = corner,y = 0})
		table.insert(poly,{x = w - corner,y = 0})
		for i = 0,180,20 do
			table.insert(poly,{x = w - corner + cos(rad(i - 90)) * corner,y = corner + sin(rad(i - 90)) * corner})
		end
		table.insert(poly,{x = corner,y = h})
		for i = 0,180,20 do
			table.insert(poly,{x = corner + cos(rad(i + 90)) * corner,y = corner + sin(rad(i + 90)) * corner})
		end
		surface.DrawPoly(poly )
		surface.SetMaterial(m_cir)
		local size = h - 4
		local length = w - 4 - size
		surface.SetDrawColor(Color(0,0,0))
		surface.DrawTexturedRect(3 + length * self.vvar,3,size,size)
		surface.SetDrawColor(d and colors[2] or Color(255,255,255))
		surface.DrawTexturedRect(2 + length * self.vvar,2,size,size)
	--	surface.DrawTexturedRectUV(0,0,h / 2,h,0,0,0.5,1)
	--	surface.DrawTexturedRectUV(h / 2,0,w - h,h,0.5,0,0.5,1)
	--	surface.DrawTexturedRectUV(w - h / 2,0,h / 2,h,0.5,0,1,1)

	end
	function panel:OnClick() end
	function panel:DoClick()
		DoSound("garrysmod/ui_click.wav")
		panel:SetToggle()
		self:OnClick(self.var)
	end
end,"DButton")

CreateSFType("Button",function(panel)
	panel:SetText("")
	panel.text = "Button"
	panel:SetSize(120,22)
	panel.setdown = false
	function panel:SetDown(b)
		self.setdown = b
	end
	function panel:GetDown()
		return self.setdown
	end
	function panel:SetText(text)
		panel.text = text
	end
	function panel:Paint(w,h)
		if self:IsDown() or self.setdown then
			surface.SetDrawColor(colors[3])
		else
			surface.SetDrawColor(colors[2])
		end
		surface.DrawRect(0,0,w,h)
		surface.SetMaterial(grad)
		surface.SetDrawColor(colors[3])
		surface.DrawTexturedRect(0,0,w,h)
		surface.SetDrawColor(colors[4])
			surface.DrawLine(0,0,w,0)
			surface.DrawLine(0,0,0,h)
			surface.DrawLine(w - 1,0,w - 1,h)
			surface.DrawLine(w - 1,0,w - 1,h - 1)
		local col = Color(241,223,221)
		if self:IsDown() then
			col.a = 25
		end
		surface.SetTextColor(col)
		surface.SetFont("SkyFox-Console")
		local tw,th = surface.GetTextSize(self.text)
		surface.SetTextPos(w / 2 - tw / 2,h / 2 - th / 2)
		surface.DrawText(self.text)
	end
	function panel:DoClick()
		DoSound("garrysmod/ui_click.wav")
		self:OnClick()
	end
end,"DButton")

CreateSFType("SmallButton",function(panel)
	panel:SetText("")
	panel.text = "Button"
	panel:SetSize(60,12)
	function panel:SetText(text)
		panel.text = text
	end
	panel.setdown = false
	function panel:SetDown(b)
		self.setdown = b
	end
	function panel:GetDown()
		return self.setdown
	end
	function panel:DoClick()
		DoSound("garrysmod/ui_click.wav")
		self:OnClick()
	end
	function panel:Paint(w,h)
		if self:IsDown() or self.setdown then
			surface.SetDrawColor(colors[3])
		else
			surface.SetDrawColor(colors[2])
		end
		surface.DrawRect(0,0,w,h)
		surface.SetMaterial(grad)
		surface.SetDrawColor(colors[3])
		surface.DrawTexturedRect(0,0,w,h)
		surface.SetDrawColor(colors[4])
			surface.DrawLine(0,0,w,0)
			surface.DrawLine(0,0,0,h)
			surface.DrawLine(w - 1,0,w - 1,h)
			surface.DrawLine(w - 1,0,w - 1,h - 1)
		local col = Color(241,223,221)
		if self:IsDown() then
			col.a = 25
		end
		surface.SetTextColor(col)
		surface.SetFont("SkyFox-Console_Small")
		local tw,th = surface.GetTextSize(self.text)
		surface.SetTextPos(w / 2 - tw / 2,h / 2 - th / 2)
		surface.DrawText(self.text)
	end
end,"DButton")

CreateSFType("Slider",function(panel)
		panel:SetText("")
		panel.var = 0
		panel.svar = 0
		panel:SetSize(140,14)
		panel.min = 0
		panel.max = 1
	function panel:Paint(w,h)
		local d = self:GetDisabled()
		if self.svar ~= self.var then
			local a = abs(self.svar - self.var)
			self.svar = lerp(min(a / 2,2) * RealFrameTime() * 100,self.svar,self.var)
		end
		if self.max < 1 then
			surface.SetDrawColor(255,255,255,255)
			surface.SetMaterial(noicon)
			local pos = w * 0.05 + w * 0.9 * self.max
			local l = w - pos
			surface.DrawTexturedRectUV(pos,0,l,h,0,0,l / h,1)
		end
		if self.min > 0 then
			surface.SetDrawColor(255,255,255,255)
			surface.SetMaterial(noicon)
			local pos = w * 0.05 + w * 0.9 * self.min
			local l = w - pos
			surface.DrawTexturedRectUV(0,0,pos,h,0,0,pos / h,1)
		end
		surface.SetDrawColor(Color(255,255,255,5))
		surface.DrawRect(0,0,w,h)
		surface.SetDrawColor(colors[3])
		surface.DrawRect(w * 0.05,h / 2 - 1,w * 0.9,2)

		surface.SetDrawColor(d and colors[3] or colors[1])
		surface.DrawRect(w * 0.05,h / 2 - 1,w * 0.9 * self.svar,2)

		surface.DrawRect(w * 0.05 + w * 0.9 * self.svar,0,2,h)
		self.first_pos = w * 0.05 + w * 0.9 * self.svar
	end
	function panel:SetMin(n)
		self.min = n
		if self.var < self.min then
			self.var = self.min
		end
	end
	function panel:SetMax(n)
		self.max = n
		if self.var > self.max then
			self.var = self.max
		end
	end
	function panel:OnChange()
	end
	function panel:DoClick()
		local w = self:GetSize()
		local x = self:CursorPos()
		local percent = clamp((x - w * 0.05) / (w * 0.9),0,1) -- w * 0.9
		self.var = clamp(percent,self.min,self.max)
		DoSound("garrysmod/ui_click.wav")
		self:OnChange(self.var)
	end
	function panel:SetVar(n)
		self.var = n
		self.svar = n
	end
	function panel:GetVar()
		return self.var or 0
	end
end,"DButton")

CreateSFType("TwoSlider",function(panel)
		panel:SetText("")
		panel.var = 0
		panel.svar = 0
		panel.var2 = 0
		panel.svar2 = 0
		panel:SetSize(140,14)
		panel.min = 0
		panel.max = 1
		panel.selectedside = 0
	function panel:Paint(w,h)
		local d = self:GetDisabled()
		if self.svar ~= self.var then
			local a = abs(self.svar - self.var)
			self.svar = lerp(min(a / 1.4,8) * RealFrameTime() * 100,self.svar,self.var)
		end
		if self.svar2 ~= self.var2 then
			local a = abs(self.svar2 - self.var2)
			self.svar2 = lerp(min(a / 1.4,8) * RealFrameTime() * 100,self.svar2,self.var2)
		end
		if self.max < 1 then
			surface.SetDrawColor(255,255,255,255)
			surface.SetMaterial(noicon)
			local pos = w * 0.05 + w * 0.9 * self.max
			local l = w - pos
			surface.DrawTexturedRectUV(pos,0,l,h,0,0,l / h,1)
		end
		if self.min > 0 then
			surface.SetDrawColor(255,255,255,255)
			surface.SetMaterial(noicon)
			local pos = w * 0.05 + w * 0.9 * self.min
			local l = w - pos
			surface.DrawTexturedRectUV(0,0,pos,h,0,0,pos / h,1)
		end
		surface.SetDrawColor(Color(255,255,255,5))
		surface.DrawRect(0,0,w,h)
		surface.SetDrawColor(colors[3])
		surface.DrawRect(w * 0.05,h / 2 - 1,w * 0.9,2)

		local first_pos,second_pos = w * 0.05 + w * 0.9 * self.svar,w * 0.05 + w * 0.9 * self.svar2
			self.first_pos = first_pos
			self.second_pos = second_pos
		local l = abs(first_pos - second_pos)
		surface.SetDrawColor(d and colors[3] or colors[1])
		surface.DrawRect(first_pos,h / 2,l,2)
		local s = 0
		if self:IsHovered() and not d then
			local w = self:GetSize()
			local x = self:CursorPos()
			local percent = clamp((x - w * 0.05) / (w * 0.9),0,1) -- w * 0.9
			surface.SetDrawColor(Color(155,155,255))
			local p_pos = w * 0.05 + w * 0.9 * percent
			if abs(percent - self.var) < abs(percent - self.var2) then
				s = 1
				local f,m = min(p_pos,first_pos),max(p_pos,first_pos)
				surface.DrawRect(f,h / 2,m - f,2)
			else
				s = 2
				local f,m = min(p_pos,second_pos),max(p_pos,second_pos)
				surface.DrawRect(f,h / 2,m - f,2)
			end
		end
		if s == 1 then
			surface.SetDrawColor(d and colors[3] or Color(155,155,255))
		else
			surface.SetDrawColor(d and colors[3] or colors[1])
		end
		surface.DrawRect(first_pos,0,2,h)
		if s == 2 then
			surface.SetDrawColor(d and colors[3] or Color(155,155,255))
		else
			surface.SetDrawColor(d and colors[3] or colors[1])
		end
		surface.DrawRect(second_pos - 1,0,2,h)
		self.selectedside = s
	end
	function panel:SetMin(n)
		self.min = n
		if self.var < self.min then
			self.var = self.min
		end
	end
	function panel:SetMax(n)
		self.max = n
		if self.var > self.max then
			self.var = self.max
		end
	end
	function panel:OnChange()
	end
	function panel:DoClick()
		local w = self:GetSize()
		local x = self:CursorPos()
		local percent = clamp((x - w * 0.05) / (w * 0.9),0,1) -- w * 0.9
		DoSound("garrysmod/ui_click.wav")
		if abs(percent - self.var) < abs(percent - self.var2) then
			self.var = clamp(percent,self.min,self.max)
			self:OnChange(self.var,1)
		else
			self.var2 = clamp(percent,self.min,self.max)
			self:OnChange(self.var2,2)
		end
	end
	function panel:SetVar(n)
		self.var = n
		self.svar = n
	end
	function panel:SetVar2(n)
		self.var2 = n
		self.svar2 = n
	end
	function panel:GetVar()
		return self.var or 0
	end
end,"DButton")

function StormFox.vguiCreate(str,parent,name)
	if not vgui_types[str] then return end
	local panel = vgui.Create(vgui_types[str][2] or str,parent,name)
	vgui_types[str][1](panel)
	return panel
end