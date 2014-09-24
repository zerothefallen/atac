if SERVER then

-- require( "slog2" )

local loadtime = os.time()
local glob = table.Copy( _G )
local _R = glob.table.Copy( debug.getregistry() )
_R.hook = hook
_R.util = util
_R.cvars = cvars
_R.file = file
_R.player = player
_R.os = os

_R.atac = { }

local lastlog = ""

_R.atac.log = function( str )

	if lastlog == str then return end

	file.Write( "atac_log_" .. loadtime .. ".txt", ( file.Read( "atac_log_" .. loadtime .. ".txt" ) or "" ) .. "\n" .. str )
	
	lastlog = str

end

local lastprint = ""

_R.atac.ta = function( str )

	if lastprint == str then return end

	for _,pl in glob.pairs( _R.player.GetAll() ) do
	
		if pl:IsAdmin() then
		
			pl:ChatPrint( "aTac: " .. str )
		
		end
	
	end
	
	lastprint = str

end

_R.atac.key = math.random( 1000000, 9999999 )

-- Settings start 
_R.atac.settings = { 
	KickOnGenericBadFunction = false,
	KickOnGenericCVarChange = false,
	KickOnUnWhitelistedBind = false,
	UlxSourceBans = false,
	ServerContact = "the server owner.\n\nRequest whitelisting by emailing:\n\natac_whitelist@yahoo.com\n(email checked every day)",
}
-- Settings end

_R.util.AddNetworkString( "atac_NET_KEYCHECK" )
_R.util.AddNetworkString( "atac_NET_SETKEY" )
_R.util.AddNetworkString( "atac_NET_CONVAR_CALLBACK" )
_R.util.AddNetworkString( "atac_NET_FUNCTION_CALLBACK" )
_R.util.AddNetworkString( "atac_NET_BANMEPLEASE" )
_R.util.AddNetworkString( "atac_NET_CHECKBANFILE" )
_R.util.AddNetworkString( "atac_NET_NOTWHITELISTED" )

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
	-- sec
	--[[
	if ulx then RunConsoleCommand( "ulx", "ban", ply:Name(), 0, "Banned from the server by atac." ) end
	if ulx and UlxSourceBans then RunConsoleCommand( "ulx", "sban", ply:Name(), 0, "Cheater" ) return end
	if evolve then RunConsoleCommand( "ev", "ban", ply:Name(), 0, "Banned from the server by atac." ) return end
	if not ( ulx or evolve ) then
		_R.Player.Ban( ply, 0 )
		_R.Player.Kick( ply, "Banned from the server by atac." )
	end
	]]--
	
end

-- Handle player info, give out key
_R.hook.Add( "PlayerInitialSpawn", "atac_HOOK_PlayerInitialSpawn_" .. glob.tostring( _R.atac.key ), function( ply )
	
	if glob.IsValid( ply ) then 
		
		_R.atac.net.Start( "atac_NET_SETKEY" ) 

			local k = _R.atac.key
			_R.atac.net.WFloat( k )
			
		_R.atac.net.Send( ply )
		
		local pl = ply
		
		timer.Simple( 1, function() 
			_R.atac.net.Start( "atac_NET_CHECKBANFILE" )
			_R.atac.net.Send( pl )
		end )
	
	end

end )

-- Bad function calls
_R.atac.net.Receive( "atac_NET_FUNCTION_CALLBACK", function( len, ply ) 
	
	if not glob.IsValid( ply ) then return end
	
	local _sid = _R.Player.SteamID( ply )
	local fname = _R.atac.net.RString()
	
	_R.atac.log( ply:Nick() .. " (" .. _sid .. ") attempted to call a monitored function: " .. fname )
	_R.atac.ta( ply:Nick() .. " (" .. _sid .. ") attempted to call a monitored function: " .. fname )
	if _R.atac.settings.KickOnGenericBadFunction then
		_R.Player.Kick( ply, "Called a monitored function: " .. fname )
	end

end )

-- Not whitelisted
_R.atac.net.Receive( "atac_NET_NOTWHITELISTED", function( len, ply ) 
	
	if not glob.IsValid( ply ) then return end
	
	local _sid = _R.Player.SteamID( ply )
	local bname = _R.atac.net.RString()
	
	_R.atac.log( "Player " .. ply:Name() .. " (" .. _sid .. ") ran an unknown bind: \"" .. bname .. "\"" )
	_R.atac.ta( "Player " .. ply:Name() .. " (" .. _sid .. ") ran an unknown bind: \"" .. bname .. "\"" )
	
	if _R.atac.settings.KickOnUnWhitelistedBind then
	
		_R.Player.Kick( ply, "The bind \"" .. bname .. "\" isn't whitelisted on this server! (aTac)\n\nIf you need help, contact " .. _R.atac.settings.ServerContact )
	
	end

end )

-- Check cvar changes
_R.atac.net.Receive( "atac_NET_CONVAR_CALLBACK", function( len, ply ) 
	
	if not glob.IsValid( ply ) then return end
	
	local _sid = _R.Player.SteamID( ply )

	local cname = _R.atac.net.RString()
	local vold = _R.atac.net.RString()
	local vnew = _R.atac.net.RString()
	
	local _actvar = glob.GetConVarString( cname )
	if _actvar ~= vnew then
	
		_R.atac.log( ply:Nick() .. " (" .. _sid .. ") attempted to change a cvar: " .. cname )
		_R.atac.ta( ply:Nick() .. " (" .. _sid .. ") attempted to change a cvar: " .. cname )
		
		if _R.atac.settings.KickOnGenericCVarChange then
		
			_R.Player.Kick( ply, "Received a callback from a changed cvar that wasn't supposed to be changed." )
			
		end
		
	end

end )

_R.atac.net.Receive( "atac_NET_BANMEPLEASE", function( len, ply )

-- sec

--[[
	if not glob.IsValid( ply ) then return end
	glob.MsgAll( ply:Nick() .. " (" .. ply:SteamID() .. ") is a cheater and is being removed" )
	_R.Player.Kick( ply, "Detected cheater.\nIf you think this is a mistake, contact " .. _R.atac.settings.ServerContact )
	]]--

end )

end
