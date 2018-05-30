include("shared.lua")

function ENT:Initialize()

end


function ENT:Draw()
	self:DrawModel()

end

function ENT:Think()
	if not LocalPlayer() or not IsValid(LocalPlayer()) then return end
	if LocalPlayer():GetShootPos():DistToSqr(self:GetPos()) > 9400 then return end
	local time,yawchange = self:GetAngleTime()
	StormFox.HUDMessage("Press E to set time to " .. time .. ( (yawchange > 20 or yawchange < -20) and " and change sun_yaw to " .. math.Round(self:GetAngles().y) or "" ) .. ".")
end

function ENT:DrawTranslucent()
	
end

