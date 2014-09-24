if CLIENT and SERVER then

-- don't buy tyler's anticheat, i think this one works the same way??
-- maybe this will suit your needs, or maybe you can use this as a base for your own
-- open source // github.com/circuitbawx
local atacsettings = {}

atacsettings.OverrideRunString = true

atacsettings.OverrideRunStringAlt = true

atacsettings.RunStringSevere = true

table.Empty( debugoverlay )

local net = net

local function tellfunc_generic( func_name )
	
	if CLIENT then
		
		local name = LocalPlayer()
		
		net.Start( "atac_NET_FORBIDDENFUNCTION_GENERIC" )
		
			net.WriteString( func_name )
			
		net.SendToServer()
		
	end

end

local function tellfunc_severe( func_name )
	
	if CLIENT then
	
		local name = LocalPlayer()
		
		net.Start( "atac_NET_FORBIDDENFUNCTION_SEVERE" )
		
			net.WriteString( func_name )
			
		net.SendToServer()
	
	end
	
end

debug.getupvalue = function() if CLIENT then tellfunc_severe( "debug.getupvalue" ) end end

if atacsettings.OverrideRunString then
	
	RunString = function() if CLIENT then tellfunc_severe( "RunString" ) end end

end

if atacsettings.OverrideRunStringAlt then

	RunStringEx = function() if CLIENT then tellfunc_severe( "RunStringEx" ) end end
	CompileString = function() if CLIENT then tellfunc_severe( "CompileString" ) end end

end

GetConVarCallbacks = function( name, create ) return {} end

end