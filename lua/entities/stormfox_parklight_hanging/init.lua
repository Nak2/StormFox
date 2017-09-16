AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel( "models/props/de_tides/tides_light_fixture.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )

	self.RenderMode = 1

	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetColor(Color(255,255,255))
	self.on = false
	self.lastT = 7
end

ENT.Use = StormFox.MakeEntityPersistance

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 63

	local ent = ents.Create( ClassName )
	local ang = (ply:GetPos() - SpawnPos):Angle().y
	ent:SetPos( SpawnPos )
	ent:SetAngles(tr.HitNormal:Angle())
	ent:Spawn()
	ent:Activate()

	ply:PrintMessage( HUD_PRINTCENTER, "Press E to make persistent" )

	return ent

end

function ENT:Think()
	if (self.lastT or 0) > SysTime() + 20 then
		self.lastT = 0
	end
	if (self.lastT or 0) > SysTime() then return end
		self.lastT = SysTime() + math.random(5,7)
	--local on = StormFox.GetDaylightAmount() <= 0.4
	local on = StormFox.GetData("MapLight",100) < 20
	local r = self:GetColor().r
	if r ~= 254 and on then
		self.on = true
		self:SetColor(Color(254,254,254))
		self:DrawShadow(false)
	elseif r ~= 255 and not on then
		self.on = false
		self:DrawShadow(true)
		self:SetColor(Color(255,255,255))
	end
end