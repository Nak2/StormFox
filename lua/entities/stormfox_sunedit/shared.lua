ENT.Type = "anim"
ENT.Base = "base_anim"
 
ENT.PrintName= "Sun editor"
ENT.Author= "Nak"
ENT.Purpose		= "Point to the sky"
ENT.Instructions= "Place it somewhere and point"
ENT.Category		= "StormFox"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true

ENT.RenderGroup = RENDERGROUP_BOTH

local function AngleToTime(p,y)
	local time = 0
	local sy = math.AngleDifference(y,StormFox.GetSunMoonAngle())
	if sy > 90 or sy < -90 then
		-- reverse
		time = -4 * (p - 90)
	else
		time = 4 * (p - 90)
	end
	if time <0 then time = time + 1440 end
	return time,sy
end

function ENT:GetAngleTime(freedom_units)
	local a = self:GetAngles()
	local t,y = AngleToTime(a.p,a.y)
	if y > 90 or y < - 90 then y = 0 end
	return StormFox.GetRealTime(t,freedom_units),y
end