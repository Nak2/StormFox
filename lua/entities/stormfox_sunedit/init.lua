AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel( "models/maxofs2d/cube_tool.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetUseType( ONOFF_USE )
	self:SetBodygroup( 1, 1 )
	self:SetMaterial( "stormfox/models/sun_edit" )

	self:SetKeyValue("fademindist", 2000)
	self:SetKeyValue("fademaxdist", 2000)
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 10
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = 0
	SpawnAng.y = SpawnAng.y + 180

	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:SetAngles( SpawnAng )
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:Think()
	
end

function ENT:Use(ply)
	if not ply then return end
	if not IsValid(ply) then return end
	if self:IsPlayerHolding() then return end
	StormFox.CanEditWeather(ply,function()
		local t,yaw = self:GetAngleTime()
		StormFox.SetTime(t) 
		if yaw > 20 or yaw <-20 then
			RunConsoleCommand("sf_sunmoon_yaw",math.Round(self:GetAngles().y))
		end
	end)
end