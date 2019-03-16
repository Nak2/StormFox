AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
	self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
	self:SetSolid( SOLID_VPHYSICS )         -- Toolbox

	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetUseType( SIMPLE_USE )
	self._24Clock = true
	self:SetNWBool("24Clock",true)
	self.t = SysTime() + 5
	self.w = false

	self:SetKeyValue("fademindist", 1000)
	self:SetKeyValue("fademaxdist", 1000)
end

function ENT:Think()
	if self.t > SysTime() then return end
	self.w = not self.w
	self:SetNWBool("showWeather",self.w)
	self.t = SysTime() + 5
end

function ENT:Use()
	self._24Clock = not self._24Clock
	self:SetNWBool("24Clock",self._24Clock)
	self:EmitSound("buttons/button14.wav")
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( not tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 16

	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:SetAngles(Angle(0,ply:EyeAngles().y,0))
	ent:Spawn()
	ent:Activate()

	return ent

end
