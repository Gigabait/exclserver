util.AddNetworkString("ESSynchInventory");
util.AddNetworkString("ESSynchInvAdd");
util.AddNetworkString("ESSynchInvRemove");

local PLAYER=FindMetaTable("Player");

function PLAYER:ESActivateItem(name,itemtype,NoSynch)
	if not self:ESHasItem(name,itemtype) then return false end

	if itemtype == ES.ITEM_TRAIL and self._es_inventory_trails then
		self:ESSetNetworkedVariable("active_trail",name);
		self:ESHandleActiveItems()
	elseif itemtype == ES.ITEM_MODEL and self._es_inventory_models then
		self:ESSetNetworkedVariable("active_model",name)
		self:ESSetModelToActive();
	elseif itemtype == ES.ITEM_AURA and self._es_inventory_auras then
		self:ESSetNetworkedVariable("active_aura",name)
		self:ESHandleActiveItems()
	elseif itemtype == ES.ITEM_MELEE and self._es_inventory_meleeweapons then
		self:ESSetNetworkedVariable("active_meleeweapon",name)
		timer.Simple(0,function()
			if IsValid(self) then
				self:ESReplaceMelee();
			end
		end)
	end 

	if !NoSynch then
		net.Start("ESSynchInvActivate");
		net.WriteString(name);
		net.WriteInt(itemtype,8)
		net.Send(self);
	end

	return true;
end
function PLAYER:ESDeactivateItem(itemtype)
	if itemtype == ES.ITEM_TRAIL and self._es_inventory_trails and self:ESGetNetworkedVariable("active_trail") then
		self:ESSetNetworkedVariable("active_trail","")
		self:ESHandleActiveItems()
	elseif itemtype == ES.ITEM_AURA and self._es_inventory_auras and self:ESGetNetworkedVariable("active_aura") then
		self:ESSetNetworkedVariable("active_aura","")
	elseif itemtype == ES.ITEM_MODEL and self._es_inventory_models and self:ESGetNetworkedVariable("active_model") then
		self:ESSetNetworkedVariable("active_model","")
		self:ESSetModelToActive();
	elseif itemtype == ES.ITEM_MELEE and self._es_inventory_meleeweapons and self:ESGetNetworkedVariable("active_meleeweapon") then
		self:ESSetNetworkedVariable("active_meleeweapon","")
		timer.Simple(0,function()
			if IsValid(self) then
				self:ESReplaceMelee();
			end
		end)
	end

	return true;
end
function PLAYER:ESGiveItem(name,itemtype,nosynch)
	if self:ESHasItem(name,itemtype) then return false end

	if itemtype == ES.ITEM_TRAIL and self._es_inventory_trails then
		table.insert(self._es_inventory_trails,name);
	elseif itemtype == ES.ITEM_MELEE and self._es_inventory_meleeweapons then
		table.insert(self._es_inventory_meleeweapons,name);
	elseif itemtype == ES.ITEM_MODEL and self._es_inventory_models then
		table.insert(self._es_inventory_models,name);
	elseif itemtype == ES.ITEM_AURA and self._es_inventory_auras then
		table.insert(self._es_inventory_auras,name);
	else
		return false;
	end

	ES.DBQuery("INSERT INTO `es_player_inventory` (steamid, itemtype, name) VALUES ('"..self:SteamID().."',"..itemtype..",'"..name.."');");

	net.Start("ESSynchInvAdd");
	net.WriteString(name);
	net.WriteInt(itemtype,8)
	net.Send(self);
	
	return true;
end
function PLAYER:ESRemoveItem(name,itemtype)
	if not self.excl or !self:ESHasItem(name,itemtype) then return end
	
	if itemtype == ES.ITEM_TRAIL and self._es_inventory_trails then
		for k,v in pairs(self._es_inventory_trails)do
			if v == name then
				table.remove(self._es_inventory_trails,k); 
			end
		end
	elseif itemtype == ES.ITEM_MELEE and self._es_inventory_meleeweapons then
		for k,v in pairs(self._es_inventory_meleeweapons)do
			if v == name then
				table.remove(self._es_inventory_meleeweapons,k);
			end
		end
	elseif itemtype == ES.ITEM_MODEL and self._es_inventory_models then
		for k,v in pairs(self._es_inventory_models)do
			if v == name then
				table.remove(self._es_inventory_models,k);
			end
		end
	elseif itemtype == ES.ITEM_AURA and self._es_inventory_auras then
		for k,v in pairs(self._es_inventory_auras)do
			if v == name then
				table.remove(self._es_inventory_auras,k);
			end
		end
	end
	
	ES.DBQuery("DELETE FROM `es_player_inventory` WHERE `steamid`='"..self:SteamID().."' AND itemtype ="..itemtype.." AND name='"..name.."';");

	net.Start("ESSynchInvRemove");
	net.WriteString(name);
	net.WriteString(itemtype)
	net.Send(self);
