if SERVER then

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
	
	-- Settings start 
	_R.atac.settings = { }
	
	-- Kick on the change of a monitored cvar?
	_R.atac.settings.KickOnGenericCVarChange = false
	
	-- Tell kick players to contact who for help?
	_R.atac.settings.ServerContact = "the server owner"
	
	-- Settings end

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
			
				pl:ChatPrint( "atac: " .. str )
			
			end
		
		end
		
		lastprint = str

	end

	_R.util.AddNetworkString( "ATAC_NET_CONVAR_CALLBACK" )
	_R.util.AddNetworkString( "ATAC_NET_FUNCTION_CALLBACK" )
	_R.util.AddNetworkString( "ATAC_NET_BANMEPLEASE" )
	_R.util.AddNetworkString( "ATAC_NET_CHECKBANFILE" )
	_R.util.AddNetworkString( "ATAC_NET_NOTWHITELISTED" )

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

	-- Bad function calls
	_R.atac.net.Receive( "ATAC_NET_FUNCTION_CALLBACK", function( len, ply ) 
		
		if not glob.IsValid( ply ) then return end
		
		local _sid = _R.Player.SteamID( ply )
		local fname = _R.atac.net.RString()
		
		_R.atac.log( ply:Nick() .. " (" .. _sid .. ") called this function: " .. fname )
		_R.atac.ta( ply:Nick() .. " (" .. _sid .. ") called this function: " .. fname )

	end )

	-- Not whitelisted
	_R.atac.net.Receive( "ATAC_NET_NOTWHITELISTED", function( len, ply ) 
		
		if not glob.IsValid( ply ) then return end
		
		local _sid = _R.Player.SteamID( ply )
		local bname = _R.atac.net.RString()
		
		_R.atac.log( ply:Name() .. " (" .. _sid .. ") ran this bind: \"" .. bname .. "\"" )
		_R.atac.ta( ply:Name() .. " (" .. _sid .. ") ran this bind: \"" .. bname .. "\"" )

	end )

	-- Check cvar changes
	_R.atac.net.Receive( "ATAC_NET_CONVAR_CALLBACK", function( len, ply ) 
		
		if not glob.IsValid( ply ) then return end
		
		local _sid = _R.Player.SteamID( ply )

		local cname = _R.atac.net.RString()
		local vold = _R.atac.net.RString()
		local vnew = _R.atac.net.RString()
		
		local _actvar = glob.GetConVarString( cname )
		if _actvar ~= vnew then
		
			_R.atac.log( ply:Nick() .. " (" .. _sid .. ") changed this cvar: " .. cname )
			_R.atac.ta( ply:Nick() .. " (" .. _sid .. ") changed this cvar: " .. cname )
			
			if _R.atac.settings.KickOnGenericCVarChange then
			
				_R.Player.Kick( ply, "Received a callback from a changed cvar that wasn't supposed to be changed." )
				
			end
			
		end

	end )

end