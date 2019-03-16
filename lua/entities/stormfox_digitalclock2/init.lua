AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel( "models/maxofs2d/motion_sensor.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
	self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
	self:SetSolid( SOLID_VPHYSICS )         -- Toolbox

	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetUseType( SIMPLE_USE )
	self._24Clock = true
	self:SetNWBool("24Clock",true)
	self:SetColor(Color(255,0,0))
	self:SetMaterial("phoenix_storms/OfficeWindow_1-1")

	self:SetKeyValue("fademindist", 1000)
	self:SetKeyValue("fademaxdist", 1000)
end

function ENT:Use()
	self._24Clock = not self._24Clock
	self:SetNWBool("24Clock",self._24Clock)
	self:EmitSound("buttons/button14.wav")
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( not tr.Hit ) then return end

	local SpawnPos = tr.HitPos

	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:SetAngles(Angle(0,ply:EyeAngles().y + 180,0))
	ent:Spawn()
	ent:Activate()

	return ent

end
