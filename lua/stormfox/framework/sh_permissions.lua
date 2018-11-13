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

CAMI.RegisterPrivilege{
	Name = "StormFox Changemap",
	MinAccess = "superadmin"
}
if CLIENT then
	concommand.Add("sf_map_change")
	return
end
local con = GetConVar("sf_enable_mapbrowser")
concommand.Add("sf_map_change",function(ply,_,args)
	CAMI.PlayerHasAccess(ply,"StormFox Changemap",function(b)
		if not b then ply:PrintMessage(HUD_PRINTTALK,"You don't have access to change the map.") return end
		if con and not con:GetBool() then
			ply:PrintMessage(HUD_PRINTTALK,"Mapchange is disabled on this server. (sf_enable_mapbrowser 0)")
			return
		end
		print("[StormFox] " .. (ply and ply:Nick() .. " is changing the map to" or "Changing map to") .. " " .. args[1] .. ".")
		RunConsoleCommand("changelevel",args[1])
	end)
end,nil,"Changes the map.")
function StormFox.CanEditWeather(ply,func,...)
	local argz = {...}
	CAMI.PlayerHasAccess(ply,"StormFox WeatherEdit",function(b)
		if not b then ply:PrintMessage(HUD_PRINTTALK,"You don't have access to weather settings.") return end
		func(unpack(argz))
	end)
end

function StormFox.CanEditMapSetting(ply,func,...)
	local argz = {...}
	CAMI.PlayerHasAccess(ply,"StormFox Settings",function(b)
		if not b then ply:PrintMessage(HUD_PRINTTALK,"You don't have access to server settings.") return end
		func(unpack(argz))
	end)
end

function StormFox.CanEditSetting(ply,con,var)
	CAMI.PlayerHasAccess(ply,"StormFox Settings",function(b)
		--print(ply,"a")
		if not b then ply:PrintMessage(HUD_PRINTTALK,"You don't have access to server settings.") return end
		--print("b")
		if not StormFox.convars[con] then ply:PrintMessage(HUD_PRINTTALK,"Non SF server setting.") return end
		--print("c",con,var)
		print("[StormFox] " .. ply:Nick() .. " (" .. ply:SteamID() .. ") changed " .. con .. " to " .. tostring(var))
		local conVar = GetConVar(con)
		if not conVar then ply:PrintMessage(HUD_PRINTTALK,"Unknown convar '" .. con .. "' (ERROR)") return end 
			ply:PrintMessage(HUD_PRINTTALK,"StormFox: " .. con .. " " .. var .. ".")
			conVar:SetString(var)
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