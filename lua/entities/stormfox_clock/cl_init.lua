include("shared.lua")

function ENT:Initialize()

end

local mat = Material("vgui/circle")
local mat2 = Material("vgui/dashed_line")
local mat3 = Material("glass/offwndwb")
local mat4 = Material("stormfox/models/clock_material")
local sf = Material("stormfox/SF.png")
function ENT:Draw()

	render.MaterialOverrideByIndex( 0, mat3 )
	render.MaterialOverrideByIndex( 1, mat4 )
	self:DrawModel()
	render.MaterialOverrideByIndex( )
	if ( halo.RenderedEntity() == self ) then return end

	if not StormFox then return end
	if not StormFox.GetTime then return end

	local a = self:GetAngles()
	local t = StormFox.GetTime()
	local h = math.floor(t / 60) -- 0 - 24
	local m = t - h * 60 -- 0 - 60

	cam.Start3D2D(self:GetPos(),self:LocalToWorldAngles(Angle(0,90,90)),0.2)
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