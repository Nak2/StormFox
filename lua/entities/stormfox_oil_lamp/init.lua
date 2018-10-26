AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel( "models/sf_models/sf_oil_lamp.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	--self:SetMoveType( MOVETYPE_NONE )

	self.RenderMode = 1

	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetColor(Color(255,255,255))
	self.on = false
	self.lastT = SysTime() + 7
	self.hp = 10
	self.respawn = -1
end

function ENT:OnTakeDamage(cmd)
	if self.hp <= 0 then return end
	self.hp = (self.hp or 0) - cmd:GetDamage()
	if self.hp > 0 then	return end
	self:EmitSound("physics/glass/glass_largesheet_break1.wav")
	self:SetNWBool("broken",true)
	self.respawn = CurTime() + 30
	for i=1,5 do
		local effectdata = EffectData()
		effectdata:SetOrigin( self:LocalToWorld(Vector(0,0,7)) )
		effectdata:SetNormal(self:GetAngles():Up())
	
		util.Effect("GlassImpact",effectdata)
	end
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 0.1

	local ent = ents.Create( ClassName )
	local ang = (ply:GetPos() - SpawnPos):Angle().y
	ent:SetPos( SpawnPos )
	ent:SetAngles(Angle(0,ang,0))
	ent:Spawn()
	ent:Activate()
	return ent

end

function ENT:Think()
	if self.respawn < 0 then return end
	if self.respawn > CurTime() then return end
	self.respawn = -1
	self.hp = 10
	self:SetNWBool("broken",false)
	--if math.random(1,1000)%100 <= 1 then
	--	self:EmitSound("vo/ravenholm/engage02.wav")
	--end
end