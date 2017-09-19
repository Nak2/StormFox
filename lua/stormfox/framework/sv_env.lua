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

StormFox.env_sun = StormFox.env_sun or nil
StormFox.env_skypaint = StormFox.env_skypaint or nil
StormFox.env_fog_controller = StormFox.env_fog_controller or nil
StormFox.shadow_control = StormFox.shadow_control or nil
StormFox.env_tonemap_controller = StormFox.env_tonemap_controller or nil
StormFox.light_environment = StormFox.light_environment or nil



-- Scan/create mapentities
local function GetOrCreate( eEntClass )
	local tEnts = ents.FindByClass( eEntClass )
	local mapSupportConvar = GetConVar( "sf_disable_mapsupport" )
	if #tEnts > 0 then return tEnts[1] end
	if mapSupportConvar:GetBool() then return end -- Disabled mapsupport

	local ent = ents.Create( eEntClass )
	ent:Spawn();
	ent:Activate();
	print("[StormFox] Creating " .. eEntClass)
	return ent
end

local function printEntFoundStatus( bFound, sEntClass )
	local sStatus = bFound and "OK" or "Not Found"
	local cStatusColor = bFound and Color( 0, 255, 0 ) or Color( 255, 0, 0 )
	MsgC( "	", Color(255,255,255), sEntClass, " ", cStatusColor, sStatus, Color( 255, 255, 255), "\n" )
	StormFox.SetData( "has_" .. sEntClass, bFound )
end

-- Finds the ents on the map that stormfox uses and creates some of them if not found
local function FindEntities()
	print( "[StormFox] Scanning mapentities ..." )

	local tSunlist = ents.FindByClass("env_sun")
	if #tSunlist > 1 then -- What .. why?
		for i = 2, #tSunlist do
			SafeRemoveEntity( sunlist[ i ] )
		end
	end
	-- Attempt to find the ents we need
	StormFox.env_sun = StormFox.env_sun or tSunlist[ 1 ] or nil
	StormFox.env_tonemap_controller = StormFox.env_tonemap_controller or ents.FindByClass( "env_tonemap_controller" )[ 1 ] or nil
	StormFox.light_environment = StormFox.light_environment or ents.FindByClass( "light_environment" )[ 1 ] or nil
	StormFox.env_fog_controller = StormFox.env_fog_controller or GetOrCreate( "env_fog_controller" ) or nil
	StormFox.env_skypaint = StormFox.env_skypaint or GetOrCreate( "env_skypaint" ) or nil
	StormFox.shadow_control = StormFox.shadow_control or ents.FindByClass( "shadow_control" )[ 1 ] or nil

	printEntFoundStatus( StormFox.env_tonemap_controller, "env_tonemap_controller" )
	printEntFoundStatus( StormFox.light_environment, "light_environment" )
	printEntFoundStatus( StormFox.env_fog_controller, "env_fog_controller" )
	printEntFoundStatus( StormFox.env_sun, "env_sun" )
	printEntFoundStatus( StormFox.env_skypaint, "env_skypaint" )
	printEntFoundStatus( StormFox.shadow_control, "shadow_control" )
	hook.Call( "StormFox - PostEntityScan" )
end
hook.Add( "StormFox - PostEntity", "StormFox - FindEntities", FindEntities )

-- Get Entities
function StormFox.GetSkyPaint()
	return StormFox.env_skypaint
end

function StormFox.GetSun()
	return StormFox.env_sun
end

-- MapBloom
local nbloom
function StormFox.SetMapBloom(n)
	if nbloom and nbloom == n then
		return
	end
	nbloom = n
	if not IsValid(StormFox.env_tonemap_controller) then return end
	StormFox.env_tonemap_controller:Fire("SetBloomScale",n)
end
local nbloom
function StormFox.SetMapBloomAutoExposureMin(n)
	if nbloom and nbloom == n then
		return
	end
	nbloom = n
	if not IsValid(StormFox.env_tonemap_controller) then return end
	StormFox.env_tonemap_controller:Fire("SetAutoExposureMin",n)
end
local nbloom
function StormFox.SetMapBloomAutoExposureMax(n)
	if nbloom and nbloom == n then
		return
	end
	nbloom = n
	if not IsValid(StormFox.env_tonemap_controller) then return end
	StormFox.env_tonemap_controller:Fire("SetAutoExposureMax",n)
end


-- Shadow controls
function StormFox.SetShadowColor( cColor )
	if not StormFox.shadow_control then return end
	StormFox.shadow_control:SetKeyValue( "color", cColor.r .. " " .. cColor.g .. " " .. cColor.b )
end

function StormFox.SetShadowAngle( aShadowAng )
	if not StormFox.shadow_control then MsgN("no shadow control :(") return end
	MsgN("updating shadow")
	-- min 190 max 350
	local sAngleString = ( aShadowAng.p + 180 ) .. " " .. aShadowAng.y .. " " .. aShadowAng.r .. " "
	StormFox.shadow_control:Fire( "SetAngles" , sAngleString , 0 )
end

function StormFox.SetShadowDistance( dis )
	if not StormFox.shadow_control then return end
	StormFox.shadow_control:SetKeyValue( "SetDistance", dis )
end

function StormFox.SetShadowDisable( bool )
	if not StormFox.shadow_control then return end
	StormFox.shadow_control:SetKeyValue( "SetShadowsDisabled", bool and 1 or 0 )
end

-- Sun (w skypaint)
function StormFox.SetSunAngle( nSunPitch )
	if not nSunPitch then return end
	local env_sun = StormFox.GetSun()
	if not IsValid( env_sun ) then return end

	nSunPitch = (nSunPitch + 180) % 360 -- Make the angle point up at 90.
	if nSunPitch == 270 then nSunPitch = 271 end -- Somehow the sun gets disabled at this angle.

	local aSunAng = Angle( nSunPitch, StormFox.GetData( "SunMoonAngle", 0 ), 0 )
	local vSunForwardVec = aSunAng:Forward()
	env_sun:SetKeyValue( "sun_dir" ,  tostring( vSunForwardVec ) )

	if StormFox.env_skypaint then StormFox.env_skypaint:SetSunNormal( vSunForwardVec ) end
	StormFox.SetShadowAngle( aSunAng )

	return true, ang
end

local nold = -1
function StormFox.SetSunSize(n)
	if not StormFox.env_sun then return end
	if nold == n then return end
	nold = n
	StormFox.env_sun:SetKeyValue( "size", round(math.Clamp(n,0,100) ))
end

local nold = -1
function StormFox.SetSunOverlaySize(n)
	if not StormFox.env_sun then return end
	if nold == n then return end
	nold = n
	StormFox.env_sun:SetKeyValue( "overlaysize", round(math.Clamp(n,0,100)) )
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
	return StormFox.env_sun:GetInternalVariable( "m_vDirection" )
end

-- Maplight
local oldls = "-"
function StormFox.SetMapLight(light) -- 0-100
	if not IsValid(StormFox.light_environment) then
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
	StormFox.light_environment:Fire("FadeToPattern", s ,0)
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
