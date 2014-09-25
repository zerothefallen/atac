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

_R.atac.settings = {}

-- Monitor and log when a clientside script (could be an addon) calls debug.getupvalue()?
_R.atac.settings.MonitorDebugGetUpValue = true

-- Monitor and log when a clientside script (could be an addon) calls RunString?
_R.atac.settings.MonitorRunString = true

-- Monitor and log when a clientside script (could be an addon) calls RunStringEx or CompileString?
_R.atac.settings.MonitorRunStringAlt = true

-- Override GetConVarCallbacks() to return an empty table?
_R.atac.settings.DumpGetConVarCallbacks = true

-- Empty the debugoverlay table?
_R.atac.settings.DumpDebugOverlay = true

-- end sh setts

if _R.atac.settings.DumpDebugOverlay then

	table.Empty( debugoverlay )
	
end

local function tellfunc_generic( func_name )
	
	if CLIENT then
		
		local name = LocalPlayer()
		
		_R.atac.net.Start( "ATAC_NET_FUNCTION_CALLBACK" )
		
			_R.atac.net.WString( func_name )
			
		_R.atac.net.SendToServer()
		
	end

end

if _R.atac.settings.MonitorDebugGetUpValue then

	_R.atac.dupval = debug.getupvalue
	
end

debug.getupvalue = function() if CLIENT then tellfunc_generic( "debug.getupvalue" ) end return _R.atac.dupval end

-- TODO: Filter/check runstring input as specified LDU

if _R.atac.settings.MonitorRunString then

	local LRunString = RunString
	
	function RunString( str ) 
		LRunString( str ) 
		if CLIENT then 
			tellfunc_generic( "RunString - \"" .. str .. "\"" ) 
		end
	 end

end

if _R.atac.settings.MonitorRunStringAlt then

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

if _R.atac.settings.DumpGetConVarCallbacks then

	function GetConVarCallbacks( name, create ) return {} end
	
end