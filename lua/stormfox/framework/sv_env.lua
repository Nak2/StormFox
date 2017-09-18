--[[-------------------------------------------------------------------------
 	Handles mapentities and entity functions

 	Get entities
	 	StormFox.GetSkyPaint()	returns env_skypaint
	 	StormFox.GetSun()		returns env_sun

	Map Bloom
		StormFox.SetMapBloom(n)

	Shadow
		StormFox.SetShadowColor(col)
		StormFox.SetShadowAngle(ang,forceday)
		StormFox.SetShadowDistance(dis)
		StormFox.SetShadowDisable(bool)

	Sun
		StormFox.SetSunAngle(ang,setShadow,forceday)
		StormFox.SetSunSize(size [0-100])
		StormFox.SetSunOverlaySize(size [0-100])
		StormFox.SetSunColor(Color)
		StormFox.SetSunOverlayColor(Color)
		StormFox.DebugSun() -- Returns sun position

	Maplight
		StormFox.SetMapLight(0-100)

 ---------------------------------------------------------------------------]]
local round,clamp = math.Round,math.Clamp

-- Scan/create mapentities
	local function GetOrCreate(str)
		local l = ents.FindByClass(str)
		local con = GetConVar("sf_disable_mapsupport")
		if #l > 0 then return l[1] end
		if con:GetBool() then return end -- Disabled mapsupport
		local ent = ents.Create(str)
		ent:Spawn();
		ent:Activate();
		print("[StormFox] Creating " .. str)
		return ent
	end

	local env_sun = nil
	local env_skypaint = nil
	local env_fog_controller = nil
	local shadow_control = nil
	local env_tonemap_controller = nil
	local light_environment = nil

	local function p(d,s)
		if d then
			MsgC("	",Color(255,255,255),s," ",Color(0,255,0),"OK",Color(255,255,255),"\n")
			StormFox.SetData("has_" .. s,true)
		else
			MsgC("	",Color(255,255,255),s," ",Color(255,0,0),"Not found",Color(255,255,255),"\n")
			StormFox.SetData("has_" .. s,false)
		end
	end
	local function FindEntities()
		print("[StormFox] Scanning mapentities ...")
		local sunlist = ents.FindByClass("env_sun")
		if #sunlist > 1 then -- What .. why?
			for i = 2,#sunlist do
				sunlist[i]:Remove()
			end
		end
		env_sun = 				env_sun 			or sunlist[1] or nil
		env_tonemap_controller = env_tonemap_controller or ents.FindByClass("env_tonemap_controller")[1] or nil
		light_environment = 	light_environment 	or ents.FindByClass("light_environment")[1] or nil
		env_fog_controller = 	env_fog_controller 	or GetOrCreate("env_fog_controller") or nil
		env_skypaint = 			env_skypaint 		or GetOrCreate("env_skypaint") or nil
		shadow_control = 		shadow_control 		or ents.FindByClass("shadow_control")[1] or nil


		p(env_tonemap_controller,"env_tonemap_controller")
		p(light_environment,"light_environment")
		p(env_fog_controller,"env_fog_controller")
		p(env_sun,"env_sun")
		p(env_skypaint,"env_skypaint")
		p(shadow_control,"shadow_control")
		hook.Call("StormFox - PostEntityScan")
	end
hook.Add("StormFox - PostEntity","StormFox - FindEntities",FindEntities)

-- Get Entities
	function StormFox.GetSkyPaint()
		return env_skypaint
	end

	function StormFox.GetSun()
		return env_sun
	end

-- MapBloom
	local nbloom
	function StormFox.SetMapBloom(n)
		if nbloom and nbloom == n then
			return
		end
		nbloom = n
		if not IsValid(env_tonemap_controller) then return end
		env_tonemap_controller:Fire("SetBloomScale",n)
	end
	local nbloom
	function StormFox.SetMapBloomAutoExposureMin(n)
		if nbloom and nbloom == n then
			return
		end
		nbloom = n
		if not IsValid(env_tonemap_controller) then return end
		env_tonemap_controller:Fire("SetAutoExposureMin",n)
	end
	local nbloom
	function StormFox.SetMapBloomAutoExposureMax(n)
		if nbloom and nbloom == n then
			return
		end
		nbloom = n
		if not IsValid(env_tonemap_controller) then return end
		env_tonemap_controller:Fire("SetAutoExposureMax",n)
	end
	local nbloom2
	function StormFox.SetBlendTonemapScale(target,duration)
		local str = target.. " " ..duration
		if nbloom2 and nbloom2 == str then
			return
		end
		if not IsValid(env_tonemap_controller) then return end
		env_tonemap_controller:Fire("BlendTonemapScale",str)
	end
	local nscale
	function StormFox.SetTonemapScale(n,dur)
		if nscale and nscale == n then
			return
		end
		nscale = n
		if not IsValid(env_tonemap_controller) then return end
		env_tonemap_controller:Fire("SetTonemapScale","n "..(dur or 0))
	end

