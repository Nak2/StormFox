
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

SWEP.Weight				= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

util.AddNetworkString("StormFox_Tool")
net.Receive("StormFox_Tool",function(len,ply)
	local msg = net.ReadInt(3)
	if msg == 0 then -- Add Material
		local str = net.ReadString()
		local bt1 = net.ReadBool()
		local bt2 = net.ReadBool()
		local mat_type = net.ReadInt(5)
		StormFox.Permission.SettingsEdit(ply,function()
			StormFox.TexHandler.AddMapMaterial(str,bt1 and mat_type or nil,bt2 and mat_type or nil)
		end)
	elseif msg == 1 then
		local str = net.ReadString()
		StormFox.Permission.SettingsEdit(ply,function()
			StormFox.TexHandler.RemoveMapMaterial(str)
		end)
	end
end)

function SWEP:Initialize()
	self:SetHoldType( "revolver" )
end

-- Should this weapon be dropped when its owner dies?
	function SWEP:ShouldDropOnDie()
		return false
	end
-- Check if changed hands. Just in case.
	local function CheckOwner(ent,owner)
		if ent.OnlyOwner == nil then
			ent.OnlyOwner = owner
			return
		end
		if ent.OnlyOwner == owner then return end
		ent:EmitSound("physics/metal/metal_box_break1.wav")
		SafeRemoveEntity(ent)
	end
	function SWEP:OwnerChanged()
		CheckOwner(self,self:GetOwner())
	end
	function SWEP:Equip( owner )
		CheckOwner(self,owner)
	end

-- Add tools
	for _,fil in ipairs(file.Find("weapons/sf_tool/tools/*.lua","LUA")) do
		AddCSLuaFile("weapons/sf_tool/tools/" .. fil)
	end

	function SWEP:CanPrimaryAttack()
		return true
	end

	function SWEP:CanSecondaryAttack()
		return true
	end

-- Console Command to switch weapon/toolmode
function sf_tool_request( ply, command, arguments )
	CAMI.PlayerHasAccess(ply,"StormFox Settings",function(b)
		if not b then ply:PrintMessage(HUD_PRINTTALK,"You don't have access to server settings.") return end
		local wep = ply:GetWeapon( "sf_tool" )
		if not IsValid(wep) then
			ply:Give("sf_tool")
		end
		ply:SelectWeapon( "sf_tool" )
	end)
end
concommand.Add( "sf_tool", sf_tool_request, nil, nil, { FCVAR_SERVER_CAN_EXECUTE } )

-- Singleplayer fix:
if game.SinglePlayer() then
	function SWEP:Reload()
		self:CallOnClient( "Reload" )
	end
end