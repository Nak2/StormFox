--[[-------------------------------------------------------------------------
Source is reaaaalllly bad with realtime shadows .. so we gotta update them our selfs :\
---------------------------------------------------------------------------]]
local last = 0
hook.Add("Think","StormFox - ShadowUpdate",function()
	if SysTime() < last then return end
	last = SysTime() + 10
	for _,ent in ipairs(ents.GetAll()) do
		ent:MarkShadowAsDirty()
	end
end)

local darkalpha = 0
local min,max = math.min,math.max
local darkalpha = 0
local clamp = math.Clamp
local con = GetConVar("sf_renderscreenspace_effects")
hook.Add( "RenderScreenspaceEffects", "stormFox - screenmodifier", function()
	if not con or not con:GetBool() then return end
	local outside = StormFox.Env.IsOutside() or StormFox.Env.NearOutside()

	if outside and darkalpha < 1 then
		darkalpha = min(darkalpha + 0.01, 1)
	elseif not outside and darkalpha > 0 then
		darkalpha = max(darkalpha - 0.01, 0)
	end
	local amount = 2 * (clamp(1 - StormFox.GetData("MapLight",100) / 100,0.3,0.8) - 0.3)
	if amount == math.huge then
		amount = 1
	end
	local ml = amount * darkalpha

	if ml <= 0 or darkalpha <= 0 then return end
	local tab = {}

	tab[ "$pp_colour_addr" ] = 0
	tab[ "$pp_colour_addg" ] = 0
	tab[ "$pp_colour_addb" ] = 0
	tab[ "$pp_colour_brightness" ] = -0.02 * ml

	tab[ "$pp_colour_contrast" ] = 1
	tab[ "$pp_colour_colour" ] = 1 - ml * 0.4
	tab[ "$pp_colour_mulr" ] = 0
	tab[ "$pp_colour_mulg" ] = 0
	tab[ "$pp_colour_mulb" ] = 0

	DrawColorModify( tab )
end )