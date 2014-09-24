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

_R.atac.atacsettings.OverrideRunString = true

_R.atac.atacsettings.OverrideRunStringAlt = true

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

debug.getupvalue = function() if CLIENT then tellfunc_generic( "debug.getupvalue" ) end end

if _R.atac.atacsettings.OverrideRunString then
	
	RunString = function() if CLIENT then tellfunc_generic( "RunString" ) end end

end

if _R.atac.atacsettings.OverrideRunStringAlt then
	
	RunStringEx = function() if CLIENT then tellfunc_generic( "RunStringEx" ) end end
	CompileString = function() if CLIENT then tellfunc_generic( "CompileString" ) end end

end

GetConVarCallbacks = function( name, create ) return {} end
