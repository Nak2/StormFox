include("shared.lua")

function ENT:Initialize()

end


function ENT:Draw()
	self:DrawModel()
end


local c_m = Material("vgui/circle")
local s_m = Material("stormfox/symbols/Sunny.png")

function ENT:DrawTranslucent()
	local eyeang = EyeAngles()
		eyeang:RotateAroundAxis(eyeang:Right(),90)
	local center = self:LocalToWorld(Vector(0,0,23))
	local t_color = StormFox.GetData("SkyTopColor") or Color(51,127.5,255)
	local m_light = StormFox.GetNetworkData("MapLightChar","a")
	local m_light_c = (string.byte(m_light) - 97) * 4 -- a - z

	-- Sky
		render.SetColorMaterial()
		render.DrawSphere(center,12.6,30,30,Color(t_color.r,t_color.g,t_color.b,105))

	local s_p = StormFox.GetSunAngle():Forward() * 8
	local m_p = StormFox.GetMoonAngle():Forward() * 8

	local ep = EyePos()
	local render_order = {}
	table.insert(render_order,{mat = {StormFox.Weather:GetIcon()},dis = ep:DistToSqr(center),pos = center})
	table.insert(render_order,{mat = {s_m},dis = ep:DistToSqr(center + s_p),pos = center + s_p,col = Color(155,255,0)})
	local mm = Material(StormFox.GetData("MoonTexture") or "stormfox/effects/moon.png")
	table.insert(render_order,{mat = {mm},dis = ep:DistToSqr(center + m_p),pos = center + m_p,rot = mr})
	
	table.SortByMember( render_order, "dis" )
	
	for k, v in ipairs( render_order ) do
		
		render.SetMaterial(v.mat[1])
		render.DrawSprite(v.pos,4,4,v.col or Color(255,255,255))
		if #v.mat > 1 then
			render.SetMaterial(v.mat[2])
			render.DrawSprite(v.pos,4,4,v.col or Color(255,255,255,55))
		end
	end
	--StormFox.GetMoonMaterial()}

end

function ENT:Think()

end