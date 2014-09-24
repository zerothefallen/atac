if SERVER then

local glob = table.Copy( _G )
local _R = glob.table.Copy( debug.getregistry() )
_R.hook = hook
_R.util = util
_R.cvars = cvars
_R.os = os

_R.atac = { }

-- Settings start
_R.atac.settings = { 
	BanOnGenericBadFunction = false,
	BanOnGenericCVarChange = false,
	BanOnBadModule = true,
	BanOnBadBind = true,
	BanOnBadConCommands = true,
	UlxSourceBans = false,
	ServerContact = "the server owner.\n\nRequest whitelisting by emailing:\n\natac_whitelist@yahoo.com\n(email checked every day)",
}
-- Settings end

_R.atac.key = math.random( 1000000, 9999999 )

_R.util.AddNetworkString( "atac_NET_KEYCHECK" )
_R.util.AddNetworkString( "atac_NET_SETKEY" )
_R.util.AddNetworkString( "atac_NET_CALLBACK_GENERIC" )
_R.util.AddNetworkString( "atac_NET_CALLBACK_SEVERE" )
_R.util.AddNetworkString( "atac_NET_FORBIDDENFUNCTION_GENERIC" )
_R.util.AddNetworkString( "atac_NET_FORBIDDENFUNCTION_SEVERE" )
_R.util.AddNetworkString( "atac_NET_BANMEPLEASE" )
_R.util.AddNetworkString( "atac_NET_CHECKBANFILE" )
_R.util.AddNetworkString( "atac_NET_UNKNOWNDLL" )
_R.util.AddNetworkString( "atac_NET_NOTWHITELISTED" )

_R.atac.players = { }

-- Implement cleaning banfiles

_R.atac.net = {
	Receive = net.Receive, 
	Start = net.Start,
	Send = net.Send,
	Broadcast = net.Broadcast,
	WString = net.WriteString,
	WInt = net.WriteInt,
	WFloat = net.WriteFloat,
	RString = net.ReadString,
	RInt = net.ReadInt,
	RFloat = net.ReadFloat,
}

_R.atac.net.Receive( "atac_NET_SETKEY", function( len ) 
	
	if _R.atac.key == loadtime * keyregfactor then
	
		_R.atac.key = _R.atac.net.RFloat()
		
		glob.print( "atac KEYSET " .. _R.atac.key )
	
	end
	
	local _nk = _R.atac.key
	
	_R.atac.net.Start( "atac_NET_KEYCHECK" )
	
		_R.atac.net.WFloat( _nk )
	
	_R.atac.net.SendToServer()

end )

_R.atac.net.Receive( "atac_NET_KEYCHECK", function( len, ply ) 

	local _k = _R.atac.net.RFloat()
	
	if not glob.IsValid( ply ) then return end
	
	if not _k then ply:Kick( "Invalid key provided, rejoin the game" ) end
	
	if _k ~= _R.atac.key then ply:Kick( "Keys don't match" ) end

end )

_R.atac.WriteBanFile = function( ply, reason )
	
	if ulx then RunConsoleCommand( "ulx", "ban", ply:Name(), 0, "You cannot connect to the selected server, because it is running in VAC (Valve Anti-Cheat) secure mode.\n\nThis Steam account has been banned from secure servers due to a cheating infraction." ) end
	if ulx and UlxSourceBans then RunConsoleCommand( "ulx", "sban", ply:Name(), 0, "Cheater" ) return end
	if evolve then RunConsoleCommand( "ev", "ban", ply:Name(), 0, "You cannot connect to the selected server, because it is running in VAC (Valve Anti-Cheat) secure mode.\n\nThis Steam account has been banned from secure servers due to a cheating infraction." ) return end
	if not ( ulx or evolve ) then
		_R.Player.Ban( ply, 0 )
		_R.Player.Kick( ply, "You cannot connect to the selected server, because it is running in VAC (Valve Anti-Cheat) secure mode.\n\nThis Steam account has been banned from secure servers due to a cheating infraction." )
	end
	
end

-- Handle player info, give out key
_R.hook.Add( "PlayerInitialSpawn", "atac_HOOK_PlayerInitialSpawn_" .. glob.tostring( _R.atac.key ), function( ply )
	
	if glob.IsValid( ply ) then 
		
		_R.atac.net.Start( "atac_NET_SETKEY" ) 

			local k = _R.atac.key
			_R.atac.net.WFloat( k )
			
		_R.atac.net.Send( ply )
		
		_R.atac.players[ _R.Player.SteamID( ply ) ] = {
			connected = _R.os.time(), 
			disconnected = nil, 
			name = _R.Player.Name( ply ), 
			active = true,
		}
		
		local pl = ply
		
		timer.Simple( 1, function() 
			_R.atac.net.Start( "atac_NET_CHECKBANFILE" )
			_R.atac.net.Send( pl )
		end )
	
	end

end )

_R.hook.Add( "PlayerDisconnect", "atac_HOOK_PlayerDisconnect_" .. glob.tostring( _R.atac.key ), function( ply )
	
	if glob.IsValid( ply ) then 
		
		_R.atac.players[ _R.Player.SteamID( ply ) ].disconnected = _R.os.time()
		_R.atac.players[ _R.Player.SteamID( ply ) ].active = false
	
	end

end )

-- Bad functions
_R.atac.net.Receive( "atac_NET_FORBIDDENFUNCTION_SEVERE", function( len, ply ) 
	
	if not glob.IsValid( ply ) then return end
	
	local _sid = _R.Player.SteamID( ply )
	local fname = _R.atac.net.RString()
		
	_R.atac.players[ _sid ].disconnected = _R.os.time()
	_R.atac.players[ _sid ].active = false
	glob.MsgAll( ply:Nick() .. " (" .. _sid .. ") is a cheater and is being removed" )
	_R.atac.WriteBanFile( ply, "You cannot connect to the selected server, because it is running in VAC (Valve Anti-Cheat) secure mode.\n\nThis Steam account has been banned from secure servers due to a cheating infraction." )

end )

