
-- Local functions
	local util_TraceLine = util.TraceLine
	local function ET(pos,pos2,mask)
		local t = util_TraceLine( {
		start = pos,
		endpos = pos + pos2,
		mask = mask,
		filter = LocalPlayer():GetViewEntity() or LocalPlayer()
		} )
		if not t then -- tracer failed, this should not happen. Create a fake result.
			local t = {}
				t.HitPos = pos + pos2
			return t
		end
		t.HitPos = t.HitPos or (pos + pos2)
		return t
	end
	local max,min,clamp,cos,sin,rad,ceil,approach = math.max,math.min,math.Clamp,math.cos,math.sin,math.rad,math.ceil,math.Approach
--[[-------------------------------------------------------------------------
Breath
---------------------------------------------------------------------------]]
	local emit
	local con = GetConVar("sf_enable_breath")
	local m_mats = {(Material("particle/smokesprites_0001")),(Material("particle/smokesprites_0002")),(Material("particle/smokesprites_0003"))}
	local function breath(ply,size)
		if not StormFox.EFEnabled() then return end
		if not ply:Alive() then return end
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
			local ang,pos = EyeAngles(),StormFox.GetEyePos()
			mpos = {Pos = pos + ang:Forward() * 3 - ang:Up() * 2,Ang = ang}
		end
		if not mpos or not mpos.Pos then return end
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
		if not con:GetBool() then return end
		if not genabled then return end
		if (ply._sf_breath or 0) > SysTime() then return end
		local len = ply:GetVelocity():Length()
		local t = clamp(1 - (len / 100),0.2,1)
			ply._sf_breath = math.Rand(t,t * 2) + SysTime()
		breath(ply,5 + (len / 100))
	end)
	hook.Add("Think","StormFox - CBreath",function()
		if not con:GetBool() then return end
		if StormFox.GetCalcViewResult().drawviewer then return end -- 3th person
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
--[[-------------------------------------------------------------------------
HUD messages
---------------------------------------------------------------------------]]
	local msg,msg_t = nil,0
	function StormFox.HUDMessage(smsg,time)
		msg_t = CurTime() + (time or 1)
		msg = smsg
	end
	hook.Add("HUDPaint","StormFox_HUDMessages",function()
		if not msg then return end
		if msg_t < CurTime() then return end
		draw.DrawText(msg,"mgui_default",ScrW() / 2 - 1,ScrH() / 2 - 49,Color(0,0,0),1)
		draw.DrawText(msg,"mgui_default",ScrW() / 2,ScrH() / 2 - 50,Color(255,255,255),1)
	end)
--[[-------------------------------------------------------------------------
Rain puddles
---------------------------------------------------------------------------]]
	local puddle_texture = {(Material("decals/decalkleinerpuddle001a"))}
	local ice_texture = {(Material("models/props/snow/icefield_01")),(Material("models/props/snow/icefield_02")),(Material("models/props/snow/icefield_03"))}
	local distance = 3000^2
	local min_distance = 600^2
	-- Get puddle positions and cache them if valid
		local abs,angdiff = math.abs,math.AngleDifference
		local function GetDiffrent(a,b)
			return abs(a - b)
		end
		local smooth = 6
		local function IsFlatNormal(vec)
			local ang = vec:Angle()
			local pdiff = abs(angdiff(ang.p,-90))
			local rdiff = abs(angdiff(ang.r,0))
			if pdiff > smooth then return false end
			if rdiff > smooth then return false end
			return true
		end
		local nodez = {}
		local invalid_protection = false
		local de_select = 6 -- 1/6
		local cache_t = 0
		local function GetNodes()
			if not StormFox.AIAinIsValid() or invalid_protection then return {} end
			if cache_t < 0 then
				if #nodez > 0 then return nodez end
			elseif cache_t > CurTime() then -- Wait a bit
				if #nodez > 0 then return nodez end
			end
			local outdoor_nodes,invalid = StormFox.GetAIAllNNodes( 2, true, 96 / 2 ) -- Get a list of nodes outside (hull 96)
			-- Make sure to call it again a bit later, in case its invalid
				if invalid then
					cache_t = CurTime() + 2
				else
					cache_t = -1
					StormFox.Msg(StormFox.Language.Translate("sf_generating.puddles"))
				end
			for _,node_id in pairs(outdoor_nodes) do
				if node_id % de_select == 0 then continue end -- Remove a few
				local pos = StormFox.GetAINodePos(node_id)
				local close = false
				for _,data in pairs(nodez) do
					if data[1]:DistToSqr(pos) < min_distance then
						close = true
						break
					end
				end
				if close then continue end

				local tr = ET(pos + Vector(0,0,30),Vector(0,0,-2000),mask)
				local puddle_pos = pos
				-- Check if flat area
					if not IsFlatNormal(tr.HitNormal) then continue end
				-- Trace 2 points
					local tMax = ET(pos + Vector(48,48,30),Vector(48,48,-60),mask)
					local tMin = ET(pos + Vector(-48,-48,30),Vector(-48,-48,-60),mask)
				-- Check if traceHit
					if not tMax.Hit or not tMin.Hit then continue end
				-- Check the hitpos
					if GetDiffrent(tMax.HitPos.z,puddle_pos.z) > 5 then continue end
					if GetDiffrent(tMin.HitPos.z,puddle_pos.z) > 5 then continue end
				-- Trace last 2 points
					local tMax = ET(pos + Vector(-48,48,30),Vector(-48,48,-60),mask)
					local tMin = ET(pos + Vector(48,-48,30),Vector(48,-48,-60),mask)
				-- Check if traceHit
					if not tMax.Hit or not tMin.Hit then continue end
				-- Check the hitpos
					if GetDiffrent(tMax.HitPos.z,puddle_pos.z) > 5 then continue end
					if GetDiffrent(tMin.HitPos.z,puddle_pos.z) > 5 then continue end
				-- Looks like a valid position
				table.insert(nodez,{puddle_pos,tr.HitNormal:Angle():Up():Angle()})
			end
			if #nodez <= 0 then
				invalid_protection = true
				StormFox.Msg("No valid rainpuddle location on the map.")
			end
			return nodez
		end
	-- Node scanner (Get all nodes nearby .. costly, but cached)
		near_nodes = {}
		local function UpdateNearNodes(procent_wet)
			table.Empty(near_nodes)
			local lp = StormFox.GetCalcViewResult().pos
			local n = 10 * (1 - procent_wet) -- 10 is dry, 0 is wet
			for id,data in pairs(GetNodes()) do
				if (id % 10) + 1 < n then continue end
				local pos,ang = data[1],data[2]
				if lp:DistToSqr(pos) > distance then continue end
				pos = pos + ang:Up()
				table.insert(near_nodes,{pos,ang,id})
			end
			return near_nodes
		end
		local puddleamount = 0
		local puddlesize = 0
		local ice = false
		local function HandlePuddles()
			local setting = GetConVar("sf_rainpuddle_enable")
			local temp = StormFox.GetNetworkData("Temperature",0)
				ice = temp <= -3
			if not setting or ice then
				puddleamount = 0
			elseif setting:GetBool() then
				local gauge = clamp(StormFox.GetData("Gauge",0) / 10,0,1)
				puddleamount = approach(puddleamount,gauge,0.2 * 10) -- Slowly .. over 10 seconds
			else
				puddleamount = 0
			end
			if puddleamount < 0.1 then
				-- No puddles
				return false
			end
			-- Update near_nodes
				UpdateNearNodes(puddleamount)
			return true
		end
		timer.Create("Stormfox - PuddleCreator",2,0,HandlePuddles)
		hook.Add("PreDrawOpaqueRenderables","StormFox - PuddleRender",function()
			if puddleamount <= 0 and puddlesize > 0 then
				puddlesize = max(0,puddlesize - FrameTime() / 100)
			elseif puddleamount > 0 and puddlesize < 1 then
				local n = FrameTime() / 40 * (1.1-puddlesize)
				puddlesize = min(1,puddlesize + n)
			end
			if puddlesize <= 0 then return end
			for _,data in pairs(near_nodes) do
				local tex,node_id = nil,data[3]
				if ice and false then
					local tex_id = (node_id % #ice_texture) + 1
					tex = ice_texture[tex_id]
				else
					local tex_id = (node_id % #puddle_texture) + 1
					tex = puddle_texture[tex_id]
				end
				render.SetMaterial(tex)
				local s = puddlesize * (1 + (node_id % 2)) * 100
				render.DrawQuadEasy(data[1],data[2]:Up(),s,s,Color(255,255,255),node_id * 19 % 360)
			end
		end)
--[[-------------------------------------------------------------------------
Snow footsteps
---------------------------------------------------------------------------]]
	local footsteps = false
	local footstep_maxlife = 30
	local footstep_dis = 2000^2
	timer.Create("StormFox.Footstep toggle",2,0,function()
		footsteps = false
		if GetConVar("sf_footsteps_enable"):GetBool() ~= true then
			table.Empty(STORMFOX_SNOW_FEETS)
			return
		end
		footsteps = true
	end)
	STORMFOX_SNOW_FEETS = STORMFOX_SNOW_FEETS or {}
	local doublestep = {}
	local function AddFootstep(ply,pos,foot,fw)
		foot = foot or 0
		if not fw then fw = 0 end
		local lp = StormFox.GetCalcViewResult().pos
		if lp:DistToSqr(pos) > footstep_dis then return end -- Too far away
		-- Look for the foot position (Ignore this .. the feet is always delayed)
		-- Foot calc
			local velspeed = ply:GetVelocity():Length()
			local y = rad(ply:GetAngles().y)
			local fy = y + rad((foot * 2 - 1) * -90)
			local l = 5 * ply:GetModelScale()
			pos = ply:GetPos() + Vector(cos(fy) * l + cos(y) * (l + fw),sin(fy) * l + sin(y) * (l + fw),0)
		-- Find impact
			local tr = ET(pos + Vector(0,0,20),Vector(0,0,-40),MASK_SOLID_BRUSHONLY)
			if not tr.Hit then return end -- In space?
		-- Double print
			if doublestep[ply] then
				local t = doublestep[ply]
				doublestep[ply] = nil
				if t > CurTime() then
					local r = math.random(0,1) * 2 - 1
					AddFootstep(ply,pos,1 - foot,5 * r)
				end
			end
		-- If no bone_angle then angle math
			local trAng = tr.HitNormal:Angle()
			local footpos = tr.HitPos
			local ang = trAng
			ang:RotateAroundAxis(ang:Right(),-90)
			ang:RotateAroundAxis(ang:Up(),-ang.y + ply:EyeAngles().y - 90)
		-- Delete old feet
			local con = GetConVar("sf_footsteps_max")
			local max_footsteps = 200
			if con then max_footsteps = con:GetInt() end
			if #STORMFOX_SNOW_FEETS >= max_footsteps then
				table.remove(STORMFOX_SNOW_FEETS,1)
			end
		-- Create new print

		-- Get the snow
			local life = footstep_maxlife * (1 - (StormFox.GetData("Gauge",1) / 20))
		-- 	pos 	ang 	foot 	scale 	life 	multi
		table.insert(STORMFOX_SNOW_FEETS,{footpos,ang,foot,ply:GetModelScale() or 1,CurTime() + life,clamp(velspeed / 200,1,3)})
	end
	hook.Add("StormFox.Footstep","StormFox.Footstepprint",function(ply,snd,foot)
		if not footsteps then return end
		if not string.match(snd,"[sS][nN][oO][wW]") then return end
		AddFootstep(ply,ply:GetPos(),foot)
	end)
	local mat = {Material("stormfox/effects/foot_hq.png"),Material("stormfox/effects/foot_hql.png"),Material("stormfox/effects/foot_m.png"),Material("stormfox/effects/foot_s.png")}
	local function getMat(q,foot)
		if q == 1 then
			if foot == 0 then
				return mat[2]
			else
				return mat[1]
			end
		end
		return mat[q + 1]
	end
	hook.Add("PreDrawOpaqueRenderables","StormFox - Footprints",function()
		if not footsteps then return end
		local lp = StormFox.GetCalcViewResult().pos
		local setting = GetConVar("sf_footsteps_distance")
		if not setting then return end
		local render_distance = (setting:GetInt() / 4)^2
		local del = {}
		for k,v in pairs(STORMFOX_SNOW_FEETS) do
			-- 	pos 	ang 	foot 	scale 	life 	multi
			local pos,ang,foot,scale,life,multi = v[1],v[2],v[3],v[4],v[5],v[6]
			local blend = clamp((life - CurTime()) * multi / 10,0,1)
			if blend <= 0 then
				table.insert(del,k)
			else
				local q = min(ceil(lp:DistToSqr(pos) / render_distance),4)
				if q >= 4 then continue end
				cam.Start3D2D( pos + Vector(0,0,q / 3), ang, scale )
					surface.SetDrawColor(0,0,0,min(blend * 255,255))
					surface.SetMaterial(getMat(q,foot))
					for i=1,multi do
						if foot == 0 and q > 1 then
							surface.DrawTexturedRectUV(-4,-10,6,14,1,0,0,1)
						else
							surface.DrawTexturedRect(-4,-10,6,14)
						end
					end
				cam.End3D2D() 
			end
		end
		for i=#del,1,-1 do
			table.remove(STORMFOX_SNOW_FEETS,del[i])
		end
	end)
	hook.Add("OnPlayerHitGround","StormFox - LandfootprintFix",function(ent,water,float,speed)
		if water or float then return end
		if speed < 192 then return end
		doublestep[ent] = CurTime() + 1
	end)
--[[-------------------------------------------------------------------------
Default texture removal
---------------------------------------------------------------------------]]
	local removeList = {"effects/fog_d1_trainstation_02"}
	for k,v in pairs(removeList) do
		Material(v):SetInt("$alpha",0)
	end

--[[-------------------------------------------------------------------------
Aurora borealis (Not done yet)
---------------------------------------------------------------------------]]
	if true then return end
	local chain_link = {}
	--TimedCos( number frequency, number min, number max, number offset ) 
	local TimedCos = TimedCos
	local chain_length = 30
	local broad_length = 7
	local function YawVector(yaw,length)
		local yr = rad(yaw)
		return Vector(cos(yr),sin(yr),0) * length
	end
	hook.Add("StormFox - RenderAboveSkies","StormFox - Aurora borealis",function(c_pos, map_center)
		if true then return end
		local r = rad(40)
		local l = broad_length * chain_length / 2
		local sV = YawVector(r + 180,l) + Vector(0,0,20)
		local n = 10
		local z = 20
		local ii = 360 / chain_length

		local light_sin_length = 20
		render.SetMaterial(Material("stormfox/effects/ab.png"))
		cam.Start3D( Vector( 0, 0, 0 ), EyeAngles() ,nil,nil,nil,nil,nil,0,32000)
			local moveYaw = 0
			for i2=1,1 do
				local last_pos = sV
				local lastYaw = r - i2 * 3.5
				for i=2,chain_length do
					local alpha = 200

					local pos = last_pos + YawVector(lastYaw,broad_length)
					
					local v1,v2,v3,v4 = pos + Vector(0,0,z),last_pos + Vector(0,0,z),last_pos,pos
						render.DrawQuad(v2,v1,v4,v3,Color( 255, 255, 255, alpha ))
						render.DrawQuad(v1,v2,v3,v4,Color( 255, 255, 255, alpha ))

				--	render.DrawLine(pos,last_pos,Color(255,255,255),true)
					--render.DrawBox(pos,Angle(0,0,0),Vector(-1,-1,-1) * n,Vector(1,1,1) * n,Color(0,255,0),true)
					last_pos = pos
					
					moveYaw = cos(i + i2 * 90)
					if i%8 == 0 then
						moveYaw = -lastYaw
					end
					lastYaw = lastYaw + sin(i) * light_sin_length
				end
				
			end
		cam.End3D()
		
	end)
	--[[-------------------------------------------------------------------------
	local last
				--print(a)
				for i=1,chain_length do
					local ai = i * ii
					local ai2 = cos(rad(ai)) + 1
					local alpha = 100 - ai2 * 50
					--print(i,alpha)
					local li = i * 0.002 * cos(i2)
					local len = broad_length * i
					local pos = sV + Vector(cos(r - li) * len,sin(r - li) * len,0) + chainOffset(i + i2)
					if last then
					--	render.DrawLine(pos,last,Color(255,255,255))
						local pz = Vector(0,0,0)
						render.SetMaterial(Material("stormfox/effects/ab.png"))
						local v1,v2,v3,v4 = last + Vector(0,0,z) + pz,pos + Vector(0,0,z) + pz,pos + pz,last + pz
						render.DrawQuad(v1,v2,v3,v4,Color( 255, 255, 255, alpha ))
						render.DrawQuad(v2,v1,v4,v3,Color( 255, 255, 255, alpha ))
					end
					last = pos
				--	render.DrawBox(pos,Angle(0,0,0),Vector(-1,-1,-1) * n,Vector(1,1,1) * n,Color(0,255,0),true)
				end
	---------------------------------------------------------------------------]]