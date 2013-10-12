local HUDInfoNote_c = 0
local HUDInfoNotes = {}

local HUDAdminNote_c = 0
local HUDAdminNotes = {}

local HUDNote_c = 0
local HUDNotes = {}

local PatchPPOwner

local Owner



------------
--  FONT  --
------------

surface.CreateFont( "PatchProtectFont", {
	font 		= "DermaDefault",
	size 		= 15,
	weight 		= 750,
	blursize 	= 0,
	scanlines 	= 0,
	antialias 	= true,
	shadow 		= false
} )

surface.CreateFont( "PatchProtectFont_small", {
	font 		= "DefaultSmall",
	size 		= 13,
	weight 		= 750,
	blursize 	= 0,
	scanlines 	= 0,
	antialias 	= true,
	shadow 		= false
} )



------------------
--  PROP OWNER  --
------------------

function cl_PProtect.ShowOwner()
	
	-- Check, PatchPP
	if GetConVarNumber( "PProtect_PP_use" ) == 0 then return end

	-- No Valid Player or Valid Entity
	if !LocalPlayer() or !LocalPlayer():IsValid() then return end

	-- Set Trace
	local PlyTrace = LocalPlayer():GetEyeTrace()
	

	if PlyTrace.HitNonWorld then

		if PlyTrace.Entity:IsValid() and !PlyTrace.Entity:IsPlayer() and !LocalPlayer():InVehicle() then

			if Owner == nil then
				net.Start("getOwner")
					net.WriteEntity( PlyTrace.Entity )
				net.SendToServer()
			end

			local ownerText

			if type(Owner) == "Player" then

				ownerText = "Owner: " .. Owner:GetName()

			else

				ownerText = "Owner: Disc. or World"

			end

			surface.SetFont("PatchProtectFont_small")

			local OW, OH = surface.GetTextSize(ownerText)
			OW = OW + 10
			OH = OH + 10
			if type(Owner) ~= "nil" then

				draw.RoundedBox(3, ScrW() - OW - 5, ScrH() / 2 - (OH / 2), OW, OH, Color(88, 144, 222, 200))
				draw.SimpleText(ownerText, "PatchProtectFont_small", ScrW() - 10, ScrH() / 2 , Color(0, 0, 0, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

			end

		else

			if Owner ~= nil then --Because of the server performance, it just sets it to nil once
				Owner = nil
			end

		end

	else
		
		if Owner ~= nil then --Because of the server performance, it just sets it to nil once
			Owner = nil
		end
		
	end

end
hook.Add("HUDPaint", "ShowingOwner", cl_PProtect.ShowOwner)

--Set PhysBeam to a kind of "disabled" Beam, if the player is not allowed to pick the prop up
function cl_PProtect.SetClientPhysBeam( ply, ent )

	return false

end
hook.Add("PhysgunPickup", "SetClientPhysBeam", cl_PProtect.SetClientPhysBeam)



---------------------
--  PROPERTY MENU  --
---------------------

-- SET OTHER OWNER OVER C-MENU
properties.Add( "setpropertyowner", {

	MenuLabel = "Set Owner...",

	Order = 2001,

	Filter = function( self, ent, ply )

		local Owner = entityOwners[ent:EntIndex()]
		if !ent:IsValid() or ent:IsPlayer() or ply != Owner then return false end
		return true

	end,

	MenuOpen = function( self, menu, ent, trace )

		local submenu = menu:AddSubMenu()
		for _, ply in ipairs( player.GetAll() ) do

			submenu:AddOption( ply:Nick(), function()

				local sendInformation = {}
				table.insert(sendInformation, ent)
				table.insert(sendInformation, ply)

				net.Start( "SetOwnerOverProperty" )
					net.WriteTable( sendInformation )
				net.SendToServer()

			end )

		end

	end,

} )

-- ADD TO BLOCKED PROPS
properties.Add("addblockedprop", {

	MenuLabel = "Add to blocked Props",
	Order = 2002,

	Filter = function(self, ent, ply)

		if !ent:IsValid() or ent:IsPlayer() then return false end
		if !ply:IsSuperAdmin() then return false end
		return true

	end,

	Action = function(self, ent)
		--Here goes funciton to block a prop
	end

} )



----------------
--  MESSAGES  --
----------------

-- INFO MESSAGE
function cl_PProtect.AddInfoNotify( str )

	local tab = {}
	tab.text = str
	tab.recv = SysTime()

	table.insert( HUDInfoNotes, tab )
	HUDInfoNote_c = HUDInfoNote_c + 1

	LocalPlayer():EmitSound("buttons/button9.wav", 100, 100)

end
usermessage.Hook( "PProtect_InfoNotify", function( u )
	cl_PProtect.AddInfoNotify( u:ReadString() )
end )

-- ADMIN MESSAGE
function cl_PProtect.AddAdminNotify( str )

	local tab = {}
	tab.text = str
	tab.recv = SysTime()

	if LocalPlayer():IsAdmin() then

		table.insert( HUDAdminNotes, tab )
		HUDAdminNote_c = HUDAdminNote_c + 1

	end

	LocalPlayer():EmitSound("npc/turret_floor/click1.wav", 10, 100)

end
usermessage.Hook( "PProtect_AdminNotify", function( u )
	cl_PProtect.AddAdminNotify( u:ReadString() )
end )

-- DEFAULT MESSAGE
function cl_PProtect.AddNotify( str )

	local tab = {}
	tab.text = str
	tab.recv = SysTime()

	table.insert( HUDNotes, tab )
	HUDNote_c = HUDNote_c + 1

	LocalPlayer():EmitSound("npc/turret_floor/click1.wav", 10, 100)

end
usermessage.Hook("PProtect_Notify", function( u )
	cl_PProtect.AddNotify(u:ReadString())
end )

-- CREATE INFO MESSAGE
local function DrawInfoNotice( self, k, v, i )

	local text = v.text
	surface.SetFont( "PatchProtectFont" )
	local tsW, tsH = surface.GetTextSize( text )
	
	local w = tsW + 20
	local h = tsH + 15
	local x = ScrW() - w - 15
	local y = ScrH() - h - 85
	local col = Color( 128, 255, 0, 200 )
	
	local xtext = ( x + w - 10 )
	local ytext = ( y + ( h / 2 ) )
	local coltext = Color( 0, 0, 0, 255 )
	
	draw.RoundedBox( 4, x, y, w, h, col )
	draw.SimpleText( text, "PatchProtectFont", xtext, ytext, coltext, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )

end

-- CREATE ADMIN MESSAGE
local function DrawAdminNotice( self, k, v, i )

	local text = v.text
	surface.SetFont("PatchProtectFont")
	local tsW, tsH = surface.GetTextSize(text)
	
	local w = tsW + 20
	local h = tsH + 15
	local x = ScrW() - w - 15
	local y = ScrH() - h - 50
	local col = Color( 176, 0, 0, 200 )
	
	local xtext = ( x + w - 10)
	local ytext = ( y + ( h / 2 ) )
	local coltext = Color( 0, 0, 0, 255 )
	
	draw.RoundedBox( 4, x, y, w, h, col )
	draw.SimpleText( text, "PatchProtectFont", xtext, ytext, coltext, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )

end

-- CREATE DEFAULT MESSAGE
local function DrawNotice( self, k, v, i )

	local text = v.text
	surface.SetFont("PatchProtectFont")
	local tsW, tsH = surface.GetTextSize(text)

	local w = tsW + 20
	local h = tsH + 15
	local x = ScrW() - w - 15
	local y = ScrH() - h - 15
	local col = Color( 88, 144, 222, 200 )
	
	local xtext = ( x + w - 10)
	local ytext = ( y + ( h / 2 ) )
	local coltext = Color( 0, 0, 0, 255 )
	
	draw.RoundedBox( 4, x, y, w, h, col )
	draw.SimpleText( text, "PatchProtectFont", xtext, ytext, coltext, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )

end



----------------
--  PAINTING  --
----------------

local function Paint()

	-- SHOW NORMAL MESSAGES
	if not HUDNotes then return end

	local i = 0

	for k, v in pairs(HUDNotes) do

		if v ~= 0 then

			i = i + 1
			DrawNotice( self, k, v, i)

		end

	end

	-- DELETE NORMAL MESSAGES
	for k, v in pairs(HUDNotes) do

		local ShowNotify

		if v ~= 0 and v.recv + 6 < SysTime() then ShowNotify = true else ShowNotify = false end

		if ShowNotify then
			HUDNotes[ k ] = 0
			if HUDNote_c > 0 then HUDNote_c = HUDNote_c - 1 end
			if (HUDNote_c < 1) then HUDNotes = {} end
		end

		if HUDNote_c > 1 then
			HUDNotes[ 1 ] = 0
			table.remove(HUDNotes, 1)
			HUDNote_c = 1
		end

	end

	-- SHOW INFO MESSAGES
	if not HUDInfoNotes then return end

	local a_i = 0

	for k, v in pairs(HUDInfoNotes) do

		if v ~= 0 then
			a_i = a_i + 1
			DrawInfoNotice( self, k, v, i)
		end

	end

	-- DELETE INFO MESSAGES
	for k, v in pairs(HUDInfoNotes) do

		local ShowInfoNotify

		if v ~= 0 and v.recv + 6 < SysTime() then ShowInfoNotify = true else ShowInfoNotify = false end

		if ShowInfoNotify then
			HUDInfoNotes[ k ] = 0
			if HUDInfoNote_c > 0 then HUDInfoNote_c = HUDInfoNote_c - 1 end
			if (HUDInfoNote_c < 1) then HUDInfoNotes = {} end
		end

		if HUDInfoNote_c > 1 then
			HUDInfoNotes[ 1 ] = 0
			table.remove(HUDInfoNotes, 1)
			HUDInfoNote_c = 1
		end

	end

	-- SHOW ADMIN MESSAGES
	if not HUDAdminNotes then return end

	local a_i = 0

	for k, v in pairs(HUDAdminNotes) do

		if v ~= 0 then
			a_i = a_i + 1
			DrawAdminNotice( self, k, v, i)
		end

	end

	-- DELETE ADMIN MESSAGES
	for k, v in pairs(HUDAdminNotes) do

		local ShowAdminNotify

		if v ~= 0 and v.recv + 6 < SysTime() then ShowAdminNotify = true else ShowAdminNotify = false end

		if ShowAdminNotify then
			HUDAdminNotes[ k ] = 0
			if HUDAdminNote_c > 0 then HUDAdminNote_c = HUDAdminNote_c - 1 end
			if HUDAdminNote_c < 1 then HUDAdminNotes = {} end
		end

		if HUDAdminNote_c > 1 then
			HUDAdminNotes[ 1 ] = 0
			table.remove(HUDAdminNotes, 1)
			HUDAdminNote_c = 1
		end

	end

end
hook.Add("HUDPaint", "RoundedBoxHud", Paint)



------------------
--  NETWORKING  --
------------------

net.Receive( "sendOwner", function( len )
    
	Owner = net.ReadEntity()

end )