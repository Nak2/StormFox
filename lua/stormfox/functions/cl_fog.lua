local app = math.Approach
local max = math.max
local smoothe,smooths = 10000, 10000
local SkyFog = function(scale)
	if not scale then scale = 1 end
	if not StormFox.GetData then return end
	local con = GetConVar("sf_disablefog")
	if con and con:GetBool() then
		return
	end
	local col = StormFox.GetData("Bottomcolor",Color(255,255,255))
	local outside = StormFox.Env.IsOutside() or StormFox.Env.NearOutside()

	local fogend,fogstart = StormFox.GetData("Fogend",10000), StormFox.GetData("Fogstart",10000)
	local ft = FrameTime()
	local amf = ft * 2500
	if not outside then
		smooths = app(smooths, max(200,fogstart), amf)
		smoothe = app(smoothe, max(500,fogend), amf)
	else
		smooths = app(smooths, fogstart, amf)
		smoothe = app(smoothe, fogend, amf)
	end

	render.FogMode( 1 )
	render.FogStart( smooths * scale )
	render.FogEnd( smoothe * scale )
	render.FogMaxDensity( StormFox.GetData("Fogdensity",0))

	render.FogColor( col.r,col.g,col.b )
	return true
end
hook.Add("SetupSkyboxFog","StormFox - skyfog",SkyFog)
hook.Add("SetupWorldFog","StormFox - skyworldfog",SkyFog)