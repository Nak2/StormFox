
SWEP.PrintName		= "SF Tool"
SWEP.Author			= "Nak"
SWEP.Purpose		= "Allows for easy configs"
SWEP.Instructions	= ""
SWEP.ViewModel		= "models/weapons/c_toolgun.mdl"
SWEP.WorldModel		= "models/weapons/w_toolgun.mdl"
SWEP.UseHands		= true
SWEP.Spawnable		= true
SWEP.AdminOnly		= true

util.PrecacheModel( SWEP.ViewModel )
util.PrecacheModel( SWEP.WorldModel )

SWEP.ShootSound = Sound( "weapons/irifle/irifle_fire2.wav" ) -- or "weapons/irifle/irifle_fire2.wav"
-- Default
	SWEP.Primary.ClipSize = -1
	SWEP.Primary.DefaultClip = -1
	SWEP.Primary.Automatic = false
	SWEP.Primary.Ammo = "none"
	SWEP.Secondary.ClipSize = -1
	SWEP.Secondary.DefaultClip = -1
	SWEP.Secondary.Automatic = false
	SWEP.Secondary.Ammo = "none"

	SWEP.CanHolster = true
	SWEP.CanDeploy = true


function SWEP:SetupDataTables()
	self:NetworkVar( "Entity", 0, "TargetEntity" )
end
function SWEP:Precache()
	util.PrecacheSound( self.ShootSound )
end

-- The shoot effect
function SWEP:DoShootEffect( hitpos, hitnormal, entity, physbone, bFirstTimePredicted )
	self:EmitSound( self.ShootSound )
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK ) -- View model animation
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	if ( not bFirstTimePredicted ) then return end
	local traceEffect = EffectData()
	traceEffect:SetOrigin( hitpos )
	traceEffect:SetStart( self.Owner:GetShootPos() )
	traceEffect:SetAttachment( 1 )
	traceEffect:SetEntity( self )
	traceEffect:SetScale(0.2)
	for i = 1,10 do
		util.Effect( "StunstickImpact", traceEffect )
	end
	util.Effect( "ToolTracer", traceEffect )
	local effectdata = EffectData()
	effectdata:SetOrigin( hitpos )
	effectdata:SetNormal( hitnormal )
	effectdata:SetEntity( entity )
	effectdata:SetAttachment( physbone )
	util.Effect( "selection_indicator", effectdata )

end

-- Trace a line then send the result to a mode function
function SWEP:PrimaryAttack()
	if SERVER and ( game.SinglePlayer() ) then self:CallOnClient( "PrimaryAttack" ) end
	if ( not self:CanPrimaryAttack() ) then return end
	local tr = util.GetPlayerTrace( self.Owner )
	tr.mask = bit.bor( CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_MONSTER, CONTENTS_WINDOW, CONTENTS_DEBRIS, CONTENTS_GRATE, CONTENTS_AUX )
	local trace = util.TraceLine( tr )
	if ( not trace.Hit ) then return end

	self:DoShootEffect( trace.HitPos, trace.HitNormal, trace.Entity, trace.PhysicsBone, IsFirstTimePredicted() )
end

function SWEP:SecondaryAttack()
	if SERVER and ( game.SinglePlayer() ) then self:CallOnClient( "SecondaryAttack" ) end
	if ( not self:CanSecondaryAttack() ) then return end
	local tr = util.GetPlayerTrace( self.Owner )
	tr.mask = bit.bor( CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_MONSTER, CONTENTS_WINDOW, CONTENTS_DEBRIS, CONTENTS_GRATE, CONTENTS_AUX )
	local trace = util.TraceLine( tr )
	if ( not trace.Hit ) then return end

	self:DoShootEffect( trace.HitPos, trace.HitNormal, trace.Entity, trace.PhysicsBone, IsFirstTimePredicted() )
end

function SWEP:OnRemove()
end

function SWEP:FireAnimationEvent( pos, ang, event, options )
	if ( event == 21 ) then return true end
	if ( event == 5003 ) then return true end
end