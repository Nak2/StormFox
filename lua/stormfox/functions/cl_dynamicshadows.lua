
-- Local Functions
	local function GetMoonAngle(time) -- Same as the sun .. tbh
		time = time or StormFox.GetTime()
		local pitch = ((time / 360) - 1) * 90
		if pitch < 0 then pitch = pitch + 360 end
		local n = true
		if pitch > 180 then pitch = pitch - 180 n = false end
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

local max,min,abs,clamp = math.max,math.min,math.abs,math.Clamp
local distance = 4300
local lcon = GetConVar("sf_dynamiclightamount")
hook.Add("RenderScene","StormFox - Suntest",function(eyepos,eyeang)
	if not LocalPlayer() then return end
	local con = GetConVar("sf_allow_dynamicshadow")
	local thunder_light = StormFox.GetData("ThunderLight",0)
	if not con:GetBool() then
		if STORMFOX_SUN then
			STORMFOX_SUN:Remove()
		end
		if STORMFOX_SUN_distance then
			STORMFOX_SUN_distance:Remove()
		end
		return
	end
	-- Get angle and alpha
		local sunAngle,isDay = nil,true
		if thunder_light > 10 then
			sunAngle = Angle(90,0,0)
		else
			sunAngle,isDay = GetMoonAngle()
		end
		local cA = sunAngle.p < 135 and min((sunAngle.p - 15) / 15,2) or min(((180 - sunAngle.p) - 15) / 15,2) -- ColorAlpha
		local alpha = min(1,cA)
		local colMult = max(0,cA - 1)
	-- Get color
		local col = nil
		if isDay then
			col = Color(255,155 + 100 * colMult,60 + 195 * colMult)
		else
			col = Color(160,200,255)
		end
	-- Find skyhit
	local search_distance = StormFox.Is3DSkybox() and 22000 or 4300
	local skypos = findSky(eyepos,-sunAngle:Forward(),MASK_SOLID_BRUSHONLY)
	if skypos then
		skypos = ET(skypos-sunAngle:Forward() * 10,-sunAngle:Forward() * search_distance,MASK_SOLID_BRUSHONLY).HitPos
		local d = min(skypos:Distance(eyepos),24000)
			distance = max(d,4300)
	else
	--	distance = StormFox.Is3DSkybox() and 18000 or 4300
	end

	local lppos = eyepos + sunAngle:Forward() * -distance
	if not STORMFOX_SUN or not IsValid(STORMFOX_SUN) then
		--print("create")
		STORMFOX_SUN = ProjectedTexture()
		STORMFOX_SUN:SetPos(lppos)
		STORMFOX_SUN:SetAngles(sunAngle)

		STORMFOX_SUN:SetEnableShadows(true)

		STORMFOX_SUN:SetNearZ( 1200 )

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

		STORMFOX_SUN_distance:SetTexture("lights/white003_nochop")
		STORMFOX_SUN_distance:Update()
	end
	local tlight = 0
	STORMFOX_SUN:SetTexture("stormfox/small_shadow_sprite")
	local l = 500
	local f = StormFox.GetNetworkData("has_light_environment",false)
		STORMFOX_SUN:SetColor(col)
		STORMFOX_SUN_distance:SetColor(col)
	if isday then
		tlight = alpha * StormFox.GetData("SunSize",20) * 0.5
	else
		tlight = alpha * StormFox.GetData("MoonVisibility",100) * 0.05 - 2
	end
	if f then
		tlight = tlight * 5
	end
	if lcon then
		tlight = tlight * clamp(lcon:GetFloat(),0,5)
	end
	tlight = tlight * clamp(distance / 22500,0,1)
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