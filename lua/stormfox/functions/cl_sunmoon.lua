
-- y = mx - b  -> pitch = sunAngSlope - sunAngOffset. This makes the sun angle equal to 0 at sunrise and 180 at sunset
local flSunAngSlope = 180 / ( StormFox.WeatherType.TIME_SUNSET - StormFox.WeatherType.TIME_SUNRISE )
local flSunAngOffset = flSunAngSlope * StormFox.WeatherType.TIME_SUNRISE

function StormFox.GetSunAngle( flTime )
	flTime = flTime or StormFox.GetTime()
	local pitch = flSunAngSlope * flTime - flSunAngOffset
	if pitch < 0 then pitch = pitch + 360 end
	return Angle( pitch, StormFox.SunMoonAngle, 0 )
end

local flNightLength = 1440 - StormFox.WeatherType.TIME_SUNSET + StormFox.WeatherType.TIME_SUNRISE
local flMoonSlope = 180 / flNightLength
local flMoonIntercept = ( 1440 - StormFox.WeatherType.TIME_SUNSET ) * 180 / flNightLength

function StormFox.GetMoonAngle( flTime )
	flTime = flTime or StormFox.GetTime()
	-- At night we convert times after sunset to be negative morning times. So the equation starts at like (-200, 0) and ends at ( 360, 180 )
	flTime = ( flTime > StormFox.WeatherType.TIME_SUNSET - 5 ) and flTime - 1440 or flTime
	local pitch = flMoonSlope * flTime + flMoonIntercept
	pitch = pitch + 180
	if pitch > 360 then pitch = 90 end
	return Angle( pitch, StormFox.SunMoonAngle, 0 )
end

local clamp = math.Clamp

local function MoonScale()
	return GetConVarNumber("sf_moonscale",6)
end


local matMoonGlow = Material("stormfox/moon_glow")
local matMoon = Material( "stormfox/moon_fix" );
local matSun = Material("engine/lightsprite")
hook.Add( "PostDraw2DSkyBox", "StormFox - MoonRender", function()

	if not StormFox.GetMoonAngle or not StormFox.GetSunAngle then return end
	if not StormFox.GetTime then return end

	local aMoonAng = StormFox.GetMoonAngle()
	local vMoonNormalVec = aMoonAng:Forward()
	local vMoonRenderPosition = vMoonNormalVec * 200
	local moonsize = 256 * MoonScale()

	local aSunAng = StormFox.GetSunAngle()
	local vSunNormalVec = aSunAng:Forward()
	local vSunRenderPosition = vSunNormalVec * 200

	local a = StormFox.GetData("MoonLight",100) / 100
	local c = StormFox.GetData("MoonColor",Color(205,205,205))
	local s = moonsize + (moonsize * 1.4) * (1.2-a)

	local eyeang = EyeAngles()
	cam.Start3D( Vector( 0, 0, 0 ), eyeang ) -- 2d maps fix
		render.SuppressEngineLighting( true )

			render.OverrideDepthEnable( true, false )
			render.SuppressEngineLighting(true)
			render.SetLightingMode( 2 )

			render.SetMaterial( matMoonGlow )

			local nGlowSize = moonsize / 60
			local glow = clamp(a,0,1)
			render.DrawQuadEasy( vMoonRenderPosition, -vMoonNormalVec, nGlowSize, nGlowSize, Color(c.r,c.g,c.b, glow * 255), (aMoonAng.p >= 270 or aMoonAng.p < 90) and 180 or 0 )

			render.SetMaterial( matMoon )

			local moonalpha = clamp((a * 1.1) - 0.2,0,1) * 255
			render.DrawQuadEasy( vMoonRenderPosition, -vMoonNormalVec, moonsize / 100, moonsize / 100, Color(c.r,c.g,c.b, moonalpha), (aMoonAng.p >= 270 or aMoonAng.p < 90) and 180 or 0 )

			render.SetMaterial( matSun )
			local sunSize = StormFox.GetData("SunSize", 30) or 30
			local sunColor = StormFox.GetData("SunColor",Color(255,255,255))
			render.DrawQuadEasy( -vSunRenderPosition, vSunNormalVec, sunSize, sunSize, sunColor, 0 )

			render.SuppressEngineLighting(false)
			render.SetLightingMode( 0 )
			render.OverrideDepthEnable( false, false )
			render.SetColorMaterial()

		render.SuppressEngineLighting( false )
	cam.End3D()
end )
-- Sunbeam
	--sf_allow_sunbeams
	-- local matSunbeams = Material( "pp/sunbeams" )
	-- 	matSunbeams:SetTexture( "$fbtexture", render.GetScreenEffectTexture() )
	-- local abs,max = math.abs,math.max
	-- STORMFOX_PIXEL = STORMFOX_PIXEL or util.GetPixelVisibleHandle()
	-- hook.Add( "RenderScreenspaceEffects", "StormFox - Sunbeams", function() -- TODO: Fix this shit if you need it
	--
	-- 	if ( not render.SupportsPixelShaders_2_0() ) then return end
	-- 	local con = GetConVar("sf_allow_sunbeams")
	-- 	if not con or not con:GetBool() then return end
	-- 	local ang = StormFox.GetMoonAngle()
	-- 	local lam = StormFox.GetDaylightAmount() - 0.5
	--
	-- 	if ang.p > 180 then ang.p = ang.p - 180 end
	-- 	local direciton = -ang:Forward()
	-- 	local beampos = EyePos() + direciton * 4096
	--
	-- 	local pix = util.PixelVisible( beampos, 100, STORMFOX_PIXEL)
	-- 	local scrpos = beampos:ToScreen()
	--
	-- 	if ( pix == 0 ) then return end
	--
	-- 	local dot = ( direciton:Dot( EyeVector() ) - 0.8 ) * 5
	-- 	if ( dot <= 0 ) then return end
	--
	-- 	local suna = StormFox.GetData("SunColor",Color(255,255,255,255)).a
	-- 	local slam = max((suna - 155) / 100,0)
	--
	-- 	render.UpdateScreenEffectTexture()
	--
	-- 		matSunbeams:SetFloat( "$darken", 0.95 )
	-- 		matSunbeams:SetFloat( "$multiply", abs(lam) * dot * pix * slam )
	-- 		matSunbeams:SetFloat( "$sunx", scrpos.x / ScrW() )
	-- 		matSunbeams:SetFloat( "$suny", scrpos.y / ScrH() )
	-- 		matSunbeams:SetFloat( "$sunsize", 0.075 )
	--
	-- 		render.SetMaterial( matSunbeams )
	-- 	render.DrawScreenQuad()
	-- end )
