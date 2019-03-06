ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Campfire"
ENT.Author = "Nak"
ENT.Purpose		= "A Campfire"
ENT.Instructions = "Place it somewhere"
ENT.Category		= "StormFox"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true

function ENT:CanProperty(ply,str)
	if str == "drive" then return false end
	if str == "editentity" then return false end
	return true
end

function ENT:IsOn()
	if SERVER then
		return self.on
	else
		return self:GetNWInt("on",0) > 0
	end
end

-- Campfire Properties
	properties.Add( "sf_campfire_ignite", {
		MenuLabel = "#ignite",
		Order = 999,
		MenuIcon = "icon16/fire.png",
		Filter = function( self, ent, ply )
			if not IsValid( ent )  then return false end
			if ent:IsPlayer()  then return false end
			if ent:GetClass() ~= "stormfox_campfire"  then return false end
			if not gamemode.Call( "CanProperty", ply, "ignite", ent ) then return false end
			return not ent:IsOn()
		end,
		Action = function( self, ent )
			self:MsgStart()
				net.WriteEntity( ent )
			self:MsgEnd()
		end,
		Receive = function( self, length, player )
			local ent = net.ReadEntity()
			if ( not self:Filter( ent, player ) ) then return end
			ent:SetOn(true)
		end
	} )
	properties.Add( "sf_campfire_extinguish", {
		MenuLabel = "#extinguish",
		Order = 999,
		MenuIcon = "icon16/water.png",
		Filter = function( self, ent, ply )
			if not IsValid( ent )  then return false end
			if ent:IsPlayer()  then return false end
			if ent:GetClass() ~= "stormfox_campfire"  then return false end
			if not gamemode.Call( "CanProperty", ply, "extinguish", ent ) then return false end
			return ent:IsOn()
		end,
		Action = function( self, ent )
			self:MsgStart()
				net.WriteEntity( ent )
			self:MsgEnd()
		end,
		Receive = function( self, length, player )
			local ent = net.ReadEntity()
			if ( not self:Filter( ent, player ) ) then return end
			ent:SetOn(false)
		end
	} )