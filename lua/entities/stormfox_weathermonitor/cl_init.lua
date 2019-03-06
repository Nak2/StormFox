include("shared.lua")

function ENT:Initialize()

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
local matBase = Material("effects/splashwake1")
local matBeam = Material( "effects/lamp_beam" )

local cir = Material("vgui/circle")
local part = Material("effects/lamp_beam")
local cel,fer = Material("stormfox/symbols/Celsius.png"),Material("stormfox/symbols/Fahrenheit.png")
function ENT:Draw()
	self:DrawModel()
	if ( halo.RenderedEntity() == self ) then return end

	if not StormFox then return end
	if not StormFox.GetRealTime then return end
	if not StormFox.Weather then return end
	if not StormFox.Weather.GetIcon then return end

	local temp = round(StormFox.GetNetworkData("Temperature",20),1 )
	local wind = round(StormFox.GetNetworkData("Wind",0) , 2)
	local Gauge = round(StormFox.GetData("Gauge",0), 2)
	local _24clock = self:GetNWBool("24Clock",true)
	cam.Start3D2D(self:LocalToWorld(Vector(3.3,-10.4,24.6)),self:LocalToWorldAngles(Angle(0,90,90)),0.1)
		surface.SetDrawColor(55,55,255)
		surface.DrawRect(0,0,208,158)
		local w,h = 208,158

		surface.SetTextColor(255,255,255)
		surface.SetFont("SkyFox-Console_B")
		local text = StormFox.Weather.GetName()
		local text_length,text_height = surface.GetTextSize(text)
		surface.SetTextPos(w / 2 - text_length / 2,h / 4 - text_height)
		surface.DrawText(text)
		local text = _24clock and (temp .. "°C") or (StormFox.CelsiusToFahrenheit(temp) .. "°F")
		local text_length,text_height = surface.GetTextSize(text)
		surface.SetTextPos(w / 2 - text_length / 2 - 20,h / 4)
		surface.DrawText(text)

		surface.SetDrawColor(Color(255,255,255))
		surface.SetMaterial(StormFox.Weather:GetIcon())
		surface.DrawTexturedRect(w / 2 + text_length / 2 - text_height / 2,h / 4,text_height,text_height)

		--Gauge
		surface.SetFont("SkyFox-Console")
		surface.SetTextPos(w / 4 , h / 1.8)
		surface.DrawText(math.ceil(Gauge) .. "mm")

		surface.SetMaterial(cir)
		local size = 60
		local posx,posy = w / 2 + 24, h / 2
		surface.DrawTexturedRect(posx - size / 2, posy  - size / 2 + 20, size ,size)
		surface.SetDrawColor(55,55,255)
		surface.DrawTexturedRect(posx - size / 2 + 1, posy  - size / 2 + 21, size - 2 ,size - 2)
		local text = wind .. "m/s"
		if not _24clock then
			text = math.Round(wind * 2.236936) .. "mph"
		end
		local tw,th = surface.GetTextSize(text)
		surface.SetTextPos(posx - tw / 2, posy + th / 2)
		surface.DrawText(text)
		if wind > 0 then
			surface.SetDrawColor(255,255,0,55)
			surface.SetMaterial(part)
			local a = - self:GetAngles().y + StormFox.GetNetworkData("WindAngle",0)
			surface.DrawTexturedRectRotated(posx, posy + 20, size - 2 ,size - 2,a)
		end

	cam.End3D2D()
end
--[[
	local thunder = StormFox.GetData("Thunder",false)
	
	local wind = StormFox.GetData("Wind",0)
	local b,str = StormFox.GetBeaufort(wind)




]]