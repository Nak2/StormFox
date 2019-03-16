AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel( "models/maxofs2d/cube_tool.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetUseType( ONOFF_USE )
	self:SetBodygroup( 1, 1 )
	self:SetMaterial( "stormfox/models/moon_edit" )
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( not tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 10
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = 0
	SpawnAng.y = SpawnAng.y + 180

	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:SetAngles( SpawnAng )
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:Think()
	moonAngG = self:GetAngles()
	moonAngG.r = 0
	--self:SetAngles(Angle(moonAngG.p,moonAngG.y,0))
end

function ENT:Use(ply)
	if not ply then return end
	if not IsValid(ply) then return end
	if self:IsPlayerHolding() then return end
end
