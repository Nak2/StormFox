include("shared.lua")

function ENT:Initialize()
	self.ClockBase = ClientsideModel("models/maxofs2d/hover_plate.mdl",RENDERGROUP_TRANSLUCENT)
	self.ClockBase:SetPos(self:LocalToWorld(Vector(0,0,-6.2)))
	self.ClockBase:SetAngles(self:GetAngles())
	self.ClockBase:SetParent(self)
	self.ClockBase:SetNoDraw(true)

--	self.Glass = ClientsideModel("models/props_c17/tv_monitor01_screen.mdl",RENDERGROUP_TRANSLUCENT)
--	self.Glass:SetPos(self:LocalToWorld(Vector(0,0,0)))
--	self.Glass:SetAngles(self:GetAngles())
--	self.Glass:SetParent(self)
--	self.Glass:SetNoDraw(true)
end

function ENT:OnRemove()
	SafeRemoveEntity(self.ClockBase)
end

surface.CreateFont( "SkyFox-DigitalClock", {
	font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 50,
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

local cos,sin,rad,round = math.cos,math.sin,math.rad,math.Round
local mat = Material("phoenix_storms/glass")
local matBase = Material("effects/splashwake1")
local matBeam = Material( "effects/lamp_beam" )
--local sf = Material("stormfox/SF.png")

local cel,fer = Material("stormfox/symbols/Celsius.png"),Material("stormfox/symbols/Fahrenheit.png")
function ENT:Draw()
	render.SetBlend(0.5)
	render.MaterialOverride(mat)
		self:DrawModel()
	render.MaterialOverride()
	render.SetBlend(1)
	if not IsValid(self.ClockBase) then
		self.ClockBase = ClientsideModel("models/maxofs2d/hover_plate.mdl",RENDERGROUP_TRANSLUCENT)
		self.ClockBase:SetParent(self)
		self.ClockBase:SetNoDraw(true)
	end
	self.ClockBase:DrawModel()
	if not IsValid(self.ClockBase:GetParent()) then
		self.ClockBase:SetParent(self)
		self.ClockBase:SetPos(self:LocalToWorld(Vector(0,0,-6.2)))
		self.ClockBase:SetAngles(self:GetAngles())
	end
--	self.Glass:DrawModel()

--	self.Glass:SetPos(self:LocalToWorld(Vector(-5,2,0)))

	if ( halo.RenderedEntity() == self ) then return end
	if not StormFox then return end
	if not StormFox.GetRealTime then return end
	if not StormFox.GetWeatherSymbol then return end

	local a = self:GetAngles()
	local f = math.random(78,80)
	local _24clock = self:GetNWBool("24Clock",true)
	local r = math.random(10)
	local col = Color(155 - r,155 - r,255)
	cam.Start3D2D(self:LocalToWorld(Vector(0,0,-4.6)),self:GetAngles(),0.1)
		surface.SetDrawColor(col)
		surface.SetMaterial(matBase)
		surface.DrawTexturedRectRotated(0,0,100,100,SysTime() * 10)
		surface.DrawTexturedRectRotated(0,0,100,100,SysTime() * -12)

		--surface.SetMaterial(sf)
		--surface.DrawTexturedRectRotated(0,0,50,50,0)
	cam.End3D2D()

	render.SetMaterial(matBeam)
	render.DrawBeam( self:LocalToWorld(Vector(0,0,-5)), self:LocalToWorld(Vector(0,0,5)), 18 - math.random(1), 0, 0.9, col )

	cam.Start3D2D(self:GetPos(),Angle(180,EyeAngles().y + 90,-a.p -90),0.07)
		if self:GetNWBool("showWeather",false) then
			surface.SetDrawColor(col)
			surface.SetMaterial(StormFox.GetWeatherSymbol())
			surface.SetTextColor(col)
			surface.SetFont("SkyFox-DigitalClock")
			local temp = round(StormFox.GetData("Temperature",20),1)
			local text_length = 0
			if _24clock then
				-- Cel
				text_length = surface.GetTextSize(temp)
				surface.SetTextPos(-text_length / 2,-30)
				surface.DrawText(temp)
				surface.DrawTexturedRect(-60,-60,40,40)
				surface.SetMaterial(cel)
			else
				-- Fer
				temp = StormFox.CelsiusToFahrenheit(temp)
				text_length = surface.GetTextSize(temp)
				surface.SetTextPos(-text_length / 2,-30)
				surface.DrawText(temp)
				surface.DrawTexturedRect(-60,-60,40,40)
				surface.SetMaterial(fer)
			end
			surface.DrawTexturedRect(text_length / 2 + 5,-20,30,30)
		else
			surface.SetTextColor(col)
			surface.SetFont("SkyFox-DigitalClock")
			local text = StormFox.GetRealTime(nil,not _24clock)
			local text_length = surface.GetTextSize(text)
			surface.SetTextPos(-text_length / 2,-30)
			surface.DrawText(text)
		end
	cam.End3D2D()
end