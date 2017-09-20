include("stormfox/cami/sh_cami.lua")
if SERVER then AddCSLuaFile("stormfox/cami/sh_cami.lua") end
if not CAMI then return end
CAMI.RegisterPrivilege{
	Name = "StormFox Settings",
	MinAccess = "superadmin"
}

CAMI.RegisterPrivilege{
	Name = "StormFox WeatherEdit",
	MinAccess = "admin"
}
if CLIENT then return end

function StormFox.CanEditWeather(ply,func,...)
	local argz = {...}
	CAMI.PlayerHasAccess(ply,"StormFox WeatherEdit",function(b)
		if not b then ply:PrintMessage(HUD_PRINTCENTER,"You don't have access to weather settings.") return end
		func(unpack(argz))
	end)
end

function StormFox.CanEditSetting(ply,con,var)
	CAMI.PlayerHasAccess(ply,"StormFox Settings",function(b)
		--print(ply,"a")
		if not b then ply:PrintMessage(HUD_PRINTCENTER,"You don't have access to server settings.") return end
		--print("b")
		if not ConVarExists(con) then
			if con == "time_set" then
				if not string.find(var,":") then return end
				StormFox.SetTime(var)
			end
			return
		end
		--print("c",con,var)
		local con = GetConVar(con)
			con:SetString(var)
	end)
end

function StormFox.MakeEntityPersistance(ent,ply)
	if not ply then return end
	if ent:GetPersistent() then return end
	CAMI.PlayerHasAccess(ply,"StormFox Settings",function(b)
		if not b then return end
		ent:SetPersistent(true)
		ent:EmitSound("ambient/energy/zap" .. math.random(1,3) .. ".wav")
		local effect = EffectData()
		effect:SetOrigin( ent:GetPos() )
		effect:SetNormal( -ent:GetAngles():Up() )
		effect:SetStart( ent:GetPos() )
		effect:SetEntity( ent )
		effect:SetMagnitude( 5 )

		util.Effect( "TeslaHitBoxes", effect, true, true )
	end)
end