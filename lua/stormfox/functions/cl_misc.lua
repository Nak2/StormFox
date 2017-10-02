
--[[-------------------------------------------------------------------------
Breath
---------------------------------------------------------------------------]]
	local emit
	local m_mats = {(Material("particle/smokesprites_0001")),(Material("particle/smokesprites_0002")),(Material("particle/smokesprites_0003"))}
	local function breath(ply,size)
		if size <= 0 then return end
		if ply:WaterLevel() >= 3 then return end
		if not emit then
			emit = ParticleEmitter(LocalPlayer():GetPos(),false)
		else
			emit:SetPos(LocalPlayer():GetPos())
		end
		local mpos
		if GetViewEntity() ~= ply then
			local att = ply:LookupAttachment("mouth")
			if att <= 0 then return end
			mpos = ply:GetAttachment(att)
		else
			local ang,pos = EyeAngles(),EyePos()
			mpos = {Pos = pos + ang:Forward() * 3 - ang:Up() * 2,Ang = ang}
		end
		local p = emit:Add(table.Random(m_mats),mpos.Pos)
			p:SetStartSize(1)
			p:SetEndSize(size)
			p:SetStartAlpha(math.random(25,35))
			p:SetEndAlpha(0)
			p:SetLifeTime(0)
			p:SetGravity(Vector(0,0,4))
			p:SetDieTime(1)
			p:SetLighting(false)
			p:SetRoll(math.random(360))
			p:SetRollDelta(math.Rand(-0.5,0.5))
			p:SetVelocity(mpos.Ang:Forward() * 2 + ply:GetVelocity() / 5)
	end
	local clamp = math.Clamp
	local genabled = false
	hook.Add("PostPlayerDraw","StormFox - Breath",function(ply)
		if not genabled then return end
		if (ply._sf_breath or 0) > SysTime() then return end
		local len = ply:GetVelocity():Length()
		local t = clamp(1 - (len / 100),0.2,1)
			ply._sf_breath = math.Rand(t,t * 2) + SysTime()
		breath(ply,5 + (len / 100))

	end)
	hook.Add("Think","StormFox - CBreath",function()
		genabled = StormFox.GetNetworkData("Temperature",20) < 4 and (StormFox.Env.IsInRain() or StormFox.Env.IsOutside() or StormFox.Env.NearOutside())
		if not genabled then return end
		if not LocalPlayer() then return end
		if GetViewEntity() ~= LocalPlayer() then return end
		local ply = LocalPlayer()
		if (ply._sf_breath or 0) > SysTime() then return end
		local len = ply:GetVelocity():Length()
		local t = clamp(1 - (len / 400),0.2,1)
			ply._sf_breath = math.Rand(t,t * 2) + SysTime()
		breath(ply,5 - (len / 50))
	end)