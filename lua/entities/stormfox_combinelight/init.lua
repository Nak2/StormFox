AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel( "models/props_combine/combine_light001a.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )

	self.RenderMode = 1

	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetColor(Color(255,255,255))
	self.on = false
	self:SetMaterial("stormfox/models/combine_light_off")
	self.lastT = SysTime() + 7
	self:SetUseType(SIMPLE_USE )

	self:SetKeyValue("fademindist", 1500)
	self:SetKeyValue("fademaxdist", 1500)
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * -0.5

	local ent = ents.Create( ClassName )
	local ang = (ply:GetPos() - SpawnPos):Angle().y - 180
	ent:SetPos( SpawnPos )
	ent:SetAngles(Angle(0,ang,0))
	ent:Spawn()
	ent:Activate()
	return ent

end

function ENT:Think()
	if (self.lastT or 0) > SysTime() + 20 then
		self.lastT = 0
	end
	if (self.lastT or 0) > SysTime() then return end
		self.lastT = SysTime() + math.random(5,7)
	--local on = StormFox.GetDaylightAmount() <= 0.4
	local on = StormFox.GetData("MapLight",100) < 20
	if self:GetMaterial() == "stormfox/models/combine_light_off" and on then
		self.on = true
		self:SetMaterial("")
		self:DrawShadow(false)
	elseif self:GetMaterial() ~= "stormfox/models/combine_light_off" and not on then
		self.on = false
		self:DrawShadow(true)
		self:SetMaterial("stormfox/models/combine_light_off")
	end
end