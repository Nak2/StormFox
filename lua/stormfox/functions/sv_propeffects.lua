local scan_id = 1
local con = GetConVar("sf_windpush")
local count = table.Count
local max,abs,min = math.max,math.abs,math.min

local function GetEffectedEntities()
	local tab = {}
	for _,ent in pairs(ents.GetAll()) do
		if not IsValid(ent) then continue end
		local class = ent:GetClass()
		if string.match(class,"^prop_") or string.match(class,"^gmod_") or string.match(class,"npc_grenade_frag") or class == "sent_ball" then
			table.insert(tab,ent)
		end
	end
	return tab
end

local move_tab = {}
-- Function
	-- Check if we can move the entity
		local function CanMoveEnt(ent,wind,breakconstraints)
			if not StormFox.IsEntityInWind then return end
			local pys = ent:GetPhysicsObject()
			if not IsValid(pys) then return false end
			if not pys:IsMoveable() and not (breakconstraints or wind < 20) then
				return false
			end
			if not StormFox.IsEntityInWind(ent) then return false end
			return true
		end
	-- Check and add into "Move props" table
		local function CheckProp(ent,wind,breakconstraints) 
			if not ent then return end
			if not IsValid(ent) then return end
			if move_tab[ent] then return end -- Already in
			if not IsValid(ent:GetPhysicsObject()) then return end -- No physics
			if not CanMoveEnt(ent,wind,breakconstraints) then return end
				move_tab[ent] = 20
		end

-- Scan for props to be effected
	local scanList,index = {},0
	timer.Create("StormFox - ScanProps",1,0,function()
		if count(move_tab) > 400 then return end
		if not StormFox then return end
		if not StormFox.GetNetworkData then return end
		local wind = StormFox.GetNetworkData("Wind",0)
		local breakconstraints = StormFox.GetMapSetting("wind_breakconstraints",true)
		if not scanList[index] then
			-- Create scanlist
			scanList = GetEffectedEntities()
			index = 1
		else
			-- Scan scanlist
			for i = index,index + 100 do
				if scanList[index] then
					CheckProp(scanList[index],wind,breakconstraints)
					index = index + 1
				else
					break
				end
			end
		end
	end)

-- Add newly spawned props
hook.Add("PlayerSpawnedProp","StormFox - PropCreate",function(ply,model,ent)
	if not con:GetBool() then return end
	if not IsValid(ent) then return end
	local wind = StormFox.GetNetworkData("Wind",0)
	local breakconstraints = StormFox.GetMapSetting("wind_breakconstraints",true)
		CheckProp(ent,wind,breakconstraints)
end)

-- Effect props
local t = 0
hook.Add("Think","StormFox - EffectProps",function()
	if not con:GetBool() then return end
	--local constraint = StormFox.GetMapSetting("wind_breakconstraints",true)
	local r = {}
	local wind = StormFox.GetNetworkData("Wind",0)
	local breakconstraints = StormFox.GetMapSetting("wind_breakconstraints",false)
	local windnorm = StormFox.GetWindNorm()
	if wind <= 0 then 
		table.Empty(move_tab)
		return 
	end
	for ent,fall_safe in pairs(move_tab) do
		if not ent or not IsValid(ent) then 	-- Check if valid
			-- Remove ent
			table.insert(r,ent)
		elseif not CanMoveEnt(ent,wind,breakconstraints) then -- Check if in wind.
			-- Check fall_safe
				if fall_safe < 1 then
					table.insert(r,ent)
				else
					move_tab[ent] = fall_safe - 1
				end
		else -- Move prop
			local pys = ent:GetPhysicsObject()
			if not IsValid(pys) then -- SOMETHING IS WRONG!
				table.insert(r,ent) -- Remove asap
				continue
			end
			-- Get prop data
				local vol = pys:GetSurfaceArea()
				if not vol then
					table.insert(r,ent) -- Remove asap
					continue
				end

			if breakconstraints then
			-- Unfreese/unweld
				if not pys:IsMoveable() and wind > 20 then
					pys:EnableMotion(true)
				end
			-- Unweld if wind > 30
				if wind > 30 and constraint.FindConstraint( ent, "Weld" ) then
					ent:EmitSound("physics/wood/wood_box_break" .. math.random(1,2) .. ".wav")
					constraint.RemoveConstraints( ent, "Weld" )
				end
			end
			-- Do movement
		--	if ent:GetModel() ~= "models/props_lab/blastdoor001c.mdl" then continue end
			local windPush = windnorm * 5.92 * (vol / 50)
			local Acc = windPush:Length() / pys:GetMass()
			local windRequ = pys:GetInertia()
				windRequ = max(windRequ.x,windRequ.y)-- * pys:GetMass()
			if max(abs(windPush.x),abs(windPush.y)) < windRequ then
				continue
			end
				pys:Wake()
				pys:ApplyForceCenter(windPush)
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

