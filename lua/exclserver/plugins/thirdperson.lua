-- A bunch of command aliases to open up the main menu. Nothing special here.
if SERVER then
	util.AddNetworkString("ESToggleTP");
end

local PLUGIN=ES.Plugin();
PLUGIN:SetInfo("Thirdperson","Allow you to toggle thirdperson.","Excl")
PLUGIN:AddCommand("thirdperson",function(p,a)
	if not p.excl or p:ESGetVIPTier() < 3  then return end
	net.Start("ESToggleTP"); net.Send(p);
end);
PLUGIN:AddCommand("firstperson",function(p,a)
	if not p.excl or p:ESGetVIPTier() < 3 then return end
	net.Start("ESToggleTP"); net.Send(p);
end);
PLUGIN:AddFlag(EXCL_PLUGIN_FLAG_NODEFAULTDISABLED)
PLUGIN();

if SERVER then return end

net.Receive("ESToggleTP",function()
	if not LocalPlayer().excl then return end
	LocalPlayer().excl.thirdperson = !LocalPlayer().excl.thirdperson;
	
	if LocalPlayer().excl.thirdperson then
		chat.AddText(Color(255,255,255),"You have enabled thirdperson mode.");
	end
	chat.PlaySound();
end)

local fov = 0;
local thirdperson = true;
local newpos
local tracedata = {}
local distance = 60;
local camPos = Vector(0, 0, 0)
local camAng = Angle(0, 0, 0)

local newpos;
local newangles;
hook.Add("CalcView", "exclThirdperson", function(ply, pos , angles ,fov)
	if !newpos then
		newpos = pos;
		newangles = angles;
	end

	if( ply.excl and ply.excl.thirdperson ) and distance > 2 then					
		local side = ply:GetActiveWeapon();
		side = side and IsValid(side) and side.GetHoldType and side:GetHoldType() != "normal" and side:GetHoldType() != "melee" and side:GetHoldType() != "melee2" and side:GetHoldType() != "knife";

		if side then
			tracedata.start = pos
			tracedata.endpos = pos - ( angles:Forward() * distance ) + ( angles:Right()* ((distance/90)*50) )
			tracedata.filter = player.GetAll()
			trace = util.TraceLine(tracedata)  
	        pos = newpos
			newpos = LerpVector( 0.5, pos, trace.HitPos + trace.HitNormal*2 )
			angles = newangles
			newangles = LerpAngle( 0.5, angles, (ply:GetEyeTraceNoCursor().HitPos-newpos):Angle() )

			camPos = pos
			camAng = angles;
			return GAMEMODE:CalcView(ply, newpos, angles, fov)
		else
			tracedata.start = pos
			tracedata.endpos = pos - ( angles:Forward() * distance * 2 ) + ( angles:Up()* ((distance/60)*10) )
			tracedata.filter = player.GetAll()
			
	    	trace = util.TraceLine(tracedata)
	        pos = newpos
			newpos = trace.HitPos + trace.HitNormal*2

			camPos = pos
			camAng = angles
			return GAMEMODE:CalcView(ply, newpos , angles ,fov)

		end
	else
		newpos = ply:EyePos();
	end
end)

hook.Add("ShouldDrawLocalPlayer", "ESThirdpersonDrawLocal", function()
	if LocalPlayer().excl and LocalPlayer().excl.thirdperson == true then
		return true;
	end
end)