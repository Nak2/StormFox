include("shared.lua")

function ENT:Initialize()

end


function ENT:Draw()
	self:DrawModel()

end

function ENT:Think()
	local dis = StormFox.DistToHeadSqr(self:GetPos())
	if not dis or dis > 9400 then return end
	local time,yawchange = self:GetAngleTime()
	StormFox.HUDMessage("Press E to set time to " .. time .. ( (yawchange > 20 or yawchange < -20) and " and change sun_yaw to " .. math.Round(self:GetAngles().y) or "" ) .. ".")
end

function ENT:DrawTranslucent()
	
end

