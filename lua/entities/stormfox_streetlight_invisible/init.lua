AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )

	self.RenderMode = 1

	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetColor(Color(255,255,255))
	self.on = false
	self.lastT = SysTime() + 7
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( not tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 40

	local ent = ents.Create( ClassName )
	local ang = (ply:GetPos() - SpawnPos):Angle().y - 90
	ent:SetPos( SpawnPos )
	ent:SetAngles(Angle(0,ang,0))
	ent:Spawn()
	ent:Activate()
	return ent

end

function ENT:Think()
	if (self.lastT or 0) > SysTime() + 20 then
		self.lastT = 0
	end
	if (self.lastT or 0) > SysTime() then return end
		self.lastT = SysTime() + math.random(5,7)
	--local on = StormFox.GetDaylightAmount() <= 0.4
	local on = StormFox.GetData("MapLight",100) < 12
	local fon = self:GetNWBool("On",false)
	if not fon and on then
		self.on = true
		self:DrawShadow(false)
		self:SetNWBool("On",true)
		self:EmitSound("doors/door_metal_large_chamber_close1.wav",65,0.8)
	elseif fon and not on then
		self:SetNWBool("On",false)
		self.on = false
		self:DrawShadow(true)
		self:EmitSound("doors/door_metal_large_chamber_close1.wav",65,0.8)
		if self.flashlight then
			self.flashlight:Remove()
		end
	end
end
