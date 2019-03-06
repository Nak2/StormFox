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
	self:SetKeyValue("fademindist", 2000)
	self:SetKeyValue("fademaxdist", 2000)
	self:SetNWInt("on",1)
	self:SetUseType( SIMPLE_USE )
	self.on = 1
	if WireAddon then
		self.Inputs = WireLib.CreateSpecialInputs(self, {"On","Red", "Green", "Blue", "RGB"}, {"NORMAL", "NORMAL", "NORMAL", "NORMAL", "VECTOR"})
		self.Outputs = Wire_CreateOutputs(self, {"IsBroken"})
	end
end

function ENT:TriggerInput(iname, value)
	if iname == "On" then
		self:SetOn(value ~= 0)
	elseif iname == "Red" then
		local c = self:GetColor()
		c.r = math.Clamp(value,0,255)
		self:SetColor(c)
	elseif iname == "Green" then
		local c = self:GetColor()
		c.g = math.Clamp(value,0,254)
		self:SetColor(c)
	elseif iname == "Blue" then
		local c = self:GetColor()
		c.b = math.Clamp(value,0,255)
		self:SetColor(c)
	elseif iname == "RGB" then
		local c = Color(math.Clamp(value[1],0,255), math.Clamp(value[2],0,254), math.Clamp(value[3],0,255))
		self:SetColor(c)
	end
end

function ENT:OnTakeDamage(cmd)
	if self.hp <= 0 then return end
	self.hp = (self.hp or 0) - cmd:GetDamage()
	if self.hp > 0 then	return end
	if WireAddon then
		Wire_TriggerOutput(self, "IsBroken", 1)
	end
	self:EmitSound("physics/glass/glass_largesheet_break1.wav")
	self:SetNWBool("broken",true)
	self.respawn = CurTime() + 30
	for i = 1,5 do
		local effectdata = EffectData()
		effectdata:SetOrigin( self:LocalToWorld(Vector(0,0,7)) )
		effectdata:SetNormal(self:GetAngles():Up())
		util.Effect("GlassImpact",effectdata)
	end
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( not tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 0.1

	local ent = ents.Create( ClassName )
	local ang = (ply:GetPos() - SpawnPos):Angle().y
	ent:SetPos( SpawnPos )
	ent:SetAngles(Angle(0,ang,0))
	ent:Spawn()
	ent:Activate()
	return ent

end

function ENT:SetOn(boolean)
	if self.on == boolean then return end
	self:SetNWInt("on",boolean and 1 or 0)
	self.on = boolean
end

function ENT:Use()
	if self:WaterLevel() < 1 and not self:IsOn() then
		self:SetOn(true)
	elseif self:IsOn() then
		self:SetOn(false)
	end
end

function ENT:Think()
	if self.respawn < 0 then return end
	if self.respawn > CurTime() then return end
	self.respawn = -1
	self.hp = 10
	self:SetNWBool("broken",false)
	if WireAddon then
		Wire_TriggerOutput(self, "IsBroken", 0)
	end
	--if math.random(1,1000)%100 <= 1 then
	--	self:EmitSound("vo/ravenholm/engage02.wav")
	--end
end