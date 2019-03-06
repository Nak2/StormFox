--[[-------------------------------------------------------------------------
This is only made serverside .. for some reason.
---------------------------------------------------------------------------]]
if SERVER then
	util.AddNetworkString("sv_trigger_soundscape")
end
ENT.Base = "base_entity"
ENT.Type = "brush"

AddCSLuaFile()

function ENT:Initialize()
	self:SetTrigger( true )
	self.soundscape = nil
end
if CLIENT then
	local cache = {}
	net.Receive("sv_trigger_soundscape",function()
		StormFox.SoundScape.Set(net.ReadString() or "")
	end)
	return
end

function ENT:StartTouch( ent )
	if not IsValid(ent) then return end
	if not ent:IsPlayer() then return end
	if not self.soundscape then return end
	net.Start("sv_trigger_soundscape")
		net.WriteString(self.soundscape)
	net.Send(ent)
end

function ENT:EndTouch( ent ) end

hook.Add("StormFox.MAP.Loaded","StormFox.trigger_soundscape",function()
	local tab = {}
	for i,ent in ipairs(ents.FindByClass("trigger_soundscape")) do
		tab[ent:GetKeyValues().hammerid or -1] = ent
	end
	for i,v in ipairs(StormFox.MAP.FindClass("trigger_soundscape")) do
		if tab[v.hammerid] then
			local ent = tab[v.hammerid]
			if not v.soundscape then continue end -- No soundscape
			ent.soundscape = v.soundscape -- The targetname
		end
	end
end)