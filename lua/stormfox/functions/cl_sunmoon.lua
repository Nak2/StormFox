
function StormFox.GetMoonAngle(time) -- Same as the sun .. tbh
	time = time or StormFox.GetTime()
	local pitch = ((time / 360) - 1) * 90
	if pitch < 0 then pitch = pitch + 360 end
	local ang = Angle(pitch,StormFox.GetData("SunMoonAngle",0), 0)
	return ang
end

local clamp = math.Clamp

local function MoonScale()
	return GetConVarNumber("sf_moonscale",6)
end

--local MaterialMoon = Material("stormfox/moon_full.png", "smooth")
--	MaterialMoon:SetFloat("$nofog","1")
--local MoonGlow = Material( "stormfox/moon_glow.png", "noclamp smooth" );
local MoonGlow = Material("stormfox/moon_glow")
local m = Material( "stormfox/moon_fix" );
local poly
local m_update = 0
local sunMat = Material("engine/lightsprite")
hook.Add( "PostDraw2DSkyBox", "StormFox - MoonRender", function()

	if not StormFox.GetMoonAngle then return end
	if not StormFox.GetTime then return end
	local ang = StormFox.GetMoonAngle()
--	LocalPlayer():SetEyeAngles( ang )
	local eyepos = EyePos()
	local N = ang:Forward()
	local pos = eyepos + (N * 15000)
	local pos2 = eyepos + (N * 15500)
	local moonsize = 256 * MoonScale()

		local a = StormFox.GetData("MoonLight",100) / 100
		local c = StormFox.GetData("MoonColor",Color(205,205,205))
		local s = moonsize * 2 + (moonsize * 1.4) * (1.2-a)

	local mirror = (ang.p >= 270 or ang.p < 90) and true or false
	if m_update < SysTime() or not poly then
		m_update = SysTime() + 1

	end
	local eyeang = EyeAngles()
	cam.Start3D( Vector( 0, 0, 0 ), eyeang ) -- 2d maps fix
		render.SuppressEngineLighting( true )
		--	cam.Start3D(EyePos(),ea) -- Start the 3D function so we can draw onto the screen.
				render.OverrideDepthEnable( true, false )
				render.SuppressEngineLighting(true)
				render.SetLightingMode( 2 )

				render.SetMaterial( MoonGlow )
				--render.DrawSprite( pos2 , s, s, Color(c.r,c.g,c.b,a * 25)) -- Draw the sprite in the middle of the map, at 16x16 in it's original colour with full alpha.
				local nn = 60
				local glow = clamp(a,0,1)
				render.DrawQuadEasy( N * 200, -N, moonsize / nn, moonsize / nn, Color(c.r,c.g,c.b, glow * 255), (ang.p >= 270 or ang.p < 90) and 180 or 0 )

				render.SetMaterial( m )
				
				--render.DrawQuadEasy( pos, -N, moonsize, moonsize, Color(c.r,c.g,c.b, clamp((a - 0.3) * 255,0,255)),(ang.p >= 270 or ang.p < 90) and 180 or 0 )
				local moonalpha = clamp((a * 1.1) - 0.2,0,1) * 255
	
				render.DrawQuadEasy( N * 200, -N, moonsize / 100, moonsize / 100, Color(c.r,c.g,c.b, moonalpha), (ang.p >= 270 or ang.p < 90) and 180 or 0 )

				render.SetMaterial(sunMat)
				local sunSize = StormFox.GetData("SunSize", 30) or 30
				local sunColor = StormFox.GetData("SunColor",Color(255,255,255))
				render.DrawQuadEasy( N * -200, N, sunSize, sunSize, sunColor, 0 )

				render.SuppressEngineLighting(false)
				render.SetLightingMode( 0 )
				render.OverrideDepthEnable( false, false )
				render.SetColorMaterial()

		--	cam.End3D()
		render.SuppressEngineLighting( false )
	cam.End3D()
end )
-- Sunbeam
	--sf_allow_sunbeams
	local matSunbeams = Material( "pp/sunbeams" )
		matSunbeams:SetTexture( "$fbtexture", render.GetScreenEffectTexture() )
	local abs,max = math.abs,math.max
	STORMFOX_PIXEL = STORMFOX_PIXEL or util.GetPixelVisibleHandle()
	hook.Add( "RenderScreenspaceEffects", "StormFox - Sunbeams", function()
		if ( not render.SupportsPixelShaders_2_0() ) then return end
		local con = GetConVar("sf_allow_sunbeams")
		if not con or not con:GetBool() then return end
		local ang = StormFox.GetMoonAngle()
		local lam = StormFox.GetDaylightAmount() - 0.5

		if ang.p > 180 then ang.p = ang.p - 180 end
		local direciton = -ang:Forward()
		local beampos = EyePos() + direciton * 4096

		local pix = util.PixelVisible( beampos, 100, STORMFOX_PIXEL)
		local scrpos = beampos:ToScreen()

		if ( pix == 0 ) then return end

		local dot = ( direciton:Dot( EyeVector() ) - 0.8 ) * 5
		if ( dot <= 0 ) then return end

		local suna = StormFox.GetData("SunColor",Color(255,255,255,255)).a
		local slam = max((suna - 155) / 100,0)

		render.UpdateScreenEffectTexture()

			matSunbeams:SetFloat( "$darken", 0.95 )
			matSunbeams:SetFloat( "$multiply", abs(lam) * dot * pix * slam )
			matSunbeams:SetFloat( "$sunx", scrpos.x / ScrW() )
			matSunbeams:SetFloat( "$suny", scrpos.y / ScrH() )
			matSunbeams:SetFloat( "$sunsize", 0.075 )

			render.SetMaterial( matSunbeams )
		render.DrawScreenQuad()
	end )