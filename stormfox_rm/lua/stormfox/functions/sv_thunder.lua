
local nextHit = 0
hook.Add("Think","StormFox - Thunder",function()
	if nextHit > SysTime() then return end
			nextHit = SysTime() + math.random(10,20)
	if not StormFox.GetData("Thunder",false) then return end
	if math.random(10) < 4 then
		StormFox.CLEmitSound("ambient/atmosphere/thunder" .. math.random(3,4) .. ".wav",nil,0.5)
	else
		StormFox.SetData("ThunderLight",math.random(150,100))
		StormFox.SetData("ThunderLight",0,StormFox.GetTime() + (math.random(1) / 10))
		StormFox.CLEmitSound("ambient/atmosphere/thunder" .. math.random(1,2) .. ".wav",nil,0.5)
	end
end)
