AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel( "models/props_phx/rt_screen.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
	self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
	self:SetSolid( SOLID_VPHYSICS )         -- Toolbox
	self:SetNWBool("Freedom",false)
	self._Freedom = false
	self:SetUseType( SIMPLE_USE )
	self:SetRenderMode(RENDERMODE_TRANSALPHA)

	self:SetKeyValue("fademindist", 2000)
	self:SetKeyValue("fademaxdist", 2000)
end
function ENT:Use()
	self._Freedom = not self._Freedom
	self:SetNWBool("Freedom",self._Freedom)
	self:EmitSound("buttons/button14.wav")
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( not tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 16

	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:SetAngles(Angle(0,ply:EyeAngles().y + 180,0))
	ent:Spawn()
	ent:Activate()

	return ent

end
