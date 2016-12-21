AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")
util.AddNetworkString("open_menu")
util.AddNetworkString("menu_closed")
util.AddNetworkString("request_ply_info")
util.AddNetworkString("requested_ply_info")
util.AddNetworkString("deposit")
util.AddNetworkString("withdraw")
util.AddNetworkString("deposit_confirm")
util.AddNetworkString("concommand_rp_bank")
util.AddNetworkString("receive_sv_settings")
util.AddNetworkString("set_sv_settings")
util.AddNetworkString("global_profit_not")
util.AddNetworkString("online_profit_not")
util.AddNetworkString("set_bank_value")
util.AddNetworkString("get_sv_settings")
util.AddNetworkString("request_all_ply_all")
util.AddNetworkString("requested_all_ply_all")
util.AddNetworkString("close_menu")
util.AddNetworkString("advert_admins_global_profit")

local empty_table = {
		steamid64 = "",
		rpname = "",
		wallet = 0,
		bank = 0,
	}
bank_config = {
	global_profit = 0,
	online_profit = 0
}
net.Receive("set_bank_value", function()
	local typ = net.ReadString()
	local steamid64 = net.ReadString()
	local newvalue = net.ReadInt(16)
	local query = ""
	if typ == "set" then
		query = "UPDATE bank_players SET bank = "..newvalue.." WHERE steamid64 = "..steamid64
	else
		query = "UPDATE bank_players SET bank = bank +"..newvalue.." WHERE steamid64 = "..steamid64
	end
	sql.Query(query)
end)
net.Receive("get_sv_settings", function(len, ply)
	local query = "SELECT global_profit, online_profit FROM bank_config"
	local query_result = sql.Query(query)
	net.Start("receive_sv_settings")
		net.WriteInt(query_result[1]["global_profit"], 16)
		net.WriteInt(query_result[1]["online_profit"], 16)
	net.Send(ply)
end)
net.Receive("menu_closed", function(len, ply)
	local entity = net.ReadEntity()
	entity:SetNWBool("in_use", false)
	entity:SetNWString("in_use_player", util.TableToJSON(empty_table))
end)
net.Receive("deposit", function(len, ply)
	local amount = tonumber(net.ReadString())
	local wallet = tonumber(get_darkrp_ply_info(ply,"wallet"))
	if IsValid(ply) and amount > 0 and amount <= wallet then
		local query_1 = "UPDATE bank_players SET bank = bank + "..amount.." WHERE steamid64 = '"..ply:SteamID64().."'"
		sql.Query(query_1)
		ply:addMoney(-amount)
	end
end)
net.Receive("set_sv_settings", function()
	local new_global_profit = tonumber(net.ReadInt(16))
	local new_online_profit = tonumber(net.ReadInt(16))
	local query = "UPDATE bank_config SET global_profit = "..new_global_profit..", online_profit = "..new_online_profit.." WHERE id = 0"
	local query_result = sql.Query(query)
end)
function get_ply_info(ply, info)
	local query = "SELECT "..info.." FROM bank_players WHERE steamid64 = '"..ply:SteamID64().."'"
	local query_result = sql.Query(query)
	if query_result != nil and istable(query_result) then
		return query_result[1][info]
	else
		return nil
	end
end
function get_darkrp_ply_info(ply, info)
	local query = "SELECT "..info.." FROM darkrp_player WHERE uid = '"..ply:UniqueID().."'"
	local query_result = sql.Query(query)
	if query_result != nil and istable(query_result) then
		return query_result[1][info]
	else
		return nil
	end
end
net.Receive("withdraw", function(len, ply)
	local amount = tonumber(net.ReadString())
	local bank = tonumber(get_ply_info(ply, "bank"))
	if IsValid(ply) and amount <= bank  then
		local query_1 = "UPDATE bank_players SET bank = bank - "..amount.." WHERE steamid64 = '"..ply:SteamID64().."'"
		sql.Query(query_1)
		ply:addMoney(amount)
	end
end)
net.Receive("concommand_rp_bank", function(len, ply)
	local amount = net.ReadInt(16)
	local query = "UPDATE bank_players SET bank = "..amount.." WHERE steamid64 = '"..ply:SteamID64().."'"
	local query_result = sql.Query(query)
end)
function update_bank_config()
	local query_table_config = "SELECT global_profit, online_profit FROM bank_config WHERE id = 0"
	local query_table_config_result = sql.Query(query_table_config)
	if query_table_config_result != nil then
		bank_config["global_profit"] = query_table_config_result[1]["global_profit"]
		bank_config["online_profit"] = query_table_config_result[1]["online_profit"]
		for k,v in pairs(ents.GetAll()) do
			if v:GetClass() == "bank" then
				v:SetNWInt("profit", bank_config["online_profit"])
			end
		end
	end
end
function give_profit_global()
	local global_profi = tonumber(bank_config["global_profit"])
	if global_profi > 0 then 
		local multiplier = global_profi/100 + 1
		local query_1 = "UPDATE bank_players SET bank = CAST(CAST(bank * "..multiplier.." AS decimal) AS int)"
		sql.Query(query_1)
	end
end
function give_profit_online()
	local online_profit = tonumber(bank_config["online_profit"])/100
	if online_profit > 0 then
		local multiplier = online_profit + 1
		for k,v in pairs(player.GetAll()) do
			local query = "UPDATE bank_players SET bank = CAST(CAST(bank * "..multiplier.." AS decimal) AS int) WHERE steamid64 = '"..v:SteamID64().."'"
			local query_result = sql.Query(query)
		end
		net.Start("online_profit_not")
			net.WriteInt(bank_config["online_profit"], 16)
		net.Broadcast()
	end
