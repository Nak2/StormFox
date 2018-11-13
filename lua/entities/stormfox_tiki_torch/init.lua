AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel( "models/sf_models/sf_torch.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )

	self.RenderMode = 1

	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetColor(Color(255,255,255))
	self.on = false
	self.lastT = SysTime() + 7

	self:SetKeyValue("fademindist", 2100)
	self:SetKeyValue("fademaxdist", 2100)
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 20

	local ent = ents.Create( ClassName )
	local ang = (ply:GetPos() - SpawnPos):Angle().y - 90
	ent:SetPos( SpawnPos )
	ent:SetAngles(Angle(0,math.random(360),0))
	ent:Spawn()
	ent:Activate()
	return ent

end

function ENT:Think()
	
end