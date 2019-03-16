include("shared.lua")

function ENT:Initialize()
	self.PixVis = util.GetPixelVisibleHandle()
end

local matLight = Material( "sprites/light_ignorez" )
local matBeam = Material( "effects/lamp_beam" )
function ENT:Draw()
	self:DrawModel()
end

function ENT:OnRemove()
	if self.flashlight and IsValid(self.flashlight) then
		self.flashlight:Remove()
	end
end

function ENT:DrawTranslucent()

	if ( halo.RenderedEntity() == self ) then return end
	local dis = EyePos():DistToSqr(self:GetPos())
	if self:GetModel() == "models/props_c17/lamppost03a_off_dynamic.mdl" or dis > 2000000 then
		if self.flashlight and IsValid(self.flashlight) then
			self.flashlight:Remove()
		end
		return
	end
	local lpos = self:LocalToWorld(Vector(0, 94, 440))
	local con = GetConVar("sf_allow_dynamiclights")
	if con:GetBool() then
		if not self.flashlight or not IsValid(self.flashlight) then
			self.flashlight = ProjectedTexture()
			self.flashlight:SetPos(lpos)
			self.flashlight:SetAngles(self:LocalToWorldAngles(Angle( 90, 0, 0 )))

			self.flashlight:SetEnableShadows(true)

			self.flashlight:SetNearZ( 12 )
			self.flashlight:SetFOV( 80 )

			self.flashlight:SetBrightness(3)
			self.flashlight:SetFarZ( 1000 )
			self.flashlight:SetColor( Color(255,255,255) )

			self.flashlight:SetTexture("effects/flashlight001")
			self.flashlight:Update()
			self.oldpos = self:GetPos()
			self.oldang = self:GetAngles()
		elseif (self.oldpos or Vector(0,0,0)) ~= self:GetPos() or (self.oldang or Angle(0,0,0)) ~= self:GetAngles() then
			self.flashlight:SetPos(lpos)
			self.flashlight:SetAngles(self:LocalToWorldAngles(Angle( 90, 0, 0 )))
			self.flashlight:Update()
			self.oldpos = self:GetPos()
			self.oldang = self:GetAngles()
		end
	elseif self.flashlight and IsValid(self.flashlight) then
		self.flashlight:Remove()
	end
	--print("CREATE")

	render.SetMaterial(matBeam)

	-- Thx gmod_light
	local LightNrm = -self:GetAngles():Up()
	local ViewNormal = lpos - EyePos()
	local Distance = ViewNormal:Length()
	ViewNormal:Normalize()
	local ViewDot = ViewNormal:Dot( LightNrm * -1 ) - 0.4

	local Alpha = 100 - math.Clamp( ( 700 - Distance ) * ViewDot, 0, 100 )
	render.StartBeam( 3 )
		render.AddBeam( lpos + LightNrm * -1, 128 * 2, -0.01, Color( 255,255, 255, Alpha) )
		render.AddBeam( lpos - LightNrm * -300, 128 * 2, 0.5, Color( 255, 255, 255, Alpha / 2) )
		render.AddBeam( lpos - LightNrm * -400, 128 * 2, 1, Color( 255,255, 255, 0) )
	render.EndBeam()

	--render.DrawBeam(lpos,lpos - self:GetAngles():Up() * 500,180,0,1,Color(255,255,255,100 - Alpha * 0.9))
	if ( ViewDot >= 0 ) then

		render.SetMaterial( matLight )
		local Visibile = util.PixelVisible( lpos, 16, self.PixVis )

		if ( not Visibile ) then return end

		local Size = math.Clamp( Distance * Visibile * ViewDot * 2, 64, 512 / 2 )

		Distance = math.Clamp( Distance, 32, 800 )
		local Alpha = math.Clamp( ( 1000 - Distance ) * Visibile * ViewDot, 0, 100 )
		local Col = self:GetColor()
		Col.a = Alpha

		render.DrawSprite( lpos, Size, Size, Col, Visibile * ViewDot )
		render.DrawSprite( lpos, Size * 0.4, Size * 0.4, Color( 255, 255, 255, Alpha ), Visibile * ViewDot )

	end
end