_R.atac.net.Receive( "atac_NET_FORBIDDENFUNCTION_GENERIC", function( len, ply ) 
	
	if not glob.IsValid( ply ) then return end
	
	local _sid = _R.Player.SteamID( ply )
	local fname = _R.atac.net.RString()
		
	_R.atac.players[ _sid ].disconnected = _R.os.time()
	_R.atac.players[ _sid ].active = false
	glob.MsgAll( ply:Nick() .. " (" .. _sid .. ") is a cheater and is being removed" )
	if _R.atac.settings.BanOnGenericBadFunction then
		_R.atac.WriteBanFile( ply, "You cannot connect to the selected server, because it is running in VAC (Valve Anti-Cheat) secure mode.\n\nThis Steam account has been banned from secure servers due to a cheating infraction." )
	else
		_R.Player.Kick( ply, "You cannot connect to the selected server, because it is running in VAC (Valve Anti-Cheat) secure mode.\n\nThis Steam account has been banned from secure servers due to a cheating infraction." )
	end

end )

-- Bad modules
_R.atac.net.Receive( "atac_NET_BADMODULE", function( len, ply ) 
	
	if not glob.IsValid( ply ) then return end
	
	local _sid = _R.Player.SteamID( ply )
	local mname = _R.atac.net.RString()
		
	_R.atac.players[ _sid ].disconnected = _R.os.time()
	_R.atac.players[ _sid ].active = false
	glob.MsgAll( ply:Nick() .. " (" .. _sid .. ") is a cheater and is being removed" )
	if _R.atac.settings.BanOnBadModule then
		_R.atac.WriteBanFile( ply, "You cannot connect to the selected server, because it is running in VAC (Valve Anti-Cheat) secure mode.\n\nThis Steam account has been banned from secure servers due to a cheating infraction." )
	else
		_R.Player.Kick( ply, "You cannot connect to the selected server, because it is running in VAC (Valve Anti-Cheat) secure mode.\n\nThis Steam account has been banned from secure servers due to a cheating infraction." )
	end

end )

-- Not whitelisted
_R.atac.net.Receive( "atac_NET_NOTWHITELISTED", function( len, ply ) 
	
	if not glob.IsValid( ply ) then return end
	
	local _sid = _R.Player.SteamID( ply )
	local bname = _R.atac.net.RString()
	
	_R.Player.Kick( ply, "The bind \"" .. bname .. "\" isn't whitelisted on this server! (aTac)\n\nIf you need help, contact " .. _R.atac.settings.ServerContact )

end )

-- unknown dlls
_R.atac.net.Receive( "atac_NET_UNKNOWNDLL", function( len, ply ) 
	
	if not glob.IsValid( ply ) then return end
	
	local _sid = _R.Player.SteamID( ply )
	local thedll = _R.atac.net.RString()
		
	_R.atac.players[ _sid ].disconnected = _R.os.time()
	_R.atac.players[ _sid ].active = false
	glob.MsgAll( ply:Nick() .. " (" .. _sid .. ") has a sketchy/unknown DLL file in lua/bin." )
	_R.Player.Kick( ply, "Needs to remove a DLL from lua/bin: " .. thedll .. " (" .. _sid .. ")" )

end )

-- Check cvar changes
_R.atac.net.Receive( "atac_NET_CALLBACK_GENERIC", function( len, ply ) 
	
	if not glob.IsValid( ply ) then return end
	
	local _sid = _R.Player.SteamID( ply )

	local cname = _R.atac.net.RString()
	local vold = _R.atac.net.RString()
	local vnew = _R.atac.net.RString()
	
	local _actvar = glob.GetConVarString( cname )
	if _actvar ~= vnew then
	
		glob.MsgAll( ply:Nick() .. " (" .. _sid .. ") is a cheater and is being removed" )
		if _R.atac.settings.BanOnGenericCVarChange then
			_R.atac.WriteBanFile( ply, "You cannot connect to the selected server, because it is running in VAC (Valve Anti-Cheat) secure mode.\n\nThis Steam account has been banned from secure servers due to a cheating infraction." )
		else
			_R.Player.Kick( ply, "You cannot connect to the selected server, because it is running in VAC (Valve Anti-Cheat) secure mode.\n\nThis Steam account has been banned from secure servers due to a cheating infraction." )
		end
		
	end

end )

_R.atac.net.Receive( "atac_NET_CALLBACK_SEVERE", function( len, ply ) 
	
	if not glob.IsValid( ply ) then return end
	
	local _sid = _R.Player.SteamID( ply )

	local cname = _R.atac.net.RString()
	local vold = _R.atac.net.RString()
	local vnew = _R.atac.net.RString()
	
	local _actvar = glob.GetConVarString( cname )
	if _actvar ~= vnew then
		
		glob.MsgAll( ply:Nick() .. " (" .. _sid .. ") is a cheater and is being removed" )
		_R.atac.WriteBanFile( ply, "You cannot connect to the selected server, because it is running in VAC (Valve Anti-Cheat) secure mode.\n\nThis Steam account has been banned from secure servers due to a cheating infraction." )
		
	end

end )

_R.atac.net.Receive( "atac_NET_BANMEPLEASE", function( len, ply )

	if not glob.IsValid( ply ) then return end
	glob.MsgAll( ply:Nick() .. " (" .. ply:SteamID() .. ") is a cheater and is being removed" )
	_R.Player.Kick( ply, "Detected cheater.\nIf you think this is a mistake, contact " .. _R.atac.settings.ServerContact )

end )

end
