AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel( "models/props_lab/reciever01d.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
	self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
	self:SetSolid( SOLID_VPHYSICS )         -- Toolbox

	self:SetRenderMode(RENDERMODE_TRANSALPHA)

	if WireAddon then
		self.Outputs = Wire_CreateOutputs(self, {
			"Temperature",
			"Temperature_F",
			"Rain_gauge",
			"Wind",
			"WindAngle",
			"Thunder",
			"Clock_24 [STRING]",
			"Clock_12 [STRING]",
			"Clock_raw",
			"Weather [STRING]"
		})
		Wire_TriggerOutput(self, "Clock_raw", StormFox.GetTime(true))
		Wire_TriggerOutput(self, "Clock_24", StormFox.GetRealTime(nil))
		Wire_TriggerOutput(self, "Clock_12", StormFox.GetRealTime(nil,true))
		Wire_TriggerOutput(self, "Temperature", StormFox.GetData("Temperature",20))
		Wire_TriggerOutput(self, "Temperature_F", StormFox.CelsiusToFahrenheit(StormFox.GetData("Temperature",20)))
		Wire_TriggerOutput(self, "Rain_gauge", StormFox.GetData("Gauge",0))
		Wire_TriggerOutput(self, "Wind", StormFox.GetData("Wind",0))
		Wire_TriggerOutput(self, "WindAngle", StormFox.GetData("WindAngle",0))
		Wire_TriggerOutput(self, "Thunder", StormFox.GetData("Thunder",false) and 1 or 0)
		Wire_TriggerOutput(self, "Weather", StormFox.GetWeatherName())
	end
end

local function SetWire(self,data,value)
	if self.Outputs[data].Value != value then
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
	SetWire(self, "Temperature", StormFox.GetData("Temperature",20))
	SetWire(self, "Temperature_F", StormFox.CelsiusToFahrenheit(StormFox.GetData("Temperature",20)))
	SetWire(self, "Rain_gauge", StormFox.GetData("Gauge",0))
	SetWire(self, "Wind", StormFox.GetData("Wind",0))
	SetWire(self, "WindAngle", StormFox.GetData("WindAngle",0))
	SetWire(self, "Thunder", StormFox.GetData("Thunder",false) and 1 or 0)
	SetWire(self, "Weather", StormFox.GetWeatherName())
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 3

	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:SetAngles(Angle(0,ply:EyeAngles().y + 180,0))
	ent:Spawn()
	ent:Activate()

	return ent

end