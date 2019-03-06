local app,abs = math.Approach,math.abs
local max = math.max
local min = math.min
local clamp = math.Clamp
local smoothe,smooths = 10000, 10000
local function fogapp(current,goal,speed)
	if not speed then speed = 1 end
	local dif = abs(current - goal)
	local ap = max(current / 500,1)
	return app(current,goal,ap * speed)
end

local SkyFog = function(scale)
	--if true then return end
	if not scale then scale = 1 end
	if not StormFox.GetData then return end
	if not StormFox.EFEnabled() then return end
	local con = GetConVar("sf_enablefog")
	if con and not con:GetBool() then
		local col = StormFox.GetData("Fogcolor") or StormFox.GetData("SkyBottomColor",Color(255,255,255))
		render.FogColor( col.r,col.g,col.b )
		return
	end
	local col = StormFox.GetData("Fogcolor") or StormFox.GetData("SkyBottomColor",Color(255,255,255))
		--col = Color(0,255,0)
	local outside = StormFox.Env.IsOutside() or StormFox.Env.NearOutside()

	local fogend,fogstart = StormFox.GetData("Fogend",10000)--, StormFox.GetData("Fogstart",10000)
	--local dis = max(abs(smooths - fogstart) / 8,1) ^ 3
	if not outside then
	--	smooths = fogapp(smooths, max(200,fogstart),3)
		smoothe = fogapp(smoothe, max(500,fogend),3)
	else
	--	smooths = fogapp(smooths, fogstart,2)
		smoothe = fogapp(smoothe, fogend)
	end

	render.FogMode( 1 )
	render.FogStart( smoothe / 4 * scale )
	render.FogEnd( smoothe * scale )
	render.FogMaxDensity( StormFox.GetData("Fogdensity",0))


	render.FogColor( col.r,col.g,col.b )
	return true
end
hook.Add("SetupSkyboxFog","StormFox - skyfog",SkyFog)
hook.Add("SetupWorldFog","StormFox - skyworldfog",SkyFog)


--[[  Work in progress


local fogP = {"particle/smokesprites_0007","particle/smokesprites_0008","particle/smokesprites_0012","particle/smokesprites_0013","particle/smokesprites_0014","particle/smokesprites_0015","particle/smokesprites_0016"}
local wind,windA = 0,0
local windV = Vector(0,0,0)
timer.Create("StormFox - FogUPVar",1,0,function()
	wind = StormFox.GetNetworkData("Wind",0)
	windA = StormFox.GetNetworkData("WindAngle",0)
	windV = Angle(0,windA,0):Forward() * wind
end)
local speed = Vector(0,0,0)
timer.Create("StormFox - FogCreator",0.2,0,function()
	--if true then return end
	if true then return end
	if not StormFox.GetCloseONodes then return end -- Check if nodes have loaded yet
	if not IsValid(_SF_FOGEMITTER) then
		_SF_FOGEMITTER = ParticleEmitter(Vector(0,0,0),false)
	end
	local maxParticles = StormFox.GetExspensive() * 200
	local curParticles = _SF_FOGEMITTER:GetNumActiveParticles()
	if curParticles >= maxParticles then return end -- No need
	local t = StormFox.GetCloseONodes(100)
	local EP = StormFox.GetEyePos() + speed

	if #t <= 0 then return end -- No nodes nearby
	speed = LocalPlayer():GetVelocity() * 2
	for i=1,min((maxParticles - curParticles ) / 2,maxParticles / 25) do
	local node = table.Random(t)
	if EP:DistToSqr(node[1]) < 80000 then return end -- Noo close
	if EP:DistToSqr(node[1]) > 2000000 then return end -- Too far
	
		local part = _SF_FOGEMITTER:Add( table.Random(fogP), node[1] + Vector(0,0,node[2] * 0.4) ) -- Create a new particle at pos
		local a = (EP - node[1]):Angle()
			a.r = 90
		if part  then
			part:SetDieTime( clamp(8 - speed:Length() / 60,1,8) ) -- How long the particle should "live"

			part:SetStartAlpha( 155 ) -- Starting alpha of the particle
			part:SetEndAlpha( 0 ) -- Particle size at the end if its lifetime

			local c = StormFox.GetData("Fogcolor") or StormFox.GetData("SkyBottomColor",Color(255,255,255))
			part:SetColor(c.r,c.g,c.b)

			part:SetStartSize( node[2] * 1 ) -- Starting size
			part:SetEndSize( node[2] * 1.1 ) -- Size when removed
			part:SetRoll(0)

			part:SetGravity( Vector( 0, 0,math.random(1,4) ) ) -- Gravity of the particle
			local v = VectorRand()
				v.z = 0
			part:SetVelocity( v * 40 + windV * 10 ) -- Initial velocity of the particle
			part:SetLighting(false)

			part:SetNextThink( CurTime() ) -- Makes sure the think hook is used on all particles of the particle emitter
			part:SetThinkFunction( function( pa )
				local d = (part:GetPos():DistToSqr(EyePos() + speed)) / 80000 - 0.3
					-- d < 1= Inside particle
					-- d > 1 = Outside particle
				if d < 1 then
					local timeProcent = part:GetLifeTime() / part:GetDieTime()
					local gt = 1 - d
					if gt > timeProcent then
			--			print("Lower time", gt)
						part:SetLifeTime(max(part:GetLifeTime(),part:GetDieTime() * gt))
					end
					part:SetNextThink( CurTime() + 0.1 )
				elseif d > 24 then
					part:SetLifeTime(part:GetDieTime() + 2)
					part:SetNextThink( CurTime() + 10 )
			--		print("Die")
				else
					local a = clamp((part:GetLifeTime() - 1) * 405,0,205)
					if a < 205 then
						part:SetStartAlpha( a )
						part:SetNextThink( CurTime() + 0.1 )
					else
						part:SetNextThink( CurTime() + 0.7 )
					end
					
				end
			end)
		end
	end 
	--StormFox.GetCloseONodes(minimumsize)
end)]]