end
function PLAYER:ESHandleActiveItems()
	if self:GetObserverMode() == OBS_MODE_NONE and self.excl then			
		local trail=self:ESGetNetworkedVariable("active_trail");
		if trail and ES.ValidItem(trail,ES.ITEM_TRAIL) then
			if self.trail and IsValid(self.trail) then
				self.trail:Remove();
				self.trail = nil;
			end
			local len = 1.5;
			local size = 16;
			if self:ESGetVIPTier() > 3 then
				len = 3;
				size = 20;
			elseif self:ESGetVIPTier() > 1 then
				len = 3;
			end
			self.trail = util.SpriteTrail(self, 0, (ES.Trails[trail].color or Color(255,255,255)), false, size, 1, len, 1/(size+1)*0.5, string.gsub(ES.Trails[self:ESGetNetworkedVariable("active_trail")].text,"materials/",""));
		elseif self.trail and IsValid(self.trail) then
				self.trail:Remove();
				self.trail = nil;
		end
	else
		if self.trail and IsValid(self.trail) then
			self.trail:Remove();
			self.trail = nil;
		end
	end
end
function PLAYER:ESSetModelToActive()
	local model=self:ESGetNetworkedVariable("active_model");
	if not model or not ES.Models[model] then
		self:SetModel(table.Random(ES.DefaultModels));
	else
		self:SetModel(ES.Models[model].model);
	end
end
hook.Add("PlayerSpawn","ESHandleActiveItems",function(p)
	timer.Simple(0,function()
		if not IsValid(p) then return end
		p:ESHandleActiveItems();
	end);
end);
hook.Add("DoPlayerDeath","ESHandleTrailRemovalOnDeath",function(p)
	if p.trail and IsValid(p.trail) then
		p.trail:Remove();
		p.trail = nil;
	end
end);
hook.Add("ESPlayerReady","ES.Inventory.LoadInitial",function(ply)
	ES.DBQuery("SELECT `steamid`, `itemtype`, `name` FROM `es_player_inventory` WHERE `steamid`='"..ply:SteamID().."';",function(data)
		local tab={
			trails={},
			auras={},
			models={},
			meleeweapons={},
			props={}
		};

		ply._es_inventory_trails 			= {};
		ply._es_inventory_auras 			= {};
		ply._es_inventory_models 			= {};
		ply._es_inventory_meleeweapons 		= {};

		for _,v in pairs(data)do
			if v.itemtype == ES.ITEM_PROP and ES.MatchSubKey(ES.Props,"name",v.name) then
				table.insert(tab.props,v.name);
				table.insert(ply._es_inventory_props,ES.Props[v.name]);
			elseif v.itemtype == ES.ITEM_AURA and ES.MatchSubKey(ES.Auras,"name",v.name) then
				table.insert(tab.auras,v.name);
				table.insert(ply._es_inventory_auras,ES.Auras[v.name]);
			elseif v.itemtype == ES.ITEM_TRAIL and ES.MatchSubKey(ES.Trails,"name",v.name) then
				table.insert(tab.trails,v.name);
				table.insert(ply._es_inventory_trails,ES.Trails[v.name]);
			elseif v.itemtype == ES.ITEM_MODEL and ES.MatchSubKey(ES.Models,"name",v.name) then
				table.insert(tab.models,v.name);
				table.insert(ply._es_inventory_models,ES.Models[v.name]);
			elseif v.itemtype == ES.ITEM_MELEE and ES.MatchSubKey(ES.MeleeWeapons,"name",v.name) then
				table.insert(tab.meleeweapons,v.name);
				table.insert(ply._es_inventory_meleeweapons,ES.MeleeWeapons[v.name]);
			end
		end

		net.Start("ESSynchInventory");
		net.WriteTable(tab);
		net.Send(ply);
	end)
end);