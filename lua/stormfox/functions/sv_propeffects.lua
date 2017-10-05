
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

local max = math.max
local function GetWindNorm()
	local wind = StormFox.GetNetworkData("Wind",0)
	local windangle = StormFox.GetNetworkData("WindAngle",0)
	windNorm = Angle(0,windangle,0):Forward() * -wind
	return windNorm,wind
end

local scan_id = 1
local con = GetConVar("sf_disable_windpush")
local move_tab = {}
function getmove_tab()
	return move_tab
end

local function GetEffected()
	local t = ents.FindByClass("prop_*")
	table.Add(t,ents.FindByClass("gmod_*"))
	return t
end
local scanList = {}
local t = CurTime() + 1
local t2 = CurTime()
hook.Add("Think","StormFox - PropImpact",function()
	if con:GetBool() then return end
	if t2 > CurTime() then return end
		t2 = CurTime() + 0.2
	-- Props moving
	local norm,wind = GetWindNorm()
	if wind <= 6 then return end
	for ent,_ in pairs(move_tab) do
		if not IsValid(ent) then
			move_tab[ent] = nil
		else
			local tr = ET(ent:GetPos(),Vector(0,0,1) * 640000,MASK_SHOT,ent)
			if not tr.HitSky then
				move_tab[ent] = nil
			else
				local pys = ent:GetPhysicsObject()
				local vol = pys:GetVolume()
				local mass = pys:GetMass()
				local pNeeded = vol / mass / 63
				if not pys:IsMoveable() and wind > 15 then
					pys:EnableMotion(true)
				end
				if wind >= pNeeded then
					local m = 1 + pNeeded - wind
					pys:ApplyForceCenter(pys:GetMass() / 2 * norm * m)
					ent:TakeDamage(1,game.GetWorld(),game.GetWorld())
				end
			end
		end
	end
	if t > CurTime() and table.Count(move_tab) < 200 then return end
		t = CurTime() + math.random(1,2)

	for i = 1,20 do
		if scan_id > #scanList or #scanList <= 0 then
			scanList = GetEffected()
			scan_id = 1
			break
		elseif not move_tab[scanList[scan_id]] and IsValid(scanList[scan_id]) and IsValid(scanList[scan_id]:GetPhysicsObject()) and not scanList[scan_id]:CreatedByMap() then
			local ent = scanList[scan_id]
			local tr = ET(ent:GetPos(),Vector(0,0,1) * 640000,MASK_SHOT,ent)
			if tr.HitSky then
				local pys = ent:GetPhysicsObject()
				local vol = pys:GetVolume()
				local mass = pys:GetMass()
				if not IsValid(pys) or type(vol) ~= "number" or type(mass) ~= "number" then break end -- Bad entity
				local pNeeded = vol / mass / 63
				if (not pys:IsMoveable() or constraint.FindConstraint( ent, "Weld" )) then
					if math.random(5) >= 3 or wind < 18 then
						ent:EmitSound("physics/wood/wood_strain" .. math.random(1,8) .. ".wav")
						pNeeded = wind + 1
					else
						ent:EmitSound("physics/wood/wood_box_break" .. math.random(1,2) .. ".wav")
						pNeeded = 15
						constraint.RemoveConstraints( ent, "Weld" )
						pys:EnableMotion(true)
					end
				end
				if wind >= pNeeded then
					local m = 1 + pNeeded - wind
					pys:ApplyForceCenter(norm * m)
					if table.Count(move_tab) < 200 then
						move_tab[ent] = true
					end
				end
			end
			scan_id = scan_id + 1
		else
			scan_id = scan_id + 1
		end
	end
end)