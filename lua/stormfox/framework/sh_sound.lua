
StormFox_SOUND = StormFox_SOUND or {}
if SERVER then
	util.AddNetworkString("StormFox - Sound")
	function StormFox.CLEmitSound(snd,ply,vol)
		net.Start("StormFox - Sound")
			net.WriteString(snd)
			net.WriteFloat(vol or 1)
		if ply then
			net.Send(ply)
		else
			net.Broadcast()
		end
	end
else
	net.Receive("StormFox - Sound",function(len)
		if not LocalPlayer() then return end
		local snd = net.ReadString()
		local vol = net.ReadFloat() or 1
		if not snd then return end
		LocalPlayer():EmitSound(snd,75,100,vol)
	end)
end