local glob = table.Copy( _G )
local _R = glob.table.Copy( debug.getregistry() )
_R.hook = hook
_R.util = util
_R.cvars = cvars
_R.os = os

_R.atac = {}

_R.atac.net = {
	Receive = net.Receive, 
	Start = net.Start,
	Send = net.Send,
	SendToServer = net.SendToServer,
	Broadcast = net.Broadcast,
	WString = net.WriteString,
	WInt = net.WriteInt,
	WFloat = net.WriteFloat,
	RString = net.ReadString,
	RInt = net.ReadInt,
	RFloat = net.ReadFloat,
}

-- sh setts

_R.atac.atacsettings = {}

_R.atac.atacsettings.MonitorRunString = true

_R.atac.atacsettings.MonitorRunStringAlt = true

-- end sh setts

table.Empty( debugoverlay )

local function tellfunc_generic( func_name )
	
	if CLIENT then
		
		local name = LocalPlayer()
		
		_R.atac.net.Start( "atac_NET_FUNCTION_CALLBACK" )
		
			_R.atac.net.WString( func_name )
			
		_R.atac.net.SendToServer()
		
	end

end

_R.atac.dupval = debug.getupvalue

debug.getupvalue = function() if CLIENT then tellfunc_generic( "debug.getupvalue" ) end return _R.atac.dupval end

-- TODO: Filter/check runstring input as specified LDU

if _R.atac.atacsettings.MonitorRunString then

	local LRunString = RunString
	
	function RunString( str ) 
		LRunString( str ) 
		if CLIENT then 
			tellfunc_generic( "RunString - \"" .. str .. "\"" ) 
		end
	 end

end

if _R.atac.atacsettings.MonitorRunStringAlt then

	local LRunStringEx = RunStringEx
	local LCompileString = CompileString
	
	function RunStringEx( str, id ) 
		LRunStringEx( str, id ) 
		if CLIENT then 
			tellfunc_generic( "RunStringEx - \"" .. str .. "\"" )
		end
	end
	
	function CompileString( str, id, herror ) 
		LCompileString( str, id, herror ) 
		if CLIENT then 
			tellfunc_generic( "CompileString - \"" .. str .. "\"" ) 
		end 
	end

end

GetConVarCallbacks = function( name, create ) return {} end
