AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel( "models/props_debris/concrete_spawnplug001a.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
	self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
	self:SetSolid( SOLID_VPHYSICS )         -- Toolbox
	self:DrawShadow(false)
	self.RenderMode = 1
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
end


function ENT:Think()

end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * -14
	local a =  tr.HitNormal:Angle():Right():Angle()
		--a:RotateAroundAxis(Vector(0,1,0),90)
		a.y = math.random(360)
	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos + Vector(0,0,14.28) )
	ent:SetAngles(a)
	ent:Spawn()
	ent:Activate()

	return ent

end