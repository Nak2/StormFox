AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel( "models/props_debris/concrete_chunk02b.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
	self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
	self:SetSolid( SOLID_VPHYSICS )         -- Toolbox

	self.RenderMode = 1
	self:DrawShadow(false)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetUseType( SIMPLE_USE )
	self.SND = CreateSound(self,"ambient/fire/fire_small1.wav")
	self.SND:Play()
	self:SetColor(Color(255,0,0)) -- I'm lazy
	self.t = 0
	self:SetUseType(SIMPLE_USE )
	self:EmitSound("ambient/fire/mtov_flame2.wav")
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self.ignite_list = {}
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 6.2

	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:SetAngles(Angle(0,ply:EyeAngles().y,0))
	ent:Spawn()
	ent:Activate()
	local pys = ent:GetPhysicsObject()
	if IsValid(pys) then
		pys:EnableMotion(false)
	end
	return ent
end

function ENT:Use()
	if self:WaterLevel() < 1 and self:GetColor().r ~= 255 then
		self:SetColor(Color(255,0,0))
		self.SND:Play()
		self:EmitSound("ambient/fire/mtov_flame2.wav")
	elseif self:GetColor().r ~= 254 then
		self:SetColor(Color(254,0,0))
		self.SND:Stop()
		table.Empty(self.ignite_list)
	end
end

local function igniteTick(self)
	if (self.tt or 0) > SysTime() then return end
	self.tt = SysTime() + 0.1
	local TDI = DamageInfo()
		TDI:SetDamage(2)
		TDI:SetInflictor(self)
		TDI:SetDamageType(8)
		TDI:SetReportedPosition(self:GetPos())
		TDI:SetDamagePosition(self:GetPos())
		TDI:SetAttacker(self)
	for _,ent in ipairs(self.ignite_list) do
		if IsValid(ent) and ent:GetMaxHealth() > 0 and ent:GetPos():DistToSqr(self:GetPos()) < 900 then
			ent:TakeDamageInfo(TDI)
		end
	end
end

function ENT:Think()
	igniteTick(self)
	if self.t > CurTime() then return end
		self.t = CurTime() + 1
	if self:WaterLevel() > 0 then -- Turn pff
		self:SetColor(Color(254,0,0))
		table.Empty(self.ignite_list)
		self.SND:Stop()
	end
	if self:GetColor().r <= 254 then return end -- Its off
	self.ignite_list = ents.FindInSphere(self:GetPos(),30)
end


function ENT:OnRemove()
	self.SND:Stop()
end