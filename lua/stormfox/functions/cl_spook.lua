

local eyes = {}
local function ET(pos,pos2)
	local tr = util.TraceLine( {
		start = pos,
		endpos = pos2,
		mask = MASK_SOLID_BRUSHONLY
	} )
	return tr.Hit
end


timer.Create("StormFox - Spooky",2,0,function()
	if not StormFox.GetAllONodes then return end
	if not StormFox.EFEnabled() then return end
	if not IsValid(LocalPlayer()) then return end
	local con = GetConVar("sf_enablespooky")
	if con:GetInt() ~= 1 then return end
	table.Empty(eyes)

	local lp = LocalPlayer():GetShootPos()
	for i,v in ipairs(StormFox.GetAllONodes()) do
		if #eyes >= 20 then return end
		if v[2] > 20 and v[1].z >= lp.z - 200 then
			local dis = v[1]:DistToSqr(lp)
			if dis > 13000000 and i%5 == 1 and dis < 200000000 then
				if not ET(lp,v[1] + Vector(0,0,20)) then
					if not ET(v[1] + Vector(0,0,20),lp) then
						table.insert(eyes,v[1])
					end
				end
			end
		end
	end
end)
local m = Material("sprites/orangecore1")
local cos = math.cos
local mt = {"particle/smokesprites_0005","particle/smokesprites_0010","particle/smokesprites_0012"}
hook.Add("PostDrawTranslucentRenderables","StormFox - HappyHalloween",function()
	if not StormFox.GetAllONodes then return end
	if not StormFox.EFEnabled() then return end
	local con = GetConVar("sf_enablespooky")
	if con:GetInt() ~= 1 then return end
	local lp = LocalPlayer():GetPos()
	local ml = StormFox.GetData("MapLight",100)
	if ml >= 20 then return end

	surface.SetMaterial(m)
	
	local tt = CurTime()
	for i,v in ipairs(eyes) do
		local dis = lp:DistToSqr(v)
		local alp = math.Clamp((dis - 7000000) / 133333,0,75) * (1 - ml / 20)
		surface.SetDrawColor(255,255,255,alp)
		local t = (tt + (i * 0.1))%3
		local pos = v + Vector(0,0,20 + i * 1)
		local a = (pos - lp):Angle()
		local s = 1
		if t < 0.5 then
			s = cos(t * 14)
		end
		local n = 1 + (i % (#mt - 1) )
		local str = mt[n]
		render.SetMaterial(Material(str))
		--cam.IgnoreZ(false)
		render.DrawBeam(v,pos + Vector(0,0,80),150,0.3,1,Color(0,0,0,alp*4))
		local v = pos + a:Up() * 10
		render.DrawSprite(v + a:Right()* - 10,20,20*s,Color(255,255,255,alp))
		render.DrawSprite(v + a:Right()* 10,20,20 *s,Color(255,255,255,alp))

		--cam.IgnoreZ(false)
	end
end)