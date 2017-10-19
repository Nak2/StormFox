
local function GetMoonAngle(time) -- Same as the sun .. tbh
	time = time or StormFox.GetTime()
	local pitch = ((time / 360) - 1) * 90
	if pitch < 0 then pitch = pitch + 360 end
	local n = 0
	if pitch > 180 then pitch = pitch - 180 n = 1 end
	local ang = Angle(pitch,StormFox.GetSunMoonAngle(), 0)
	return ang,n
end

local function ET(pos,pos2,mask)
	local t = util.TraceLine( {
		start = pos,
		endpos = pos + pos2,
		mask = mask or LocalPlayer(),
		filter = LocalPlayer():GetViewEntity() or LocalPlayer()
		} )
	t.HitPos = t.HitPos or (pos + pos2)
	return t
end
function findSky(pos1,pos2,mask)
	local skypos = nil
	local pos = pos1
	for i = 1,16 do
		local t = ET(pos,pos2 * 18000,mask)
		if t.HitSky then
			skypos = t.HitPos
		--	debugoverlay.Box(t.HitPos,Vector(-10,-10,-10),Vector(10,10,10),RealFrameTime(),Color( 0, 255, 0 ,255 ),true)
			break
		elseif t.Hit then
			pos = t.HitPos + pos2 * 10
		--	debugoverlay.Box(t.HitPos,Vector(-10,-10,-10),Vector(10,10,10),RealFrameTime(),Color( 255, 255, 255 ,1 ),true)
		else -- void

		end
	end
	return skypos
end
-- 
local max,min,abs = math.max,math.min,math.abs
local distance = 18000
hook.Add("RenderScene","StormFox - Suntest",function(eyepos,eyeang)
	if not LocalPlayer() then return end
	local con = GetConVar("sf_allow_dynamicshadow")
	local dla = StormFox.CalculateMapLight() / 100
	local thunder_light = StormFox.GetData("ThunderLight",0)
	if not con:GetBool() or (dla < 0.55 and dla > 0.45 and thunder_light <= 0) then
		if STORMFOX_SUN then
			STORMFOX_SUN:Remove()
		end
		if STORMFOX_SUN_distance then
			STORMFOX_SUN_distance:Remove()
		end
		return
	end

	local colA = abs(0.5 - dla) * 2
	-- Get angle
		local sunAngle
		if thunder_light > 10 then
			sunAngle = Angle(90,0,0)
		else
			sunAngle = GetMoonAngle()
		end
	-- Find skyhit
	local skypos = findSky(eyepos,-sunAngle:Forward(),MASK_SOLID_BRUSHONLY)
	if skypos then
		local d = max(skypos:Distance(eyepos) + 300,6000)
			distance = d
	end
	if not StormFox.Is3DSkybox() then
		distance = 4300 -- 2d map protection
	end
	local lppos,isday = eyepos + sunAngle:Forward() * -distance,dla > 0.5
	if not STORMFOX_SUN or not IsValid(STORMFOX_SUN) then
		--print("create")
		STORMFOX_SUN = ProjectedTexture()
		STORMFOX_SUN:SetPos(lppos)
		STORMFOX_SUN:SetAngles(sunAngle)

		STORMFOX_SUN:SetEnableShadows(true)

		STORMFOX_SUN:SetNearZ( 1200 )

		STORMFOX_SUN:SetFarZ( 14000 )
		STORMFOX_SUN:SetColor( Color(127.5 + 27.5 * colA,255,255 * colA) )

		STORMFOX_SUN:SetTexture("engine/depthwrite")
		STORMFOX_SUN:Update()
	end
	if not STORMFOX_SUN_distance or not IsValid(STORMFOX_SUN_distance)  then
		STORMFOX_SUN_distance = ProjectedTexture()
		STORMFOX_SUN_distance:SetPos(lppos)
		STORMFOX_SUN_distance:SetAngles(sunAngle)

		STORMFOX_SUN_distance:SetEnableShadows(true)

		STORMFOX_SUN_distance:SetNearZ( 1200 )
		STORMFOX_SUN_distance:SetFOV( 80 )

		STORMFOX_SUN_distance:SetFarZ( 4000 )
		STORMFOX_SUN_distance:SetColor( Color(127.5 + 27.5 * colA,255,255 * colA) )

		STORMFOX_SUN_distance:SetTexture("lights/white003_nochop")
		STORMFOX_SUN_distance:Update()
	end
	local tlight = 0
	STORMFOX_SUN:SetTexture("stormfox/small_shadow_sprite")
	local l = 500
	local f = StormFox.GetNetworkData("has_light_environment",false)
	if isday then
		local c = Color(127.5 + 127.5 * colA,255,255 * colA)
		STORMFOX_SUN:SetColor(c)
		STORMFOX_SUN_distance:SetColor(c)
		tlight = StormFox.GetData("SunSize",20) * 0.5
	else
		local c =  Color(63.5 + 63.5 * colA,155,255 * colA)
		STORMFOX_SUN:SetColor(c)
		STORMFOX_SUN_distance:SetColor(c)
		tlight = StormFox.GetData("MoonVisibility",100) * 0.05 - 2
	end
	if f then
		tlight = tlight * 4
	end
	STORMFOX_SUN:SetOrthographic(true,l,l,l,l)
	STORMFOX_SUN:SetFarZ( distance * 1.3 )

	STORMFOX_SUN:SetBrightness(max(tlight,thunder_light))
	STORMFOX_SUN:SetAngles(sunAngle)
	STORMFOX_SUN:SetPos(lppos)
	STORMFOX_SUN:Update()

	local l = 2000
	STORMFOX_SUN_distance:SetTexture("stormfox/shadow_sprite")
	STORMFOX_SUN_distance:SetOrthographic(true,l,l,l,l)
	STORMFOX_SUN_distance:SetFarZ( distance * 1.3  )
	STORMFOX_SUN_distance:SetBrightness(max(tlight,thunder_light))
	STORMFOX_SUN_distance:SetPos(lppos )
	STORMFOX_SUN_distance:SetAngles(sunAngle)

	STORMFOX_SUN_distance:Update()
end)