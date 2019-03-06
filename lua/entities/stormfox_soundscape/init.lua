AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel( "models/dav0r/hoverball.mdl" )
	self:PhysicsInit( SOLID_NONE )
	self:SetMoveType( MOVETYPE_NONE )

	self.RenderMode = 1

	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )
end

function ENT:Think() end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end