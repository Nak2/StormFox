
-- This requires us to override hook.Call
local con  = GetConVar("sf_debugcompatibility")
if not con or not con:GetBool() then return end
print("[STORMFOX] Debugcompatability enabled. Overriding the hook function.")
print("Set sh_debugcompatibility to 0 to disable this.")

_SF_OLDHOOKCALL = _SF_OLDHOOKCALL or hook.Call

-- Keep an eye on thise
local DontReturn = {}
	DontReturn["InitPostEntity"] = true -- Init protection
	DontReturn["HUDPaint"] = true -- Rain protection
	DontReturn["PostDrawTranslucentRenderables"] = true -- Rain render
	DontReturn["SetupSkyboxFog"] = true -- Fog
	DontReturn["SetupWorldFog"] = true -- Fog
	DontReturn["PostPlayerDraw"] = true -- Player effects
	DontReturn["StormFox.PostEntity"] = true -- Init protection
	DontReturn["StormFox.PostEntityScan"] = true -- Init protection

function StormFox.DebugHooks()
	return DontReturn
end

-- Trace the addon or source
local function TraceThatScriptDown(name, gm, ... )
	local a;
	for k, v in pairs( hook.GetTable()[name] or {} ) do
		if ( isstring( k ) ) then
			a, b, c, d, e, f = v( ... )
		elseif ( IsValid( k ) ) then
				a = v( k, ... )
		end
		if ( a != nil ) then
			return debug.getinfo(v)
		end
	end
end

-- Now for our own function
local call_result = {}
function hook.GetCallResult(str)
	return call_result[str]
end

-- Now lets edit hook.Call to support it
hook.Call = function( name, gm, ... )
	local a, b, c, d, e, f = _SF_OLDHOOKCALL(name,gm, ...)
	if ( a != nil ) then
		if DontReturn[name] then -- Should we care?
			local funcinfo = TraceThatScriptDown(name, gm, ... ) -- Check
			if funcinfo then
				call_result[name] = funcinfo
			end
		end
		return a, b, c, d, e, f
	end
end

if SERVER then
	util.AddNetworkString("StormFox - SendMessageBox")
	timer.Create("StormFox - Debugger",10,0,function()
		for hook_name,_ in pairs(StormFox.DebugHooks()) do
			local result = hook.GetCallResult(hook_name) or {}
			if result.short_src and result.short_src ~= "[C]" and not string.find(result.short_src,"/stormfox/") then
				-- This addon returns stuff ..
				print("[StormFox] WARNING! " .. result.short_src .. " is breaking all " .. hook_name .. "-hooks.")
				local pl = {}
				for _,ply in ipairs(player.GetAll()) do
					if ply:IsAdmin() or ply:IsSuperAdmin() then
						table.insert(pl,ply)
					end
				end
				net.Start("StormFox - SendMessageBox")
					net.WriteString("A mod is breaking hooks!")
					net.WriteString(result.short_src .. " is breaking StormFox and other mods by blocking " .. hook_name .. "-hooks.")
					net.WriteString("vo/eli_lab/eli_lookgordon.wav")
				net.Send(pl)
			end
		end
	end)
end