end
function detect_bank_config_table()
	if sql.TableExists("bank_config") == false then
		local query_create_table = "CREATE TABLE bank_config ('id' integer(1), 'global_profit' integer(3), 'online_profit' integer(3))"
		sql.Query(query_create_table)
		local query_create_table_entry = "INSERT INTO bank_config (id,global_profit,online_profit) VALUES (0, 0, 0)"
		sql.Query(query_create_table_entry)
	end
	update_bank_config()
		
		timer.Create("update_bank_config", 10, 0, function()
			update_bank_config()
		end)
		
		timer.Create("profit_global_func", 1800, 0, function() --1800
			give_profit_global()
		end)
		
		timer.Create("profit_online_func", 120, 0, function() --120
			give_profit_online()
		end)

end
function detect_bank_table()
	if sql.TableExists("bank_players") == false then
		local query_add_table = "CREATE TABLE bank_players ('steamid64' integer(20), 'bank' integer(10))"
		sql.Query(query_add_table)
		print(sql.LastError())
	end
end
function get_ply_info_all(ply)
	local query = "SELECT * FROM bank_players WHERE steamid64 = '"..ply:SteamID64().."'"
	local query_result = sql.Query(query)
	if query_result != nil and istable(query_result) then
		return util.TableToJSON(query_result[1])
	else
		return nil
	end
end
function get_darkrp_ply_info_all(ply)
	local query = "SELECT * FROM darkrp_player WHERE uid = '"..ply:UniqueID().."'"
	local query_result = sql.Query(query)
	if query_result != nil and istable(query_result) then
		return util.TableToJSON(query_result[1])
	else
		return nil
	end
end
function get_all_ply_info_all()
	local query = "SELECT * FROM bank_players"
	local query_result = sql.Query(query)
	if query_result != nil and istable(query_result) then
		return util.TableToJSON(query_result)
	else
		return nil
	end
end
function get_all_darkrp_ply_info_all()
	local query = "SELECT * FROM darkrp_player"
	local query_result = sql.Query(query)
	if query_result != nil and istable(query_result) then
		return util.TableToJSON(query_result)
	else
		return nil
	end
end
net.Receive("request_all_ply_all", function(len, ply)
local plys_bank = util.JSONToTable(get_all_ply_info_all())
	if ply != nil then
		net.Start("requested_all_ply_all")
			net.WriteTable(plys_bank)
		net.Send(ply)
	end
end)

net.Receive("request_ply_info", function(len, requester)
	local ply = net.ReadEntity()
	
	local requested_ply_info = util.JSONToTable(get_ply_info_all(ply))
	local requested_dark_rp_info = util.JSONToTable(get_darkrp_ply_info_all(ply))
	local result_table = {
	rpname = requested_dark_rp_info["rpname"],
	bank = requested_ply_info["bank"],
	wallet = requested_dark_rp_info["wallet"]
	}
	net.Start("requested_ply_info")
		if requested_ply_info != false or requested_ply_info != nil then
			net.WriteString(util.TableToJSON(result_table))
		else
			net.WriteString("ERROR")
		end
	net.Send(requester)
end)
function ENT:Initialize() 
	self:SetModel("models/props/cs_assault/TicketMachine.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)    
	self:SetMoveType(MOVETYPE_VPHYSICS)  
	self:SetSolid(SOLID_VPHYSICS)        
	self:SetUseType(SIMPLE_USE)
	self:SetColor(Color(255,255,255,255))
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	detect_bank_config_table()
	detect_bank_table(self)
	self:SetNWString("in_use_player", util.TableToJSON(empty_table))
	self:SetNWBool("in_use", false)
	
	/*settings*/
	self:SetNWBool("settings_drawclmenu", true)
end

function ENT:AcceptInput(name, activator, caller)
	local in_use = self:GetNWBool("in_use")
	local args = {global_profit = global_profi}
	if name == "Use" and caller != nil and in_use == false and caller:SteamID64() != 0 then
		if get_ply_info_all(caller) != nil then
			self:SetNWBool("in_use", true)
			local ply_table = {
			steamid64 = caller:SteamID64(),
			rpname = get_darkrp_ply_info(caller,"rpname"),
			wallet = get_darkrp_ply_info(caller, "wallet"),
			bank = get_ply_info(caller, "bank"),
			}
			self:SetNWString("in_use_player", util.TableToJSON(ply_table))
			net.Start("open_menu")
				net.WriteEntity(self)
			net.Send(activator)
		end
	else
		if in_use == true then
			
		end
		if caller:SteamID64() == 0 then
			caller:ChatPrint("THIS ONLY WORKS IN MP!")
		end
	end
end
function ENT:Think()
	local in_use = self:GetNWBool("in_use")
	if in_use == true then
		local in_use_player = util.JSONToTable(self:GetNWString("in_use_player"))
		if player.GetBySteamID64(in_use_player["steamid64"]) != nil and player.GetBySteamID64(in_use_player["steamid64"]) != false then
			local ply = player.GetBySteamID64(in_use_player["steamid64"])
				if ply:GetEyeTrace().Entity != nil then
					if ply:GetEyeTrace().Entity != self or ply:GetPos():Distance(self:GetPos()) > 110 then
						net.Start("close_menu")
						net.Send(ply)
					end
				else
					net.Start("close_menu")
					net.Send(ply)
				end
		else
			net.Start("close_menu")
			net.Send(ply)
		end
	else
		self:SetNWBool("in_use_player", util.TableToJSON(empty_table))
	end

end