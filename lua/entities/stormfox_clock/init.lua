AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel( "models/props_trainstation/trainstation_clock001.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
	self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
	self:SetSolid( SOLID_VPHYSICS )         -- Toolbox

	self.RenderMode = 1

	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetUseType( SIMPLE_USE )
	if WireAddon then
		self.Outputs = Wire_CreateOutputs(self, {
			"Clock_24 [STRING]",
			"Clock_12 [STRING]",
			"Clock_raw"
		})
		Wire_TriggerOutput(self, "Clock_raw", StormFox.GetTime(true))
		Wire_TriggerOutput(self, "Clock_24", StormFox.GetRealTime(nil))
		Wire_TriggerOutput(self, "Clock_12", StormFox.GetRealTime(nil,true))
	end

	self:SetKeyValue("fademindist", 1500)
	self:SetKeyValue("fademaxdist", 1500)
end

local function SetWire(self,data,value)
	if self.Outputs[data].Value ~= value then
		Wire_TriggerOutput(self, data, value)
	end
end

local l = 0
function ENT:Think()
	if not WireAddon then return end
	if l > SysTime() then return end
		l = SysTime() + 1
	SetWire(self, "Clock_raw", StormFox.GetTime(true))
	SetWire(self, "Clock_24", StormFox.GetRealTime(nil))
	SetWire(self, "Clock_12", StormFox.GetRealTime(nil,true))
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
