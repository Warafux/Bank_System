include("shared.lua")
net.Receive("open_menu", function()
	bank_account_menu(net.ReadEntity())
	LocalPlayer():SetNWBool("in_use_bank", true)

end)
net.Receive("online_profit_not", function()
	local online_profit = net.ReadInt(16)
	local user_settings = get_cl_settings()
	if user_settings["online_profit_not"] == 1 or user_settings["online_profit_not"] == "1" then
			chat.AddText(Color(0,106,255), "[BANK] ", Color(30,30,30), "Your bank balance has increased by ",Color(100,100,255),online_profit.."%")


	end
end)

surface.CreateFont( "bank_number_menu", {
	font = "Coolvetica", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 49,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )
surface.CreateFont( "bank_title_menu", {
	font = "Coolvetica", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 30,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )
surface.CreateFont( "bank_big", {
	font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 18,
	weight = 650,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )
surface.CreateFont( "bank_med", {
	font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 18,
	weight = 650,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )
surface.CreateFont( "bank_numberwang", {
	font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 18,
	weight = 650,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )
function rp_bank(ply, cmd, args)
	if ply:IsAdmin() == true then
		net.Start("concommand_rp_bank")
			net.WriteInt(args[1], 16)
		net.SendToServer()
	end
end

function detect_cl_settings_table()
	if sql.TableExists("bank_settings") == false then
		local query_create_table = "CREATE TABLE bank_settings (id integer(1), global_profit_not integer(1), online_profit_not integer(1)) "
		sql.Query(query_create_table)
		if sql.TableExists("bank_settings") == true then
			local query_create_entry = "INSERT INTO bank_settings (id,global_profit_not,online_profit_not) VALUES (0, 0, 0)"
			sql.Query(query_create_entry)
		else
			detect_cl_settings_table()
		end
	end
end
function deposit(amount)
net.Start("deposit")
	net.WriteString(amount)
net.SendToServer()
end
function switch_cl_settings(column, oldvalue, user_settings)
	local query = ""
	if oldvalue == "1" or oldvalue == 1 then
		query = "UPDATE bank_settings SET "..column.." = 0 WHERE id = 0"
	end
	if oldvalue == "0" or oldvalue == 0 then
		query = "UPDATE bank_settings SET "..column.." = 1 WHERE id = 0"	
	end
	
	sql.Query(query)
end
function get_sv_settings()
	net.Start("get_sv_settings")
	net.SendToServer()
	net.Start("request_all_ply_all")
	net.SendToServer()
end
function get_cl_settings()
	if sql.TableExists("bank_settings") == true then
		local query = "SELECT global_profit_not, online_profit_not FROM bank_settings WHERE id = 0"
		local query_result = sql.Query(query)
		return query_result[1]
	else
		detect_cl_settings_table()
	end
end
function withdraw(amount)
net.Start("withdraw")
	net.WriteString(amount)
net.SendToServer()
end
function bank_account_menu(entity)
	local ply_wallet = 0
	local can_be_closed = true
	local confirm_message = ""
	local ply_bank = 0 -- var always updated
	local deposit_amount = 0
	local withdraw_amount = 0
	local profit = entity:GetNWInt("profit")
	local tab = 1
	
	detect_cl_settings_table()
	
	local bank_dframe = vgui.Create("DFrame")
	bank_dframe:SetSize(500,500)
	bank_dframe:Center()
	bank_dframe:ShowCloseButton(false)
	bank_dframe:MakePopup()
	bank_dframe:SetTitle("")
	bank_dframe:SetDraggable(true)
	bank_dframe.Paint = function(self,w,h)
		draw.RoundedBox(20,0,0, w, h, Color(60,60,60,240))
		draw.RoundedBox(20, 10, 80, w - 20, h - 90, Color(0, 150, 255, 255))
		draw.RoundedBox(0, 10, 110, w - 20, 2, Color(0, 0, 0, 255))
		draw.SimpleText("BANK OF THE CITY", "Trebuchet24", bank_dframe:GetWide()/2 - 80, 20, Color(0,0,0,255), 0,0)
		draw.SimpleText(confirm_message, "Trebuchet18", 20, bank_dframe:GetTall()-28, Color(0,0,0,255), 0, 2)
		
	end
	
	local supersecretbutton = vgui.Create("DButton", bank_dframe)
	supersecretbutton:SetSize(130,20)
	supersecretbutton:SetPos(bank_dframe:GetWide()-150, bank_dframe:GetTall()-28)
	supersecretbutton:SetText("")
	supersecretbutton.Paint = function(self,w,h)
			draw.SimpleText("Made by/for PSIKOTYC", "Trebuchet18", self:GetWide()/2, self:GetTall()/2, Color(0,0,0,255), 1, 1)
	end
	supersecretbutton.DoClick = function()
		gui.OpenURL("https://www.youtube.com/watch?v=JtA_WnBP_Co")
	end
	
	local bank_dframe_closebutton = vgui.Create("DButton", bank_dframe)
	bank_dframe_closebutton:SetSize(25, 25)
	bank_dframe_closebutton:SetPos(bank_dframe:GetWide()-bank_dframe_closebutton:GetWide(), 0)
	bank_dframe_closebutton:SetText("")
	bank_dframe_closebutton.Paint =  function(self,w,h)
		if can_be_closed == true then
			draw.RoundedBox(0,0,0, w, h, Color(255,60,60,255))
			draw.SimpleText("X", "Trebuchet24", 6, 0, Color(0,0,0,255), 0,0)
		end
	end
	bank_dframe_closebutton.DoClick = function()
		bank_dframe:Close()
		net.Start("menu_closed")
			net.WriteEntity(entity)
		net.SendToServer()
	end	
	
	/*ACCOUNT TAB*/
		local account_panel = vgui.Create("DPanel", bank_dframe)
		account_panel:SetSize(480,360)
		account_panel:SetPos(10,112)
		account_panel.Paint = function(self,w,h)
		draw.RoundedBox(0,0,0, w, h, Color(0, 255, 0, 0))
		
		end
	
	/*deposit TAB*/	

	/*deposit TAB*/
		local deposit_panel = vgui.Create("DPanel", bank_dframe)
		deposit_panel:SetSize(480,360)
		deposit_panel:SetPos(10,112)
		deposit_panel.Paint = function(self,w,h)
		draw.RoundedBox(0,0,0, w, h, Color(255, 0, 0, 0))
		draw.RoundedBox(8,w/2 - 270/2, 5, 270, 60, Color(0, 150, 160, 255))
		draw.RoundedBox(8,w/2 - 260/2, 10, 260, 50, Color(80, 80, 80, 230))
		draw.SimpleText(ply_bank.."$", "bank_number_menu", 365, 12.5, Color(0,0,0,255), 2, 0)
		
		draw.RoundedBox(8,w/2 - 270/2, 115, 270, 60, Color(0, 150, 160, 255))
		draw.RoundedBox(8,w/2 - 260/2, 120, 260, 50, Color(80, 80, 80, 230))
		draw.SimpleText(deposit_amount.."$", "bank_number_menu", 365, 12.5 + 110, Color(0,0,0,255), 2, 0)
		end
		
		deposit_panel:Hide()
	/*ACCOUNT TAB*/
	
	/*withdraw TAB*/
		local withdraw_panel = vgui.Create("DPanel", bank_dframe)
		withdraw_panel:SetSize(480,360)
		withdraw_panel:SetPos(10,112)
		withdraw_panel.Paint = function(self,w,h)
		draw.RoundedBox(0,0,0, w, h, Color(255, 0, 0, 0))
		draw.RoundedBox(8,w/2 - 270/2, 5, 270, 60, Color(0, 150, 160, 255))
		draw.RoundedBox(8,w/2 - 260/2, 10, 260, 50, Color(80, 80, 80, 230))
		draw.SimpleText(ply_bank.."$", "bank_number_menu", 365, 12.5, Color(0,0,0,255), 2, 0)
		
		draw.RoundedBox(8,w/2 - 270/2, 115, 270, 60, Color(0, 150, 160, 255))
		draw.RoundedBox(8,w/2 - 260/2, 120, 260, 50, Color(80, 80, 80, 230))
		draw.SimpleText(withdraw_amount.."$", "bank_number_menu", 365, 12.5 + 110, Color(0,0,0,255), 2, 0)
		end
		withdraw_panel:Hide()
	/*ACCOUNT TAB*/
	
	/*settings TAB*/
		local settings_panel = vgui.Create("DPanel", bank_dframe)
		settings_panel:SetSize(480,360)
		settings_panel:SetPos(10,112)
		settings_panel.Paint = function(self,w,h)
			draw.RoundedBox(0,0,0, w, h, Color(120, 55, 80, 0))
		end
		settings_panel:Hide()
	/*ACCOUNT TAB*/
	
	/*bank menu*/
		local bank_menu_accountinfo = vgui.Create("DButton", bank_dframe)
		bank_menu_accountinfo:SetText("")
		bank_menu_accountinfo:SetPos(10,60)
		bank_menu_accountinfo:SetSize(115,50)
		bank_menu_accountinfo.Paint = function(self,w,h)
			if tab != 1 then
				draw.RoundedBox(0,0,0, w, h, Color(0, 80, 150, 255))
			else
				draw.RoundedBox(0,0,0, w, h, Color(0, 150, 255, 255))
			end
			draw.SimpleText("ACCOUNT", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
			draw.RoundedBox(0,w-1,0, 1, h, Color(0, 0, 0, 255))
		end
		bank_menu_accountinfo.DoClick = function()
			account_panel:Show()
			account_panel:RequestFocus()
			deposit_panel:Hide()
			withdraw_panel:Hide()
			settings_panel:Hide()
			tab = 1
		end
		
		local bank_menu_deposit = vgui.Create("DButton", bank_dframe)
		bank_menu_deposit:SetText("")
		bank_menu_deposit:SetPos(125,60)
		bank_menu_deposit:SetSize(125,50)
		bank_menu_deposit.Paint = function(self,w,h)
			if tab != 2 then
				draw.RoundedBox(0,0,0, w, h, Color(0, 80, 150, 255))
			else
				draw.RoundedBox(0,0,0, w, h, Color(0, 150, 255, 255))
			end
			draw.SimpleText("DEPOSIT", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
			draw.RoundedBox(0,w-1,0, 1, h, Color(0, 0, 0, 255))
			draw.RoundedBox(0,0,0, 1, h, Color(0, 0, 0, 255))
		end
		bank_menu_deposit.DoClick = function()
			account_panel:Hide()
			deposit_panel:Show()
			deposit_panel:RequestFocus()
			withdraw_panel:Hide()
			settings_panel:Hide()
			deposit_amount = 0
			tab = 2
		end
		local bank_menu_withdraw = vgui.Create("DButton", bank_dframe)
		bank_menu_withdraw:SetText("")
		bank_menu_withdraw:SetPos(250,60)
		bank_menu_withdraw:SetSize(125,50)
		bank_menu_withdraw.Paint = function(self,w,h)
			draw.RoundedBox(0,0,0, w, h, Color(0, 102, 255, 255))
			if tab != 3 then
				draw.RoundedBox(0,0,0, w, h, Color(0, 80, 150, 255))
			else
				draw.RoundedBox(0,0,0, w, h, Color(0, 150, 255, 255))
			end
			draw.SimpleText("WITHDRAW", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
			draw.RoundedBox(0,w-1,0, 1, h, Color(0, 0, 0, 255))
			draw.RoundedBox(0,0,0, 1, h, Color(0, 0, 0, 255))
		end
		bank_menu_withdraw.DoClick = function()
			account_panel:Hide()
			deposit_panel:Hide()
			withdraw_panel:Show()
			withdraw_panel:RequestFocus()
			settings_panel:Hide()
			withdraw_amount = 0
			tab = 3
		end
		local bank_menu_settings = vgui.Create("DButton", bank_dframe)
		bank_menu_settings:SetText("")
		bank_menu_settings:SetPos(375,60)
		bank_menu_settings:SetSize(115,50)
		bank_menu_settings.Paint = function(self,w,h)
			if tab != 4 then
				draw.RoundedBox(0,0,0, w, h, Color(0, 80, 150, 255))
			else
				draw.RoundedBox(0,0,0, w, h, Color(0, 150, 255, 255))
			end
			draw.SimpleText("SETTINGS", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
			draw.RoundedBox(0,0,0, 1, h, Color(0, 0, 0, 255))
		end
		bank_menu_settings.DoClick = function()
			account_panel:Hide()
			deposit_panel:Hide()
			withdraw_panel:Hide()
			settings_panel:Show()
			settings_panel:RequestFocus()
			tab = 4
		end
	/*bank menu*/
	

	
	/*deposit tab*/

		local deposit_button = vgui.Create("DButton", deposit_panel)
		deposit_button:SetPos(15, 240)
		deposit_button:SetSize(120, 60)
		deposit_button:SetText("")
		deposit_button.Paint = function(self,w,h)
			draw.RoundedBox(8, 0, 0, w, h, Color(0, 150, 160, 255))
			draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 120, 160, 255))
			draw.SimpleText("DEPOSIT", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
			if self:IsDown() then
				draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 220, 255, 255))
				draw.SimpleText("DEPOSIT", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
			end
		end
		deposit_button.DoClick = function()
			dramatic_timer_deposit()
		end	
		
		local deposit_erasebutton = vgui.Create("DButton", deposit_panel)
		deposit_erasebutton:SetPos(deposit_panel:GetWide() - 135, 240)
		deposit_erasebutton:SetSize(120, 60)
		deposit_erasebutton:SetText("")
		deposit_erasebutton.Paint = function(self,w,h)
			draw.RoundedBox(8, 0, 0, w, h, Color(0, 150, 160, 255))
			draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 120, 160, 255))
			draw.SimpleText("DELETE", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
			if self:IsDown() then
				draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 220, 255, 255))
				draw.SimpleText("DELETE", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
			end
		end
		deposit_erasebutton.DoClick = function()
			deposit_amount = 0
		end
		
		local grid_deposit = vgui.Create("DGrid", deposit_panel)
		grid_deposit:SetPos(175,180)
		grid_deposit:SetCols(3)
		grid_deposit:SetColWide(45)
		grid_deposit:SetRowHeight(45)
		grid_deposit.Paint = function (self,w,h)
			draw.RoundedBox(8, 0, 0, w, h, Color(0, 150, 160, 255))
		end
		function add_number_deposit(amount)

				if string.len(deposit_amount) < 10 then 
					deposit_amount = deposit_amount * 10 + amount
				end
		end	
		
		function erase_number_deposit()
			if string.len(deposit_amount) != 1 and deposit_amount != 0 then 
				deposit_amount = math.floor(deposit_amount / 10)
			else
				if string.len(deposit_amount) == 1 then
					deposit_amount = 0
				end
			end
		end
		

		for i = 1, 12 do
			if i != 10 and i != 11 and i != 12 then
				local button = vgui.Create("DButton")
				button:SetText("")
				button:SetSize(45, 45)
				button.Paint = function(self,w,h)
					draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 120, 160, 255))
					draw.SimpleText(i, "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
					if self:IsDown() then
						draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 220, 255, 255))
						draw.SimpleText(i, "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
					end
				end
				button.DoClick = function()
					add_number_deposit( i)
				end
				grid_deposit:AddItem(button)
			else
				local text = ""
				
				if i == 10 then
					text = "ALL"
				end
				if i == 11 then
					text = "0"
				end
				if i == 12 then
					text = "C"
				end
				local button = vgui.Create("DButton")
				button:SetText("")
				button:SetSize(45, 45)
				button.Paint = function(self,w,h)
					draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 120, 160, 255))
					draw.SimpleText(text, "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
					if self:IsDown() then
						draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 220, 255, 255))
						draw.SimpleText(text, "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
					end
				end
					if i == 10 then
						button.DoClick = function()
							deposit_amount = ply_wallet
						end
					end
					if i == 11 then
						button.DoClick = function()
							add_number_deposit(tonumber(text))
						end
					end
					if i == 12 then
						button.DoClick = function()
							erase_number_deposit()
						end
					end
				grid_deposit:AddItem(button)
			end
		end
		
	/*withdraw tab*/
	
	
		local withdraw_button = vgui.Create("DButton", withdraw_panel)
		withdraw_button:SetPos(15, 240)
		withdraw_button:SetSize(120, 60)
		withdraw_button:SetText("")
		withdraw_button.Paint = function(self,w,h)
			draw.RoundedBox(8, 0, 0, w, h, Color(0, 150, 160, 255))
			draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 120, 160, 255))
			draw.SimpleText("WITHDRAW", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
			if self:IsDown() then
				draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 220, 255, 255))
				draw.SimpleText("WITHDRAW", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
			end
		end
		withdraw_button.DoClick = function()
			dramatic_timer_withdraw()
		end	
		
		local withdraw_erasebutton = vgui.Create("DButton", withdraw_panel)
		withdraw_erasebutton:SetPos(withdraw_panel:GetWide() - 135, 240)
		withdraw_erasebutton:SetSize(120, 60)
		withdraw_erasebutton:SetText("")
		withdraw_erasebutton.Paint = function(self,w,h)
			draw.RoundedBox(8, 0, 0, w, h, Color(0, 150, 160, 255))
			draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 120, 160, 255))
			draw.SimpleText("DELETE", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
			if self:IsDown() then
				draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 220, 255, 255))
				draw.SimpleText("DELETE", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
			end
		end
		withdraw_erasebutton.DoClick = function()
			withdraw_amount = 0
		end
		
		local grid_withdraw = vgui.Create("DGrid", withdraw_panel)
		grid_withdraw:SetPos(175,180)
		grid_withdraw:SetCols(3)
		grid_withdraw:SetColWide(45)
		grid_withdraw:SetRowHeight(45)
		grid_withdraw.Paint = function (self,w,h)
			draw.RoundedBox(8, 0, 0, w, h, Color(0, 150, 160, 255))
		end
		
		function add_number_withdraw(amount)

				if string.len(withdraw_amount) < 10 then 
					withdraw_amount = withdraw_amount * 10 + amount
				end
		end	

		function erase_number_withdraw()
			if string.len(withdraw_amount) != 1 and withdraw_amount != 0 then 
				withdraw_amount = math.floor(withdraw_amount / 10)
			else
				if string.len(withdraw_amount) == 1 then
					withdraw_amount = 0
				end
			end
		end
		
		i = 0
		for i = 1, 12 do
			if i != 10 and i != 11 and i != 12 then
				local button = vgui.Create("DButton")
				button:SetText("")
				button:SetSize(45, 45)
				button.Paint = function(self,w,h)
					draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 120, 160, 255))
					draw.SimpleText(i, "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
					if self:IsDown() then
						draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 220, 255, 255))
						draw.SimpleText(i, "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
					end
				end
				button.DoClick = function()
					add_number_withdraw(i)
				end
				grid_withdraw:AddItem(button)
			else
				local text = ""
				
				if i == 10 then
					text = "ALL"
				end
				if i == 11 then
					text = "0"
				end
				if i == 12 then
					text = "C"
				end
				local button = vgui.Create("DButton")
				button:SetText("")
				button:SetSize(45, 45)
				button.Paint = function(self,w,h)
					draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 120, 160, 255))
					draw.SimpleText(text, "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
					if self:IsDown() then
						draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 220, 255, 255))
						draw.SimpleText(text, "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
					end
				end
					if i == 10 then
						button.DoClick = function()
							withdraw_amount = ply_bank
						end
					end
					if i == 11 then
						button.DoClick = function()
							add_number_withdraw(tonumber(text))
						end
					end
					if i == 12 then
						button.DoClick = function()
							erase_number_withdraw()
						end
					end
				grid_withdraw:AddItem(button)
			end
		end
	/*withdraw tab*/
	
	/*settings tab*/
		
	
		local settings_scrollbar = vgui.Create("DScrollPanel", settings_panel)
		settings_scrollbar:SetPos(0, 0)
		settings_scrollbar:SetSize(settings_panel:GetWide(), settings_panel:GetTall())
		settings_scrollbar.Paint = function(self,w,h)
		end
	
		
			/*user settings*/
			local user_settings = get_cl_settings()
			
			local panel_user_settings = vgui.Create("DPanel", settings_scrollbar)
			panel_user_settings:SetPos(0,0)
			panel_user_settings:SetSize(settings_panel:GetWide(), 250)
			panel_user_settings.Paint = function(self,w,h)
				draw.SimpleText("User settings", "bank_title_menu", self:GetWide()/2, 20, Color(0,0,0,255), 1, 0)
				draw.SimpleText("Notifications", "bank_title_menu", 30, 50, Color(0,0,0,255), 0, 0)
				draw.SimpleText("Global profit", "bank_title_menu", 60, 100, Color(0,0,0,255), 0, 0)
				draw.SimpleText("Online profit", "bank_title_menu", 260, 100, Color(0,0,0,255), 0, 0)
				
				draw.SimpleText("(online/offline players with 30min delay)", "DermaDefault", 30, 180, Color(0,0,0,255), 0, 0)
				draw.SimpleText("(online players with 2min delay)", "DermaDefault", 250, 180, Color(0,0,0,255), 0, 0)
			end
			
			local button_global_profit_not = vgui.Create("DButton", panel_user_settings)
			button_global_profit_not:SetSize(110,40)
			button_global_profit_not:SetText("")
			button_global_profit_not:SetPos(70, 130)
			button_global_profit_not.Paint = function(self,w,h)
				draw.RoundedBox(8, 0, 0, w, h, Color(150, 150, 150, 255))
				if user_settings["global_profit_not"] == "1" then
					draw.RoundedBox(8, 55, 0, 55, h, Color(0, 255, 0, 255))
					draw.SimpleText("ON", "bank_title_menu", w/2+5, h/2, Color(0,0,0,255), 0, 1)
				end
				if user_settings["global_profit_not"] == "0" then
					draw.RoundedBox(8, 0, 0, 55, h, Color(255, 0, 0, 255))
					draw.SimpleText("OFF", "bank_title_menu", w/2-5, h/2, Color(0,0,0,255), 2, 1)
				end
			end
			button_global_profit_not.DoClick = function()
					switch_cl_settings("global_profit_not", user_settings["global_profit_not"])
			end
			
			local button_online_profit_not = vgui.Create("DButton", panel_user_settings)
			button_online_profit_not:SetSize(110,40)
			button_online_profit_not:SetText("")
			button_online_profit_not:SetPos(270, 130)
			button_online_profit_not.Paint = function(self,w,h)
				draw.RoundedBox(8, 0, 0, w, h, Color(150, 150, 150, 255))
				if user_settings["online_profit_not"] == "1" then
					draw.RoundedBox(8, 55, 0, 55, h, Color(0, 255, 0, 255))
					draw.SimpleText("ON", "bank_title_menu", w/2+5, h/2, Color(0,0,0,255), 0, 1)
				end
				if user_settings["online_profit_not"] == "0" then
					draw.RoundedBox(8, 0, 0, 55, h, Color(255, 0, 0, 255))
					draw.SimpleText("OFF", "bank_title_menu", w/2-5, h/2, Color(0,0,0,255), 2, 1)
				end
			end
			button_online_profit_not.DoClick = function()
					switch_cl_settings("online_profit_not", user_settings["online_profit_not"])
			end
			
			local a = 320
		
			/*admin settings*/
			if LocalPlayer():IsAdmin() == true then
				get_sv_settings()
				target_rpname = ""
				target_wallet = 0
				target_bank = 0
				target_steamid64 = ""
				panel_admin_settings = vgui.Create("DPanel", settings_scrollbar)
				panel_admin_settings:SetPos(0,250)
				panel_admin_settings:SetSize(settings_panel:GetWide(), 500)
				panel_admin_settings.Paint = function(self,w,h)
					draw.SimpleText("ADMIN settings", "bank_title_menu", self:GetWide()/2, 0, Color(0,0,0,255), 1, 0)
					draw.RoundedBox(8, 35, 220, 400, 130, Color(0, 200, 200, 255))
					draw.SimpleText("Player database", "DermaLarge", 20, 30, Color(0,0,0,255), 0, 0)
					draw.SimpleText("SteamID64", "DermaLarge", 50, 220, Color(0,0,0,255), 0, 0)
					draw.SimpleText("Bank", "DermaLarge", 210, 220, Color(0,0,0,255), 0, 0)
					draw.SimpleText("Action", "DermaLarge", 330, 220, Color(0,0,0,255), 0, 0)
					draw.SimpleText(target_steamid64, "bank_big", 110, 290, Color(0,0,0,255), 1, 0)
					draw.SimpleText("Global profit -        %", "DermaLarge", 20, 30 + a, Color(0,0,0,255), 0, 0)
					draw.SimpleText("Online profit -        %", "DermaLarge", 20, 80 + a, Color(0,0,0,255), 0, 0)
					draw.SimpleText("Global profit: every 30 minutes.", "DermaDefault", 22, 60 + a, Color(0,0,0,255), 0, 0)
					draw.SimpleText("Online profit: every 2 minutes.", "DermaDefault", 22, 110 + a, Color(0,0,0,255), 0, 0)
				end
				
				player_list = vgui.Create("DListView", panel_admin_settings)
				player_list:SetSize(400,150)
				player_list:SetPos(35,60)
				player_list:AddColumn("SteamID64"):SetFixedWidth(120)
				--player_list:AddColumn("RPName"):SetFixedWidth(100)
				--player_list:AddColumn("Wallet"):SetFixedWidth(90)
				player_list:AddColumn("Bank"):SetFixedWidth(90)
			
			
				local player_bank_nwang = vgui.Create("DNumberWang", panel_admin_settings)
				player_bank_nwang:SetPos(190, 280)
				player_bank_nwang:SetSize(110, 30)
				player_bank_nwang:SetMinMax(0,999999999)
				player_bank_nwang:SetFont("bank_numberwang")
				
				function player_list:DoDoubleClick(lineID, line)
					target_steamid64 = line:GetColumnText(1)
					--target_wallet = line:GetColumnText(3)
					target_bank = line:GetColumnText(2)
					--target_rpname = line:GetColumnText(2)
					player_bank_nwang:SetValue(target_bank)
				end

				local set_money_button = vgui.Create("DButton", panel_admin_settings)
				set_money_button:SetPos(320, 260)
				set_money_button:SetSize(100, 30)
				set_money_button:SetText("")
				set_money_button.Paint = function(self,w,h)
					draw.RoundedBox(4, 0, 0, w, h, Color(0, 150, 160, 255))
					draw.RoundedBox(4,2,2, w-4, h-4, Color(120, 120, 160, 255))
					draw.SimpleText("SET", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
					if self:IsDown() then
						draw.RoundedBox(4,2,2, w-4, h-4, Color(120, 220, 255, 255))
						draw.SimpleText("SET", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
					end
				end
				
				set_money_button.DoClick = function()
					if target_steamid64 != "" then
						net.Start("set_bank_value")
							net.WriteString("set")
							net.WriteString(target_steamid64)
							net.WriteInt(player_bank_nwang:GetValue(), 16)
						net.SendToServer()
						net.Start("request_all_ply_all")
						net.SendToServer()
					end
				end
				
				local add_money_button = vgui.Create("DButton", panel_admin_settings)
				add_money_button:SetPos(320, 300)
				add_money_button:SetSize(100, 30)
				add_money_button:SetText("")
				add_money_button.Paint = function(self,w,h)
					draw.RoundedBox(4, 0, 0, w, h, Color(0, 150, 160, 255))
					draw.RoundedBox(4,2,2, w-4, h-4, Color(120, 120, 160, 255))
					draw.SimpleText("ADD", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
					if self:IsDown() then
						draw.RoundedBox(4,2,2, w-4, h-4, Color(120, 220, 255, 255))
						draw.SimpleText("ADD", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
					end
				end
				
				add_money_button.DoClick = function()
					if target_steamid64 != "" then
						net.Start("set_bank_value")
							net.WriteString("add")
							net.WriteString(target_steamid64)
							net.WriteInt(player_bank_nwang:GetValue(), 16)
						net.SendToServer()
						net.Start("request_all_ply_all")
						net.SendToServer()
					end
				end
				
				local refresh_player_table = vgui.Create("DButton", panel_admin_settings)
				refresh_player_table:SetSize(15, 15)
				refresh_player_table:SetPos(420,40)
				refresh_player_table:SetText("")
				refresh_player_table.Paint = function(self,w,h)
					surface.SetMaterial(Material("icon16/arrow_refresh.png"))
					surface.SetDrawColor(255, 255, 255, 255)
					surface.DrawTexturedRect(0, 0, w, h)
				end
				
				refresh_player_table.DoClick = function()
					net.Start("request_all_ply_all")
					net.SendToServer()
				end
			end
		net.Receive("requested_all_ply_all", function()
				local player_table = net.ReadTable()
				player_list:Clear()
				for k,v in pairs(player_table) do
					if LocalPlayer():SteamID64() == v["steamid64"] then
						player_list:AddLine(v["steamid64"],v["bank"])
					else
						player_list:AddLine(v["steamid64"], v["bank"])
					end
				end
			end)
			
				
			
			
			net.Receive("receive_sv_settings", function()
				
				local global_profit = net.ReadInt(16)
				local online_profit = net.ReadInt(16)				
				
				local numberwang_global_profit = vgui.Create("DNumberWang", panel_admin_settings)
				numberwang_global_profit:SetPos(190, 35 + a)
				numberwang_global_profit:SetSize(50, 30)
				numberwang_global_profit:SetMinMax(0, 100)
				numberwang_global_profit:SetValue(global_profit)
				numberwang_global_profit:SetFont("bank_numberwang")
			
				local numberwang_online_profit = vgui.Create("DNumberWang", panel_admin_settings)
				numberwang_online_profit:SetPos(190, 85 + a)
				numberwang_online_profit:SetSize(50, 30)
				numberwang_online_profit:SetMinMax(0, 100)
				numberwang_online_profit:SetValue(online_profit)
				numberwang_online_profit:SetFont("bank_numberwang")
								
				local set_admin_settings = vgui.Create("DButton", panel_admin_settings)
				set_admin_settings:SetText("")
				set_admin_settings:SetSize(450,30)
				set_admin_settings:SetPos(15, 130 + a)
				set_admin_settings.Paint = function(self,w,h)
					draw.RoundedBox(8, 0, 0, w, h, Color(0, 150, 160, 255))
					draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 120, 160, 255))
					draw.SimpleText("SAVE", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
					if self:IsDown() then
						draw.RoundedBox(8,2,2, w-4, h-4, Color(120, 220, 255, 255))
						draw.SimpleText("SAVE", "Trebuchet24", w/2, h/2, Color(0,0,0,255), 1, 1)
					end
				end
				set_admin_settings.DoClick = function()
					net.Start("set_sv_settings")
						net.WriteInt(numberwang_global_profit:GetValue(), 16)
						net.WriteInt(numberwang_online_profit:GetValue(), 16)
					net.SendToServer()
				end
		end)
		
	/*settings tab*/
	
	
	/*blocktab*/
		local block_panel = vgui.Create("DPanel", bank_dframe)
		block_panel:SetSize(bank_dframe:GetWide(), bank_dframe:GetTall())
		block_panel:SetPos(0, 0)
		block_panel:Hide()
		block_panel.Paint = function(self,w,h)
		draw.RoundedBox(20,0,0, w, h, Color(50, 50, 5, 100))
		end
		local block_panel_deposit = vgui.Create("DPanel", deposit_panel)
		block_panel_deposit:SetSize(deposit_panel:GetWide(), deposit_panel:GetTall())
		block_panel_deposit:SetPos(0, 0)
		block_panel_deposit:Hide()
		block_panel_deposit.Paint = function(self,w,h)
		draw.RoundedBox(20,0,0, w, h, Color(50, 50, 5, 0))
		end	
		local block_panel_withdraw = vgui.Create("DPanel", withdraw_panel)
		block_panel_withdraw:SetSize(withdraw_panel:GetWide(), withdraw_panel:GetTall())
		block_panel_withdraw:SetPos(0, 0)
		block_panel_withdraw:Hide()
		block_panel_withdraw.Paint = function(self,w,h)
		draw.RoundedBox(20,0,0, w, h, Color(50, 50, 5, 0))
		end
	/*blocktab*/
	
	function dramatic_timer_deposit()
		local time = 5
		can_be_closed = false
		block_panel:Show()
		block_panel_deposit:Show()
		bank_dframe_closebutton:SetEnabled(false)
		confirm_message = "Executing order. Wait please."
		timer.Simple(time,function()
			if IsValid(bank_dframe) and IsValid(bank_menu_deposit) and IsValid(block_panel) then
				deposit(deposit_amount)
				block_panel:Hide()
				block_panel_deposit:Hide()
				can_be_closed = true
				bank_dframe_closebutton:SetEnabled(true)
				confirm_message = ""
				deposit_amount = 0
			end
		end)
	end 
	function dramatic_timer_withdraw()
		local time = 5
		can_be_closed = false
		block_panel:Show()
		block_panel_withdraw:Show()
		bank_dframe_closebutton:SetEnabled(false)
		confirm_message = "Executing order. Wait please."
		timer.Simple(time,function()
			if IsValid(bank_dframe) and IsValid(bank_menu_deposit) and IsValid(block_panel) then
				withdraw(withdraw_amount)
				block_panel:Hide()
				block_panel_withdraw:Hide()
				can_be_closed = true
				bank_dframe_closebutton:SetEnabled(true)
				confirm_message = ""
				withdraw_amount = 0
			end
		end)
	end 
	/*DETECT KEYS */
		/*deposit panel*/
		function deposit_panel:OnKeyCodePressed(key)
			if can_be_closed == true then
				if key == 38 then
					add_number_deposit(1)
				end
				if key == 44 then
					add_number_deposit(7)
				end
				if key == 45 then
					add_number_deposit(8)
				end
				if key == 46 then
					add_number_deposit(9)
				end
				if key == 41 then
					add_number_deposit(4)
				end
				if key == 42 then
					add_number_deposit(5)
				end
				if key == 43 then
					add_number_deposit(6)
				end
				if key == 39 then
					add_number_deposit(2)
				end
				if key == 40 then
					add_number_deposit(3)
				end
				if key == 37 then
					add_number_deposit(0)
				end
				if key == 66 then
					erase_number_deposit()
				end
				if key == 64 then
					dramatic_timer_deposit()
				end
			end
		end
		/*deposit panel*/
		/*withdraw panel*/
		function withdraw_panel:OnKeyCodePressed(key)
			if can_be_closed == true then
				if key == 38 then
					add_number_withdraw(1)
				end
				if key == 44 then
					add_number_withdraw(7)
				end
				if key == 45 then
					add_number_withdraw(8)
				end
				if key == 46 then
					add_number_withdraw(9)
				end
				if key == 41 then
					add_number_withdraw(4)
				end
				if key == 42 then
					add_number_withdraw(5)
				end
				if key == 43 then
					add_number_withdraw(6)
				end
				if key == 39 then
					add_number_withdraw(2)
				end
				if key == 40 then
					add_number_withdraw(3)
				end
				if key == 37 then
					add_number_withdraw(0)
				end
				if key == 66 then
					erase_number_withdraw()
				end
				if key == 64 then
					dramatic_timer_withdraw()
				end
			end
		end
		/*withdraw panel*/
	
	
	
	/*DETECT KEYS */
	/*deposit tab*/
	net.Receive("close_menu", function()
		bank_dframe:Close()
		net.Start("menu_closed")
			net.WriteEntity(entity)
		net.SendToServer()
	end)
			
	timer.Create("update_data", 0.05, 0, function()
		if IsValid(bank_dframe) then
			net.Start("request_ply_info")
				net.WriteEntity(LocalPlayer())
			net.SendToServer()
			user_settings = get_cl_settings()
		else
			timer.Destroy("update_data")
		end
	end)
	
	net.Receive("requested_ply_info", function()
		local ply_info = util.JSONToTable(net.ReadString())
		if IsValid(bank_dframe) then
			ply_wallet = tonumber(ply_info["wallet"])
			ply_rpname = tonumber(ply_info["rpname"])
			ply_bank = tonumber(ply_info["bank"])
		end
	end)	
end
function ENT:Draw()
    self:DrawModel()
	
	local Pos = self:GetPos()
    local Ang = self:GetAngles()
    local title = "BANK"
	local text = "Press E to start managing your bank account"
	local in_use = self:GetNWBool("in_use")
	local settings_drawclmenu = self:GetNWBool("settings_drawclmenu")
	local profit = self:GetNWInt("profit")
	if settings_drawclmenu == true then
		Ang:RotateAroundAxis(Ang:Up(), 90)
		Ang:RotateAroundAxis(Ang:Forward(), 94)
		cam.Start3D2D(Pos + Ang:Up() * 8.7, Ang, 0.15)
			draw.RoundedBox(0,-256*0.512,-630,262,62,Color(0,106,255,255))
			draw.SimpleText(title,"DermaLarge",0,-600,Color(0,0,0,255),1,1)
			draw.SimpleText(profit.."% profit!","DermaDefault",0,-575,Color(0,0,0,255),1,1)
			cam.End3D2D()
			
		cam.Start3D2D(Pos + Ang:Up() * 14.1, Ang+Angle(0,0,-1), 0.1)
			draw.RoundedBox(0,-384*0.51,-204,393,96, Color(0,106,255,255))	
			draw.SimpleText(text,"Trebuchet24",-387*0.50,-165,Color(0,0,0,255),0,1)
		cam.End3D2D()
		
		cam.Start3D2D(Pos + Ang:Up() * 15.5, Ang+Angle(0,0,-4), 0.1) --caja centro-derecha
			draw.RoundedBox(0,0,-819,180,240, Color(0,106,255,255))
			if in_use == true then
				local in_use_player = util.JSONToTable(self:GetNWString("in_use_player")) 
				draw.SimpleText("Welcome,","bank_number_menu",5,-810,Color(0,0,0,255,0,2))
				draw.SimpleText(in_use_player["rpname"],"bank_big",20,-770,Color(0,0,0,255,1,2))				
				draw.SimpleText(in_use_player["bank"].."$","bank_number_menu",170,-700,Color(0,0,0,255),2)		
				--draw.SimpleText(in_use_player["wallet"].."$","bank_number_menu",170,-650,Color(0,0,0,255),2)		
			
			else
				draw.SimpleText("tete klk","bank_number_menu",5,-810,Color(0,0,0,255,0,2))
			end
		
		
		
		
		cam.End3D2D()
	end
end
concommand.Add("rp_bank", rp_bank)