AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel( "models/props/de_tides/tides_streetlight.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )

	self.RenderMode = 1

	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetMaterial("stormfox/models/parklight_off")
	self.lastT = CurTime() + 7

	self:SetKeyValue("fademindist", 2100)
	self:SetKeyValue("fademaxdist", 2100)
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( not tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 80

	local ent = ents.Create( ClassName )
	local ang = (ply:GetPos() - SpawnPos):Angle().y
	ent:SetPos( SpawnPos )
	ent:SetAngles(Angle(0,ang,0))
	ent:Spawn()
	ent:Activate()
	return ent
end

function ENT:Think()
	if (self.lastT or 0) > CurTime() then return end
		self.lastT = CurTime() + math.random(5,7)
	--local on = StormFox.GetDaylightAmount() <= 0.4
	local on = StormFox.GetData("MapLight",100) < 20
	local mat = self:GetMaterial()
	if mat == "stormfox/models/parklight_off" and on then
		self:SetMaterial("")
		self:DrawShadow(false)
	elseif mat ~= "stormfox/models/parklight_off" and not on then
		self:DrawShadow(true)
		self:SetMaterial("stormfox/models/parklight_off")
	end
end
