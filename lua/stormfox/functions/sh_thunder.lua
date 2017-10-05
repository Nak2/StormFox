
local ran,rand = math.random,math.Rand
if SERVER then

	local function ETHull(pos,pos2,size,mask)
		local t = util.TraceHull( {
			start = pos,
			endpos = pos + pos2,
			maxs = Vector(size,size,4),
			mins = Vector(-size,-size,0),
			mask = mask
			} )
		t.HitPos = t.HitPos or pos + pos2
		return t
	end
	local function ET(pos,pos2,mask)
		local t = util.TraceLine( {
			start = pos,
			endpos = pos + pos2,
			mask = mask
			} )
		t.HitPos = t.HitPos or (pos + pos2)
		return t,t.HitSky
	end
	local function EntityHit(ent)
		if not ent or not IsValid(ent) then return end
		local effectdata = EffectData()
		effectdata:SetOrigin( ent:GetPos() )
		effectdata:SetEntity(ent)
	    effectdata:SetMagnitude(2)
	    effectdata:SetScale(3)
	    for i=1,100 do
	    	util.Effect( "TeslaHitboxes", effectdata, true, true )
	    end
		

		local ctd = DamageInfo()
			ctd:IsDamageType(DMG_SHOCK)
			ctd:SetDamage(ran(90,200))
			local vr = VectorRand()
			vr.z = math.abs(vr.z)
			ctd:SetDamageForce(vr * 1000)
			ctd:SetInflictor(game.GetWorld())
			ctd:SetAttacker(game.GetWorld())
		ent:TakeDamageInfo(ctd)
	end
	local function CalcLightningStrike(pos,size)

		local line = {}
		table.insert(line,pos)
		local bottom = ET(pos,Vector(0,0,-64000))
		if not bottom.Hit then return {} end
		local distance = (pos.z - bottom.HitPos.z)
		local joints = distance / 1000
		local n = joints * 1.6
		local Sway = 120
		local olddir = Vector(0,0,-1)
		for i = 1,n or 10 do
			Sway = 120 - i * 10
			local hitbox_size = 512 - i * 12
			local randir = Angle(ran(-Sway,Sway) + 90,ran(360),ran(-Sway,Sway)):Forward() + olddir
				randir:Normalize()
				randir.z = -math.abs(randir.z)
			olddir = randir
			local trace = ETHull(pos,randir * 1000,hitbox_size)
			if IsValid(trace.Entity) and not trace.Entity:IsWorld() then
				table.insert(line,trace.Entity:GetPos())
				return line,trace.Entity
			elseif trace.HitPos.z > pos.z - 50 then
				table.insert(line,trace.HitPos)
				return line,trace.Entity
			else
				pos = trace.HitPos
				table.insert(line,trace.HitPos)
			end
		end
		return line
	end

	local nextHit = 0
	util.AddNetworkString("StormFox - ThunderLight")
	hook.Add("Think","StormFox - Thunder",function()
		if nextHit > CurTime() then return end
			nextHit = SysTime() + math.random(10,20)
		if not StormFox.GetNetworkData("Thunder",false) then return end
		local con = GetConVar("sf_disablelightningbolts")
		if math.random(10) < 4 or con:GetBool() then
			StormFox.CLEmitSound("ambient/atmosphere/thunder" .. math.random(3,4) .. ".wav",nil,0.5)
		else
			local thunder_length = math.Rand(1,2) / 10
			local thunder_light = math.random(150,100)
			-- Create lightning bolt
			local thundersize = 512
			local mmax = StormFox.MapOBBMaxs()
			local mmin = StormFox.MapOBBMins()
			local pos = Vector(ran(mmin.x,mmax.x),ran(mmin.y,mmax.y),340000)
			local tr = ET(pos,Vector(0,0,-340000 + mmin.z))
			if not tr.HitSky then return end
				pos = tr.HitPos + Vector(0,0,-50)
			StormFox.CLEmitSound("ambient/atmosphere/thunder" .. math.random(1,2) .. ".wav",nil,0.5)
			local lightningarray,HitEntity = CalcLightningStrike(pos,thundersize)
			EntityHit(HitEntity)
			net.Start("StormFox - ThunderLight")
				net.WriteFloat(thunder_length)
				net.WriteFloat(thunder_light)
				net.WriteFloat(#lightningarray)
				for _,v in ipairs(lightningarray) do
					net.WriteVector(v)
				end
			net.Broadcast()
		end
	end)
else
	local lightning = {}
	net.Receive("StormFox - ThunderLight",function()
		local thunder_length = net.ReadFloat()
		local thunder_light = net.ReadFloat()
		StormFox.SetData("ThunderLight",thunder_light)
		StormFox.SetData("ThunderLight",0,thunder_length)
		local n = net.ReadFloat()
		local l = {}
			l.life = SysTime() + 0.3
		local Sway = 10
		local old = Vector(0,0,0)
		for i = 1,n do
			local randir = Angle(ran(-Sway,Sway) + 90,ran(360),ran(-Sway,Sway))
			local new = net.ReadVector()
			if old then
				randir = randir:Forward() + (new - old):Angle():Forward() * 2
			else
				randir = randir:Forward()
			end
			old = new
			local n = ran(0,1)
			table.insert(l,{new,rand(0.5,1),randir,n})
		end
		l.renderid = 0
		print("LIGHTNOT " .. #l)
		if l[#l] and l[#l][1] then
			local dlight = DynamicLight( 1 )
			if ( dlight ) then
				dlight.pos = l[#l][1]
				dlight.r = 255
				dlight.g = 255
				dlight.b = 255
				dlight.brightness = 6
				dlight.Decay = 1000
				dlight.Size = 256 * 4
				dlight.DieTime = CurTime() + 0.5
			end
		end
		table.insert(lightning,l)
	end)
	local tex = {(Material("stormfox/effects/lightning.png")),(Material("stormfox/effects/lightning2.png")),(Material("stormfox/effects/lightning3.png"))}
	local texend = {(Material("stormfox/effects/lightning_end.png")),(Material("stormfox/effects/lightning_end2.png"))}
	local sys = SysTime
	local cos = math.cos
	hook.Add("PostDrawOpaqueRenderables","StormFox - Lightning",function(_,sky)
		local removes = {}
		local bap = ran(2,4)
		for id,data in ipairs(lightning) do
			if data.life < SysTime() then
				table.insert(removes,id)
			else
				local a = cos(sys() * 20)
				--PrintTable(tex)
				render.SetMaterial(tex[1])
				render.StartBeam(#data)
				for i = 1, #data do
					local vec = data[i][1]
					local tp = 1 / #data * i
						render.AddBeam( vec, 100, tp, Color(255,255,255,a * 25 + 50) )
						--render.SetMaterial(Material("stormfox/moon_glow"))
						--render.DrawSprite(vec,400,400,Color(255,255,255,a * 25 + 150))
				end
				render.EndBeam()
				for i = 1, #data do
					local vec = data[i][1]
					local tp = 1 / #data * i
					local n = i % #texend + 1
					render.SetMaterial(texend[n])
					local w,h = texend[n]:Width(),texend[n]:Height()
						render.DrawBeam( vec, vec + data[i][3] * h  * data[i][2], w * data[i][2], 0, 1, Color(255,255,255,a * 25 + 50) )
						--render.SetMaterial(Material("stormfox/moon_glow"))
						--render.DrawSprite(vec,400,400,Color(255,255,255,a * 25 + 150))
				end
				
			end
		end
		for _,id in ipairs(removes) do
			table.remove(lightning,id)
		end
	end)
end