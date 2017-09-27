--[[-------------------------------------------------------------------------
Source is reaaaalllly bad with realtime shadows .. so we gotta update them our selfs :\
---------------------------------------------------------------------------]]
local last = 0
hook.Add("Think","StormFox - ShadowUpdate",function()
	if CurTime() < last then return end
	last = CurTime() + 10
	for _,ent in ipairs(ents.GetAll()) do
		ent:MarkShadowAsDirty()
	end
end)

local darkalpha = 0
local min,max = math.min,math.max

local darkalpha = 0
local clamp = math.Clamp
hook.Add( "RenderScreenspaceEffects", "stormFox - screenmodifier", function()
	local outside = StormFox.Env.IsOutside() or StormFox.Env.NearOutside()

	if outside and darkalpha < 1.5 then
		darkalpha = min(darkalpha + 0.01, 1)
	elseif not outside and darkalpha > 0 then
		darkalpha = max(darkalpha - 0.01, 0)
	end
	local amount = StormFox.GetData("MapLight",100)
	local ml = clamp((100 - amount) / 100,0,1)

	if ml <= 0 or darkalpha <= 0 then return end
	local tab = {}
	tab[ "$pp_colour_addr" ] = 0
	tab[ "$pp_colour_addg" ] = 0
	tab[ "$pp_colour_addb" ] = 0
	tab[ "$pp_colour_brightness" ] = 0
	if not StormFox.GetData("has_light_environment",false) then
		local con = GetConVar("sf_redownloadlightmaps")
		if con and con:GetBool() then
			tab[ "$pp_colour_brightness" ] = -darkalpha * 0.05 * ml
		else
			tab[ "$pp_colour_brightness" ] = -darkalpha * 0.10 * ml
		end
	else
		tab[ "$pp_colour_brightness" ] = -darkalpha * 0.05 * ml
	end
	tab[ "$pp_colour_contrast" ] = 1
	tab[ "$pp_colour_colour" ] = 1 - darkalpha * 0.4 * ml
	tab[ "$pp_colour_mulr" ] = 0
	tab[ "$pp_colour_mulg" ] = 0
	tab[ "$pp_colour_mulb" ] = 0

	DrawColorModify( tab )

end )
