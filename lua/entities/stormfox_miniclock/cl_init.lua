include("shared.lua")

function ENT:Initialize()

end

local mat = Material("vgui/circle")
local mat2 = Material("vgui/dashed_line")
local mat3 = Material("stormfox/clock_mini_material")
function ENT:Draw()
	render.MaterialOverrideByIndex( 0, mat3 )
	self:DrawModel()
	render.MaterialOverrideByIndex( )

	if ( halo.RenderedEntity() == self ) then return end

	if not StormFox then return end
	if not StormFox.GetTime then return end

	local t = StormFox.GetTime()
	local h = math.floor(t / 60) -- 0 - 24
	local m = t - h * 60 -- 0 - 60

	cam.Start3D2D(self:LocalToWorld(Vector(-1,0,0.5)),self:LocalToWorldAngles(Angle(0,270,90)),0.1)
		surface.SetMaterial(mat)
		surface.SetDrawColor(0,0,0)
		surface.DrawTexturedRect(-2,-2,4,4)

		surface.SetMaterial(mat2)
		-- hour arm
		local ang = h * 30 + m / 2 + 90
		surface.DrawTexturedRectRotated(0,0,30,1,-ang)

		-- min arm
		local ang = m * 6 + 90
		surface.DrawTexturedRectRotated(0,0,40,1,-ang)
	cam.End3D2D()
	cam.Start3D2D(self:LocalToWorld(Vector(1,0,0.5)),self:LocalToWorldAngles(Angle(0,90,90)),0.1)
		surface.SetMaterial(mat)
		surface.SetDrawColor(0,0,0)
		surface.DrawTexturedRect(-2,-2,4,4)

		surface.SetMaterial(mat2)
		-- hour arm
		local ang = h * 30 + m / 2 + 90
		surface.DrawTexturedRectRotated(0,0,30,1,-ang)

		-- min arm
		local ang = m * 6 + 90
		surface.DrawTexturedRectRotated(0,0,40,1,-ang)
	cam.End3D2D()
end