local buffertimer = 10
local buffer = {}

-- Set vars and reset buffer
local message_list = {}
timer.Create("net-reset",buffertimer,0,function()
	message_list = table.Copy(buffer)
	table.Empty(buffer)
end)

-- Override incoming messages and count them
oldNetIncoming = oldNetIncoming or net.Incoming
function net.Incoming(len, client)
	buffer[client] = (buffer[client] or 0) + 1
	oldNetIncoming(len,client)
end

-- Make a command
concommand.Add( "netcheck", function( ply, cmd, args )
	if not ply:IsAdmin() then return end -- Only admins
	ply:PrintMessage(HUD_PRINTCONSOLE,"Messages pr second")
	for client,time in pairs(message_list) do
		ply:PrintMessage(HUD_PRINTCONSOLE,"[" .. client:Name() .. "] " .. (time / buffertimer) .. "mps")
	end
end )