include("shared.lua")

function ENT:Initialize()
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetModelScale(math.random(2,4),0)
end

local m = Material("nature/water_coast04")
local mm = Material("decals/decalsplash")
local scale = Vector( 1, 1, 0.4 )
local mmm = Material("nature/water_coast04")

local mat = Matrix()
function ENT:Draw()

	render.SetShadowsDisabled( true ) 
	render.SuppressEngineLighting( true ) 

	-- Reset everything to known good
		render.SetStencilWriteMask( 0xFF )
		render.SetStencilTestMask( 0xFF )
		render.ClearStencil()
		render.SetStencilReferenceValue( 1 )
		render.SetStencilFailOperation( STENCILOPERATION_REPLACE )
	    render.SetStencilPassOperation( STENCILOPERATION_ZERO )
	    render.SetStencilZFailOperation( STENCILOPERATION_ZERO )
	
	-- Enable stencils
		render.SetStencilEnable( true )
		render.SetStencilCompareFunction( 1 )
	-- Render mask
		mat:Scale( scale )
		self:EnableMatrix( "RenderMultiply", mat )
		self:DrawModel()
	-- Setup cutter
		render.SetStencilFailOperation( STENCILOPERATION_ZERO )
	    render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
	    render.SetStencilZFailOperation( STENCILOPERATION_ZERO )
	    render.SetStencilCompareFunction( 3 )
	    render.SetStencilReferenceValue( 1 )
	-- Draw in mask
		render.SetMaterial(mmm)
		local s = self:OBBMaxs() - self:OBBMins()
		--render.DrawBox(self:GetPos(),self:GetAngles(),Vector(-10,-10,-10),Vector(10,10,10) ,Color(255,255,255))
		render.DrawQuadEasy( self:GetPos() + Vector(0,0,5), self:GetAngles():Up(),s.x * 2,s.y * 2, Color(255,255,255),self:GetAngles().y + 90 )
	-- Let everything render normally again
	render.SetStencilEnable( false )
	render.SuppressEngineLighting( false ) 
	render.SetShadowsDisabled( false ) 
end