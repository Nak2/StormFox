include("shared.lua")

function ENT:Initialize()

end

local cos,sin,rad = math.cos,math.sin,math.rad
local mat = Material("vgui/circle")
local mat2 = Material("vgui/dashed_line")
function ENT:Draw()
	self:DrawModel()
	if ( halo.RenderedEntity() == self ) then return end
	if not StormFox then return end
	if not StormFox.GetTime then return end

	local a = self:GetAngles()
	local t = StormFox.GetTime()
	local h = math.floor(t / 60) -- 0 - 24
	local m = t - h * 60 -- 0 - 60
	cam.Start3D2D(self:LocalToWorld(Vector(5.1,0,53.6)),self:LocalToWorldAngles(Angle(0,90,90)),0.1)
		surface.SetMaterial(mat)
		surface.SetDrawColor(0,0,0)
		surface.DrawTexturedRect(-10,-10,20,20)

		surface.SetMaterial(mat2)
		-- hour arm
		local ang = h * 30 + m / 2 + 90
		surface.DrawTexturedRectRotated(0,0,140,4,-ang)

		-- min arm
		local ang = m * 6 + 90
		surface.DrawTexturedRectRotated(0,0,200,4,-ang)
	cam.End3D2D()

	cam.Start3D2D(self:LocalToWorld(Vector(-5.4,0,53.6)),self:LocalToWorldAngles(Angle(0,270,90)),0.1)
		surface.SetMaterial(mat)
		surface.SetDrawColor(0,0,0)
		surface.DrawTexturedRect(-10,-10,20,20)

		surface.SetMaterial(mat2)
		-- hour arm
		local ang = h * 30 + m / 2 + 90
		surface.DrawTexturedRectRotated(0,0,140,4,-ang)

		-- min arm
		local ang = m * 6 + 90
		surface.DrawTexturedRectRotated(0,0,200,4,-ang)
	cam.End3D2D()
end