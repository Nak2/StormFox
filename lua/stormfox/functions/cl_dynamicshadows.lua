
-- Local Functions
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
	local function findSky(pos1,pos2,mask)
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
	if not con:GetBool() or not StormFox.GetMapSetting("dynamiclight") or not StormFox.EFEnabled() then
		if STORMFOX_SUN then
			STORMFOX_SUN:Remove()
		end
		if STORMFOX_SUN_distance then
			STORMFOX_SUN_distance:Remove()
		end
		return
	end
	local thunder_light = StormFox.GetData("ThunderLight",0)
	-- Get ambient color
		local light_angle,isDay = nil,true
		local light_amount = 0
		local light_color = Color(255,255,255,0)
		if thunder_light > 10 then
			light_angle = Angle(90,0,0)
			light_color = Color(255,255,255,thunder_light * 1.3)
		else
			light_color,light_angle = StormFox.GetAmbientLight()		
		end
	-- Find skyhit
		local search_distance = StormFox.Is3DSkybox() and 22000 or 4300
		local skypos = findSky(eyepos,-light_angle:Forward(),MASK_SOLID_BRUSHONLY)
		if skypos then
			skypos = ET(skypos-light_angle:Forward() * 10,-light_angle:Forward() * search_distance,MASK_SOLID_BRUSHONLY).HitPos
			local d = min(skypos:Distance(eyepos),24000)
				distance = max(d,4300)
		else
		--	distance = StormFox.Is3DSkybox() and 18000 or 4300
		end
	-- Apply pos and angle
		local lppos = eyepos + light_angle:Forward() * -distance
		if not STORMFOX_SUN or not IsValid(STORMFOX_SUN) then
			--print("create")
			STORMFOX_SUN = ProjectedTexture()
			STORMFOX_SUN:SetPos(lppos)
			STORMFOX_SUN:SetAngles(light_angle)

			STORMFOX_SUN:SetEnableShadows(true)

			STORMFOX_SUN:SetNearZ( 1200 )

			STORMFOX_SUN:SetTexture("engine/depthwrite")
			STORMFOX_SUN:Update()
		end
		if not STORMFOX_SUN_distance or not IsValid(STORMFOX_SUN_distance)  then
			STORMFOX_SUN_distance = ProjectedTexture()
			STORMFOX_SUN_distance:SetPos(lppos)
			STORMFOX_SUN_distance:SetAngles(light_angle)

			STORMFOX_SUN_distance:SetEnableShadows(true)

			STORMFOX_SUN_distance:SetNearZ( 1200 )
			STORMFOX_SUN_distance:SetFOV( 80 )

			STORMFOX_SUN_distance:SetTexture("lights/white003_nochop")
			STORMFOX_SUN_distance:Update()
		end
	-- Apply color and tex
	STORMFOX_SUN:SetTexture("stormfox/small_shadow_sprite")
	local l = 500
	local f = StormFox.GetNetworkData("has_light_environment",false)
		STORMFOX_SUN:SetColor(light_color)
		STORMFOX_SUN_distance:SetColor(light_color)
	local brightness = light_color.a / 25.5
	if lcon then
		brightness = brightness * clamp(lcon:GetFloat(),0,5) * 2
	end
	brightness = brightness * clamp(distance / 22500,0,1)
	STORMFOX_SUN:SetOrthographic(true,l,l,l,l)
	STORMFOX_SUN:SetFarZ( distance * 1.3 )
	STORMFOX_SUN:SetBrightness(brightness)
	STORMFOX_SUN:SetAngles(light_angle)
	STORMFOX_SUN:SetPos(lppos)
	STORMFOX_SUN:Update()

	local l = 2000
	STORMFOX_SUN_distance:SetTexture("stormfox/shadow_sprite")
	STORMFOX_SUN_distance:SetOrthographic(true,l,l,l,l)
	STORMFOX_SUN_distance:SetFarZ( distance * 1.3  )
	STORMFOX_SUN_distance:SetBrightness(brightness)
	STORMFOX_SUN_distance:SetPos(lppos )
	STORMFOX_SUN_distance:SetAngles(light_angle)

	STORMFOX_SUN_distance:Update()
end)