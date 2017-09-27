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

function StormFox.SkyPaint.GetTopColor() return vTopColor end
function StormFox.SkyPaint.GetBottomColor() return vBottomColor end
function StormFox.SkyPaint.GetFadeBias() return flFadeBias end
function StormFox.SkyPaint.GetSunNormal() return vSunNormal end
function StormFox.SkyPaint.GetSunColor() return vSunColor end
function StormFox.SkyPaint.GetSunSize() return flSunSize end
function StormFox.SkyPaint.GetDuskColor() return vDuskColor end
function StormFox.SkyPaint.GetDuskScale() return flDuskScale end
function StormFox.SkyPaint.GetDuskIntensity() return flDuskIntensity end
function StormFox.SkyPaint.GetDrawStars() return bDrawStars end
function StormFox.SkyPaint.GetStarLayers() return nStarLayers end
function StormFox.SkyPaint.GetStarSpeed() return flStarSpeed end
function StormFox.SkyPaint.GetStarScale() return flStarScale end
function StormFox.SkyPaint.GetStarFade() return flStarFade end
function StormFox.SkyPaint.GetStarTexture() return sStarTexture end
function StormFox.SkyPaint.GetHDRScale() return flHDRScale end


-- This overrides the matproxy used by g_SkyPaint. Since g_SkyPaint uses entity datatables that are reset by the server every tick or something.
matproxy.Add( {
	name = "SkyPaint",

	init = function( self, mat, values )
	end,

	bind = function( self, mat, ent )

		if not StormFox.SkyPaint then return end

		mat:SetVector( "$TOPCOLOR",		StormFox.SkyPaint.GetTopColor() )
		mat:SetVector( "$BOTTOMCOLOR",	StormFox.SkyPaint.GetBottomColor() )
		mat:SetVector( "$SUNNORMAL",	StormFox.SkyPaint.GetSunNormal() )
		mat:SetVector( "$SUNCOLOR",		StormFox.SkyPaint.GetSunColor() )
		mat:SetVector( "$DUSKCOLOR",	StormFox.SkyPaint.GetDuskColor() )
		mat:SetFloat( "$FADEBIAS",		StormFox.SkyPaint.GetFadeBias() )
		mat:SetFloat( "$HDRSCALE",		StormFox.SkyPaint.GetHDRScale() )
		mat:SetFloat( "$DUSKSCALE",		StormFox.SkyPaint.GetDuskScale() )
		mat:SetFloat( "$DUSKINTENSITY",	StormFox.SkyPaint.GetDuskIntensity() )
		mat:SetFloat( "$SUNSIZE",		StormFox.SkyPaint.GetSunSize() )

		if ( StormFox.SkyPaint.GetDrawStars() ) then
			mat:SetInt( "$STARLAYERS",		StormFox.SkyPaint.GetStarLayers() )
			mat:SetFloat( "$STARSCALE",		StormFox.SkyPaint.GetStarScale() )
			mat:SetFloat( "$STARFADE",		StormFox.SkyPaint.GetStarFade() )
			mat:SetFloat( "$STARPOS",		RealTime() * StormFox.SkyPaint.GetStarSpeed() )
			mat:SetTexture( "$STARTEXTURE",	StormFox.SkyPaint.GetStarTexture() )
		else
			mat:SetInt( "$STARLAYERS", 0 )
		end
	end
} )




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
	vSunColor = ColorToVector( StormFox.GetData("SunColor", Color(255,255,255) ) )

	local s = StormFox.GetData("SunSize",20) / 500
	flSetSunSize = StormFox.GetDaylightAmount() * s


	vSetDuskColor = ColorToVector( StormFox.GetData( "DuskColor", Color(255,51,0) ))
	flDuskIntensity = StormFox.GetData("DuskIntensity",1)
	flDuskScale = StormFox.GetData("DuskScale",1)

	-- Only draw stars if the current weather type has it enabled and its night time.
	bDrawStars = StormFox.GetData("DrawStars", true) and ( flTime < 330 or flTime > 1100 )

	flStarSpeed = StormFox.GetData("StarSpeed",0.001)
	flStarFade = StormFox.GetData("StarFade",1.5)
	sStarTexture = StormFox.GetData( "StarTexture","skybox/starfield")

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
