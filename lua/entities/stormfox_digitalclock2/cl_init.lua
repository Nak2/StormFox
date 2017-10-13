include("shared.lua")

function ENT:Initialize()

end

surface.CreateFont( "SkyFox-DigitalClock2", {
	font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 40,
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
surface.CreateFont( "SkyFox-DigitalClock2-mini", {
	font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
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

local cos,sin,rad,round = math.cos,math.sin,math.rad,math.Round
--local sf = Material("stormfox/SF.png")
local scale = Vector( 1, 0.6, 1 )

local mat = Matrix()
	mat:Scale( scale )

local mat2 = Material("vgui/circle")
function ENT:Draw()
	self:EnableMatrix( "RenderMultiply", mat )
	render.SetColorModulation(1,1,1)
	self:DrawModel()

	if ( halo.RenderedEntity() == self ) then return end
	if not StormFox then return end
	if not StormFox.GetRealTime then return end
	if not StormFox.Weather then return end
	if not StormFox.Weather.GetIcon then return end

	cam.Start3D2D(self:LocalToWorld(Vector(1,-6.75,6.64)),self:LocalToWorldAngles(Angle(0,90,90)),0.07)
		surface.SetDrawColor(0,0,0)
		surface.DrawRect(0,0,193,40)

		local d = StormFox.GetTime() - StormFox.GetTime(true)
		local str = StormFox.GetRealTime(nil,self:GetNWBool("24Clock",false))
		if d <= 0 then
			str = string.Replace(str,":"," ")
		end
		draw.DrawText(str,"SkyFox-DigitalClock2",96.5,0,self:GetColor(),1)
		
	cam.End3D2D()
end