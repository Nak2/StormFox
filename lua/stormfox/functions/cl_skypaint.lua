
-- Skypaint think
	local function ColVec(col,div)
		if not div then
			return Vector(col.r,col.g,col.b)
		end
		return Vector(col.r / div,col.g / div,col.b / div)
	end


-- SkyPaint Main
local max,round = math.max,math.Round
local oldSunSize
local max = math.max
hook.Add("Think","StormFox - SkyThink",function()
	if not IsValid(g_SkyPaint) then return end

		local tl = StormFox.GetData("ThunderLight",0)
		local topColor = StormFox.GetData("Topcolor",Color(51,127.5,255))
		g_SkyPaint:SetTopColor(ColVec(Color(max(topColor.r,tl),max(topColor.g,tl),max(topColor.b,tl)),255))
		g_SkyPaint:SetBottomColor(ColVec(StormFox.GetData("Bottomcolor",Color(204,255,255)),255))
		g_SkyPaint:SetFadeBias(StormFox.GetData("FadeBias",1))
		g_SkyPaint:SetHDRScale(StormFox.GetData("HDRScale",0.66))
		g_SkyPaint:SetSunColor(ColVec(StormFox.GetData("SunColor",Color(255,255,255)),255))
		local s = StormFox.GetData("SunSize",20) / 500
		g_SkyPaint:SetSunSize( StormFox.GetDaylightAmount() * s) --max( StormFox.GetData("SunOverlay",20) / 20 ) )


		g_SkyPaint:SetDuskColor(ColVec(StormFox.GetData("DuskColor",Color(255,51,0)),255))
		g_SkyPaint:SetDuskIntensity(StormFox.GetData("DuskIntensity",1))
		g_SkyPaint:SetDuskScale(StormFox.GetData("DuskScale",1))


		g_SkyPaint:SetDrawStars(StormFox.GetData("DrawStars",false))
		g_SkyPaint:SetStarSpeed(StormFox.GetData("StarSpeed",0.001))
		g_SkyPaint:SetStarFade(StormFox.GetData("StarFade",1.5))
		g_SkyPaint:SetStarTexture(StormFox.GetData("StarTexture","skybox/starfield"))

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
