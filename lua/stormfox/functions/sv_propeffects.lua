local scan_id = 1
local con = GetConVar("sf_disable_windpush")
local count = table.Count


local max = math.max
local windNorm,wind = Vector(0,0,1),0
-- Mini functions
	local function ET(pos,pos2,mask,filter)
		local t = util.TraceLine( {
			start = pos,
			endpos = pos + pos2,
			mask = mask,
			filter = filter
			} )
		t.HitPos = t.HitPos or (pos + pos2)
		return t,t.HitSky
	end
	timer.Create("StormFox - WindPushUpdater",1,0,function()
		wind = StormFox.GetNetworkData("Wind",0)
		local windangle = StormFox.GetNetworkData("WindAngle",0)
		windNorm = Angle(0,windangle,0):Forward() * -wind
		windNorm.z = windNorm.z + max(wind * 0.4,1)
		windNorm:Normalize()
	end)
	local function GetEffected()
		local t = ents.FindByClass("prop_*")
		table.Add(t,ents.FindByClass("gmod_*"))
		table.Add(t,ents.FindByClass("npc_grenade_frag"))
		return t
	end

local move_tab = {}
-- Function
	function InWind(ent)
		if wind <= 6 then return end
		local tr = ET(ent:GetPos(),windNorm * 640000,MASK_SHOT,ent)
		return tr.HitSky,windNorm
	end
	local function CheckProp(ent) -- Check and add into "Move props" table
		if not ent then return end
		if wind <= 6 then return end
		if not IsValid(ent) then return end
		if move_tab[ent] then return end -- Already in
		if not IsValid(ent:GetPhysicsObject()) then return end -- No physics
		if not ent:GetPhysicsObject():IsMoveable() and wind <= 20 then return end -- Ignore
		if InWind(ent) then
			move_tab[ent] = 40
			return true
		end
		return false
	end
	function fmove_tab() return move_tab end

-- Scan for props to be effected
	local scanList,index = {},0
	timer.Create("StormFox - ScanProps",1,0,function()
		if count(move_tab) > 400 then return end
		if not scanList[index] then
			-- Create scanlist
			scanList = GetEffected()
			index = 1
		else
			-- Scan scanlist
			for i = index,index + 100 do
				if scanList[index] then
					CheckProp(scanList[index])
					index = index + 1
				else
					break
				end
			end
		end
	end)

-- Add newly spawned props
hook.Add("PlayerSpawnedProp","StormFox - PropCreate",function(ply,model,ent)
	if con:GetBool() then return end
	if not IsValid(ent) then return end
	CheckProp(ent)
end)

-- Effect props
local t = 0
hook.Add("Think","StormFox - EffectProps",function()
	if con:GetBool() then return end
	local r = {}
	for ent,v in pairs(move_tab) do
		if not ent or not IsValid(ent) then
			-- Remove ent
			table.insert(r,ent)
		elseif not InWind(ent) then
			-- Check
			if move_tab[ent] < 1 then
				-- Remove ent
				table.insert(r,ent)
			else
				move_tab[ent] = move_tab[ent] - 1
			end
		else -- Move prop
			move_tab[ent] = 10
			-- Get prop data
				local pys = ent:GetPhysicsObject()
				if not IsValid(pys) then -- SOMETHING IS WRONG!
					table.insert(r,ent) -- Remove asap
					break
				end
				local vol = pys:GetSurfaceArea()
				if not vol then
					table.insert(r,ent) -- Remove asap
					break
				end
			-- Undfreeze if wind > 20
				if not pys:IsMoveable() and wind > 20 then
					pys:EnableMotion(true)
				end
			-- Unweld if wind > 30
				if wind > 30 and constraint.FindConstraint( ent, "Weld" ) then
					ent:EmitSound("physics/wood/wood_box_break" .. math.random(1,2) .. ".wav")
					constraint.RemoveConstraints( ent, "Weld" )
				end
			-- Do movement
			local pNeeded = vol / 10
				pys:Wake()
				pys:ApplyForceCenter(-windNorm * pNeeded)
			-- Take damage (To stop all the wood props)
				if not ent:IsVehicle() and t <= CurTime() and wind > 40 then
					t3 = CurTime() + 0.5
					ent:TakeDamage(1,game.GetWorld(),game.GetWorld())
				end
		end
	end
	if #r >= 0 then
		for i = #r,1,-1 do
			move_tab[r[i]] = nil
		end
	end
end)

