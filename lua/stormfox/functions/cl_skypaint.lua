
-- Skypaint think
	local function ColVec(col,div)
		if not div then
			return Vector(col.r,col.g,col.b)
		end
		return Vector(col.r / div,col.g / div,col.b / div)
	end

-- Override skypaint problems
local g_SkyPaint_tab = {}
	function g_SkyPaint_tab.IsValid() return true end

local g_datacache = {}
local function AddDataCache(name,defaultdata)
	g_datacache[name] = defaultdata
	g_SkyPaint_tab["Set" .. name] = function(self,var)
		g_datacache[name] = var
	end
	g_SkyPaint_tab["Get" .. name] = function()
		return g_datacache[name]
	end
end
AddDataCache("TopColor", Vector( 0.2, 0.5, 1.0 ) )
AddDataCache("BottomColor", Vector( 0.8, 1.0, 1.0 ) )
AddDataCache("FadeBias", 1 )

AddDataCache("SunNormal", Vector( 0.4, 0.0, 0.01 ) )
AddDataCache("SunColor", Vector( 0.2, 0.1, 0.0 ) )
AddDataCache("SunSize", 2.0 )

AddDataCache("DuskColor", Vector( 1.0, 0.2, 0.0 ) )
AddDataCache("DuskScale", 1 )
AddDataCache("DuskIntensity", 1 )

AddDataCache("DrawStars", true )
AddDataCache("StarLayers", 1 )
AddDataCache("StarSpeed", 0.01 )
AddDataCache("StarScale", 0.5 )
AddDataCache("StarFade", 1.5 )
AddDataCache("StarTexture", "skybox/starfield" )

AddDataCache("HDRScale", 0.66 )

hook.Add("Think","StormFox - SkyPaintFix",function()
	if not IsValid(g_SkyPaint) then return end
	if type(g_SkyPaint) ~= "Entity" then return end
	if g_SkyPaint:GetClass() == "env_skypaint" then
		-- We'll hande it from here
		g_SkyPaint = g_SkyPaint_tab
	end
end)

-- SkyPaint Main
local max,round,clamp = math.max,math.Round,math.Clamp
local oldSunSize
local max = math.max
hook.Add("Think","StormFox - SkyThink",function()
	if not IsValid(g_SkyPaint) then return end
		local tl = StormFox.GetData("ThunderLight") or 0
		local topColor = StormFox.GetData("SkyTopColor") or Color(51,127.5,255)
		g_SkyPaint:SetTopColor(ColVec(Color(max(topColor.r,tl),max(topColor.g,tl),max(topColor.b,tl)),255))
		g_SkyPaint:SetBottomColor(ColVec(StormFox.GetData("SkyBottomColor") or Color(204,255,255),255))
		g_SkyPaint:SetFadeBias(StormFox.GetData("FadeBias") or 1)
		g_SkyPaint:SetHDRScale(StormFox.GetData("HDRScale") or 0.66)
		local sunsize = StormFox.GetData("SunSize") or 30
		local sc = StormFox.GetData("SunColor") or Color(255,255,255)
			sc.a = clamp(sunsize / 20,0,1) * 255
		g_SkyPaint:SetSunColor(ColVec(sc,255))

		local s = (sunsize > 5 and sunsize or 0) / 500

		g_SkyPaint:SetSunSize( StormFox.CalculateMapLight() / 100 * s) --max( StormFox.GetData("SunOverlay",20) / 20 ) )
		if sunsize <= 0 then
			g_SkyPaint:SetDuskColor(ColVec(Color(0,0,0),255))
		else
			g_SkyPaint:SetDuskColor(ColVec(StormFox.GetData("DuskColor") or Color(255,51,0),255))
		end
		g_SkyPaint:SetDuskIntensity(StormFox.GetData("DuskIntensity") or 1)
		g_SkyPaint:SetDuskScale(StormFox.GetData("DuskScale") or 1)

		local n = StormFox.GetData("StarFade") or 1.5
		if n <= 0 then
			g_SkyPaint:SetDrawStars(false)
		else
			g_SkyPaint:SetDrawStars(true)
			g_SkyPaint:SetStarSpeed((StormFox.GetData("StarSpeed") or 0.001) * StormFox.GetTimeSpeed())
			g_SkyPaint:SetStarFade(n)
			g_SkyPaint:SetStarScale(StormFox.GetData("StarScale") or 0.5)
			g_SkyPaint:SetStarTexture(StormFox.GetData("StarTexture","skybox/starfield"))
		end

end)

local shootingstars = {}
local ran,abs,cos,sin,max = math.random,math.abs,math.cos,math.sin,math.max
timer.Create("ShootingStars",0.5,0,function()
	if #shootingstars > 5 or ran(100) < 90  then return end
	local pos = Angle(ran(360),ran(360),ran(360)):Forward() * 20000
		pos.z = max(math.abs(pos.z),10000)
	local movevec = Vector(0,cos(ran(math.pi)),-ran(10) / 10)
	table.insert(shootingstars,{ran(2) / 10 + SysTime() ,pos, movevec })
end)

local beam_mat = Material("effects/beam_generic01")
local last = SysTime()
hook.Add( "PostDraw2DSkyBox", "StormFox - ShootingStars", function()
	if not StormFox.GetData then return end
	local FT = (SysTime() - last) * 100
		last = SysTime()
	if StormFox.GetData("StarFade",0) <= 0.7 then return end
	if #shootingstars <= 0 then return end

	render.SuppressEngineLighting( true )
			render.OverrideDepthEnable( true, false )
			render.SuppressEngineLighting(true)
			render.SetLightingMode( 2 )

			render.SetMaterial(beam_mat)
			for i = #shootingstars,1,-1 do
				local life,pos,movevec = shootingstars[i][1],shootingstars[i][2],shootingstars[i][3]
				if life < SysTime() then
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