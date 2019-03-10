--[[-------------------------------------------------------------------------
This is only made serverside .. for some reason.
---------------------------------------------------------------------------]]
if SERVER then
	AddCSLuaFile()
end
ENT.Base = "base_entity"
ENT.Type = "brush"

function ENT:Initialize()
	self:SetTrigger( true )
	self.soundscape = nil
	self.enabled = true
end

function ENT:StartTouch( ent )
	if not IsValid(ent) then return end
	if not ent:IsPlayer() then return end
	if not self.soundscape then return end
	if not self.enabled then return end
	StormFox.SoundScape.TriggerSoundScape(self.soundscape,ent)
end

function ENT:Activate() end

function ENT:EndTouch( ent ) end

hook.Add("StormFox.MAP.Loaded","StormFox.trigger_soundscape",function()
	local tab = {}
	for i,ent in ipairs(ents.FindByClass("trigger_soundscape")) do
		tab[ent:GetKeyValues().hammerid or -1] = ent
	end
	print("A")
	for i,v in ipairs(StormFox.MAP.FindClass("trigger_soundscape")) do
		if tab[v.hammerid] then
			local ent = tab[v.hammerid]
			print(ent)
			PrintTable(v)
			if not v.soundscape then continue end -- No soundscape
			ent.soundscape = v.soundscape -- The targetname
			if v.startdisabled then
				ent.enabled = false
			end
		end
	end
end)