-- Shadow
	function StormFox.SetShadowColor(col)
		if not shadow_control then return end
		shadow_control:SetKeyValue( "color", col.r .. " " .. col.g .. " " .. col.b )
	end
	function StormFox.SetShadowAngle(ang,forceday)
		if not shadow_control then return end
		if ang.p < 180 and not forceday then -- night
			ang.p = ang.p + 180
		end
		if ang.p > 350 or ang.p < 90 then
			ang.p = 350
		end
		if ang.p < 190 then
			ang.p = 190
		end
		-- min 190 max 350
		local SAngle = (ang.p + 180) .. " " .. ang.y .. " " .. ang.r .. " "
		shadow_control:Fire( "SetAngles" , SAngle , 0 )
	end
	function StormFox.SetShadowDistance(dis)
		if !shadow_control then return end
		shadow_control:SetKeyValue( "SetDistance", dis )
	end
	function StormFox.SetShadowDisable(bool)
		if !shadow_control then return end
		local int = 0
		if bool then int = 1 end
		shadow_control:SetKeyValue( "SetShadowsDisabled", int )
	end

-- Sun (w skypaint)
	function StormFox.SetSunAngle(ang,setShadow,forceday)
		if not ang then return end
		local env_sun = StormFox.GetSun()
		if not IsValid(env_sun) then return end
		ang.p = (ang.p + 180) % 360 -- Make the angle point up at 90.
		if ang.p == 270 then ang.p = 271 end -- Somehow the sun gets disabled at this angle.
		env_sun:SetKeyValue( "sun_dir" ,  tostring( ang:Forward() ) )
		if env_skypaint then
			-- Best serverside .. with the sun vars and all
			env_skypaint:SetSunNormal(ang:Forward())
		end
		if setShadow then
			StormFox.SetShadowAngle(ang,forceday)
		end
		return true, ang
	end

	local nold = -1
	function StormFox.SetSunSize(n)
		if not env_sun then return end
		if nold == n then return end
		nold = n
		env_sun:SetKeyValue( "size", round(math.Clamp(n,0,100) ))
	end

	local nold = -1
	function StormFox.SetSunOverlaySize(n)
		if not env_sun then return end
		if nold == n then return end
		nold = n
		env_sun:SetKeyValue( "overlaysize", round(math.Clamp(n,0,100)) )
	end

	local nold
	function StormFox.SetSunColor(col)
		local env_sun = StormFox.GetSun()
		if not env_sun then return end
		if nold == col then return end
		nold = col
		env_sun:SetKeyValue( "suncolor", (col.r / 255) .. " " .. (col.g / 255) .. " " .. (col.b / 255) )
	end

	local nold
	function StormFox.SetSunOverlayColor(col)
		local env_sun = StormFox.GetSun()
		if not env_sun then return end
		if nold == col then return end
		nold = col
		env_sun:SetKeyValue( "overlaycolor", (col.r / 255) .. " " .. (col.g / 255) .. " " .. (col.b / 255) )
	end

	function StormFox.DebugSun()
		return env_sun:GetInternalVariable( "m_vDirection" )
	end

-- Maplight
	local oldls = "-"
	function StormFox.SetMapLight(light) -- 0-100
		if not IsValid(light_environment) then
			light = 15 + (light * 0.7)
			local s = string.char(97 + clamp(light / 4,0,25))
			if s == oldls then return end
			engine.LightStyle(0,s)
			oldls = s
			return
		end
		local s = string.char(97 + clamp(light / 4,0,25))
		if s == oldls then return end
		oldls = s
		light_environment:Fire("FadeToPattern", s ,0)
	end

-- Support for envcitys sky-entity
	hook.Add("StormFox - PostEntity","StormFox - StopWhiteBoxes",function()
		local skyCam = ents.FindByClass("sky_camera")[1] or nil
		if not IsValid(skyCam) then return end
		local tr = util.QuickTrace(skyCam:GetPos(),Vector(0,0,-1000))
		if not tr.Entity then return end
		if tr.Entity:GetClass() == "func_brush" and not tr.Entity:IsWorld() then
			SafeRemoveEntity(tr.Entity) -- just to be safe
		end
	end)
