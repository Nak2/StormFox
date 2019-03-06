

--[[-------------------------------------------------------------------------
There are no way to control the wind angle of env_wind.
Issue: http://github.com/Facepunch/garrysmod-requests/issues/1259

Since there are no way to control the env_wind, we have to delete the entity
and use cl_tree_sway_dir.
---------------------------------------------------------------------------]]


local flags = {}
local flag_models = {}
	flag_models["models/props_fairgrounds/fairgrounds_flagpole01.mdl"] = 90
	flag_models["models/props_street/flagpole_american.mdl"] = 90
	flag_models["models/props_street/flagpole_american_tattered.mdl"] = 90
	flag_models["models/props_street/flagpole.mdl"] = 90
	flag_models["models/mapmodels/flags.mdl"] = 0
	flag_models["models/props/de_cbble/cobble_flagpole.mdl"] = 180
	flag_models["models/props/de_cbble/cobble_flagpole_2.mdl"] = 225
	flag_models["models/props/props_gameplay/capture_flag.mdl"] = 270
	flag_models["models/props_medieval/pendant_flag/pendant_flag.mdl"] = 0
	flag_models["models/props_moon/parts/moon_flag.mdl"] = 0

local abs,clamp = math.abs,math.Clamp
hook.Add("StormFox.PostEntityScan","StormFox.WindSetup",function()
	-- Delete env_wind until there is support
		if IsValid(StormFox.env_wind) then
			SafeRemoveEntity(StormFox.env_wind)
			StormFox.env_wind = nil
		end
	-- Check if there are any flags
		for _,ent in pairs(ents.GetAll()) do
			if not ent:CreatedByMap() then continue end
			-- Check the angle
				if abs(ent:GetAngles():Forward():Dot(Vector(0,0,1))) > 5 then continue end
			if not flag_models[ent:GetModel()] then continue end
				table.insert(flags,ent)
		end
	-- Setup flag AI
		if #flags > 0 then
			hook.Add("StormFox - NetDataChange","StormFox - FlagController",function(key,var)
				if key == "WindAngle" then
					for _,ent in pairs(flags) do
						if not IsValid(ent) then continue end
						local y = flag_models[ent:GetModel()] or 0
						ent:SetAngles(Angle(0,var + y,0))
					end
				elseif key == "Wind" then
					for _,ent in pairs(flags) do
						if not IsValid(ent) then continue end
						ent:SetPlaybackRate(clamp(var / 7,0.5,10))
					end
				end
			end)
		end
end)

--[[ Unused code. As env_wind doesn't work.
hook.Add("StormFox - NetDataChange","StormFox - WindController",function(key,var)
	if true then return end
	if key == "Wind" then
		if not IsValid( StormFox.env_wind ) then return end -- No wind controller
		local var = 1
		local m = 1

		StormFox.env_wind:SetKeyValue("minwind",var * 11.7 * m) -- 25 45% 	
		StormFox.env_wind:SetKeyValue("maxwind",var * 26 * m) -- 45

		StormFox.env_wind:SetKeyValue("mingust",var * 32 * m) -- 60
		StormFox.env_wind:SetKeyValue("maxgust",var * 40 * m) -- 80
		game.SetGlobalState("m_iInitialWindDir")
	elseif key == "WindAngle" then
		if not IsValid( StormFox.env_wind ) then return end -- No wind controller
		StormFox.env_wind:SetAngles(Angle(0,var,0)) -- This part doesn't work
	end
end)]]