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
	self.t = 0
	self.tt = 0
	self:SetUseType( SIMPLE_USE )
	self:EmitSound("ambient/fire/mtov_flame2.wav")
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self.ignite_list = {}
	self:SetNWInt("on",1)
	self.on = true

	self:SetKeyValue("fademindist", 2800)
	self:SetKeyValue("fademaxdist", 2800)
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( not tr.Hit ) then return end

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

function ENT:SetOn(boolean)
	if self:IsOn() and boolean then return end
	table.Empty(self.ignite_list)
	self:SetNWInt("on",boolean and 1 or 0)
	self.on = boolean
	if boolean then
		self.SND:Play()
		self:EmitSound("ambient/fire/mtov_flame2.wav")
	else
		self.SND:Stop()
	end
end

function ENT:Use()
	if self:WaterLevel() < 1 and not self:IsOn() then
		self:SetOn(true)
	elseif self:IsOn() then
		self:SetOn(false)
	end
end

local function damageEnts(self)
	if self.tt  > SysTime() then return end
	self.tt = SysTime() + 0.1
	if #self.ignite_list < 1 then return end
	local TDI = DamageInfo()
		TDI:SetDamage(2)
		TDI:SetInflictor(self)
		TDI:SetDamageType(8)
		TDI:SetReportedPosition(self:GetPos())
		TDI:SetDamagePosition(self:GetPos())
		TDI:SetAttacker(self)
		TDI:SetDamageType( 8 )
	for _,ent in ipairs(self.ignite_list) do
		if IsValid(ent) and ent:GetPos():DistToSqr(self:GetPos()) < 900 then
			ent:TakeDamageInfo(TDI)
			if not ent:IsOnFire() and math.random(10) >= 9 then
				ent:Ignite(2,2)
			end
		end
	end
end

local function findEnts(self)
	if self.t > CurTime() then return end
	self.t = CurTime() + 1
	table.Empty(self.ignite_list)
	for _,ent in ipairs(ents.FindInSphere(self:GetPos(),30)) do
		if IsValid(ent) and ent:GetPos():DistToSqr(self:GetPos()) < 900 then
			if ent:GetMaxHealth() > 0 then
				table.insert(self.ignite_list,ent)
			elseif ent:GetClass() == "stormfox_campfire" and ent ~=self then
				ent:SetOn(true)
			end
		end
	end
end

function ENT:Think()
	if self:IsOn() then
		if self:WaterLevel() > 0 then
			self:SetOn(false)
		else
			findEnts(self)
			damageEnts(self)
			if self:IsOnFire() then
				self:Extinguish()
			end
		end
	elseif self:WaterLevel() < 1 then
		if self:IsOnFire() then -- Campfire is on fire .. lets turn it on
			self:Extinguish()
			self:SetOn(true)
		end
	end
end

function ENT:OnRemove()
	self.SND:Stop()
end