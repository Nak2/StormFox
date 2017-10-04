-- g_SkyPaint uses entity datatables which end up getting reset to the values on the server every second. So this replaces it

StormFox.SkyPaint = {}

local vTopColor = Vector( 0.2, 0.5, 1.0 )
local vBottomColor = Vector( 0.8, 1.0, 1.0 )
local flFadeBias = 1
local vSunNormal = Vector( 0.4, 0.0, 0.01 )
local vSunColor = Vector( 0.2, 0.1, 0.0 )
local flSunSize = 2.0
local vDuskColor = Vector( 1.0, 0.2, 0.0 )
local flDuskScale = 1
local flDuskIntensity = 1
local bDrawStars = true
local nStarLayers = 1
local flStarSpeed = 0.01
local flStarScale = 0.5
local flStarFade = 1.5
local sStarTexture = "skybox/starfield"
local flHDRScale = 0.66

-- The Material segments in the skybox we will be overriding, we ignore the bottom because no one sees it, if you need it it's "skybox/painteddn"
local tMaterialSegments = {
	Material("skybox/paintedft"),
	Material("skybox/paintedlf"),
	Material("skybox/paintedbk"),
	Material("skybox/paintedup"),
	Material("skybox/paintedrt")
}
-- This overrides the matproxy used by g_SkyPaint. Since g_SkyPaint uses entity datatables that are reset by the server every tick or something.
local function overrideMatProxy() -- We don't actually use this but we need to override g_SkyPaints matproxy
	matproxy.Add( {
		name = "SkyPaint",
		init = function( self, mat, values ) end,
		bind = function( self, mat, ent ) end
	} )
end
timer.Simple( 0.5, overrideMatProxy ) -- for lua refreshing

-- Skypaint think
local function ColorToVector( cColor, flDivisor )
	flDivisor = flDivisor or 255
	return Vector( cColor.r / flDivisor, cColor.g / flDivisor, cColor.b / flDivisor )
end

-- SkyPaint Main
local max,round = math.max,math.Round
local oldSunSize
local max = math.max

hook.Add( "StormFox-Tick", "StormFox - SkyThink", function( flTime )
	flTime = flTime or StormFox.GetTime()

	local topColor = StormFox.GetData( "SkyTopColor", Color( 51, 127.5, 255 ) )
	vTopColor = ColorToVector( topColor )
	vBottomColor = ColorToVector( StormFox.GetData("SkyBottomColor", Color(204,255,255)) )
	flFadeBias = StormFox.GetData( "FadeBias", 1 )
	flHDRScale = StormFox.GetData("HDRScale",0.66)
	vSunColor = Vector(0,0,0)
	flSetSunSize = StormFox.GetData("SunSize",20) / 500
	vSetDuskColor = ColorToVector( StormFox.GetData( "DuskColor", Color(255,51,0) ))
	flDuskIntensity = StormFox.GetData("DuskIntensity",1)
	flDuskScale = StormFox.GetData("DuskScale",1)
	-- Only draw stars if the current weather type has it enabled and its night time.
	bDrawStars = StormFox.GetData("DrawStars", true) and ( flTime < 330 or flTime > 1100 )
	flStarSpeed = RealTime() * StormFox.GetData("StarSpeed",0.001)
	flStarFade = StormFox.GetData("StarFade",1.5)
	sStarTexture = StormFox.GetData( "StarTexture","skybox/starfield")

	-- Update the skybox materials
	for i = 1, #tMaterialSegments - 1 do
		tMaterialSegments[ i ]:SetVector( "$TOPCOLOR", vTopColor )
		tMaterialSegments[ i ]:SetVector( "$BOTTOMCOLOR", vBottomColor )
		tMaterialSegments[ i ]:SetVector( "$SUNNORMAL",	vSunNormal )
		tMaterialSegments[ i ]:SetVector( "$SUNCOLOR", vSunColor )
		tMaterialSegments[ i ]:SetVector( "$DUSKCOLOR",	vDuskColor )
		tMaterialSegments[ i ]:SetFloat( "$FADEBIAS", flFadeBias )
		tMaterialSegments[ i ]:SetFloat( "$HDRSCALE", flHDRScale )
		tMaterialSegments[ i ]:SetFloat( "$DUSKSCALE", flDuskScale )
		tMaterialSegments[ i ]:SetFloat( "$DUSKINTENSITY", flDuskIntensity)
		tMaterialSegments[ i ]:SetFloat( "$SUNSIZE", flSunSize )
		if ( bDrawStars ) then
			tMaterialSegments[ i ]:SetInt( "$STARLAYERS", nStarLayers )
			tMaterialSegments[ i ]:SetFloat( "$STARSCALE", flStarScale )
			tMaterialSegments[ i ]:SetFloat( "$STARFADE", flStarFade )
			tMaterialSegments[ i ]:SetFloat( "$STARPOS", flStarSpeed )
			tMaterialSegments[ i ]:SetTexture( "$STARTEXTURE", sStarTexture)
		else
			tMaterialSegments[ i ]:SetInt( "$STARLAYERS", 0 )
		end
	end
end)


-- Shit for shooting stars

local shootingstars = {}
local ran,abs,cos,sin,max = math.random,math.abs,math.cos,math.sin,math.max
timer.Create("ShootingStars",0.5,0,function()
	if #shootingstars > 5 or ran(100) < 90  then return end
	local pos = Angle(ran(360),ran(360),ran(360)):Forward() * 20000
		pos.z = max(math.abs(pos.z),10000)
	local movevec = Vector(0,cos(ran(math.pi)),-ran(10) / 10)
	table.insert(shootingstars,{ran(2) / 10 + CurTime() ,pos, movevec })
end)

local beam_mat = Material("effects/beam_generic01")
local last = CurTime()
hook.Add( "PostDraw2DSkyBox", "StormFox - ShootingStars", function()
	if not StormFox.GetData then return end
	local FT = (CurTime() - last) * 100
		last = CurTime()
	if StormFox.GetData("StarFade",0) <= 0.7 then return end
	if #shootingstars <= 0 then return end

	render.SuppressEngineLighting( true )
			render.OverrideDepthEnable( true, false )
			render.SuppressEngineLighting(true)
			render.SetLightingMode( 2 )

			render.SetMaterial(beam_mat)
			for i = #shootingstars,1,-1 do
				local life,pos,movevec = shootingstars[i][1],shootingstars[i][2],shootingstars[i][3]
				if life < CurTime() then
					table.remove(shootingstars,i)
				else
					render.DrawBeam(pos,pos + movevec * 1500,40,0,1,Color(255,255,255))
					shootingstars[i][2] = pos + movevec * FT * 1000
				end
			end

			render.SuppressEngineLighting(false)
			render.SetLightingMode( 0 )
			render.OverrideDepthEnable( false, false )
	render.SuppressEngineLighting( false )
end )
