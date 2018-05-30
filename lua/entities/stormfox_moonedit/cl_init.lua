include("shared.lua")

function ENT:Initialize()

end


function ENT:Draw()
	self:DrawModel()
end

function ENT:OnRemove()
	moonAngG = nil
end
function ENT:Think()
	moonAngG = self:GetAngles()
	moonAngG.r = 0
end