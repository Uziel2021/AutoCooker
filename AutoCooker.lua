if not rawget(_G, "AutoCooker") then
	rawset(_G, "AutoCooker", {})

	function AutoCooker:message(text, title)
		managers.chat:_receive_message(1, (title or "SYSTEM"), text, tweak_data.system_chat_color)
	end

	function AutoCooker:Helper(text)
		if self.helper.enabled then
			if self.helper.synced then
				managers.chat:send_message( 1, managers.network:session():local_peer(), text )
			else
				self:message(text, "Helper")
			end
		end
	end

	function AutoCooker:is_server()
		return Network:is_server()
	end

	function AutoCooker:take_meth(Vector)
		if self.toggle then
			local Vector = Vector or managers.player:player_unit():camera():position()
			self:drop_current_bag(Vector)
			self:interact(self.interactions[4])
			self:drop_current_bag(Vector)
			self.current_cooking_phase = 1
		end
	end

	function AutoCooker:interact(interaction_name)
		local can_interact = function()
			return true
		end

		if not self.toggle then 
			return 
		end

		local player = managers.player:player_unit()
		if alive(player) then
			local interaction
			if type(interaction_name) == 'string' then
				for _, unit in pairs(managers.interaction._interactive_units) do
					interaction = unit and unit:interaction()
					if interaction.tweak_data == interaction_name then
						interaction.can_interact = can_interact
						interaction:interact(player)
						break
					end
				end
			end
		end
	end

	function AutoCooker:toggle_autocooker()
		self.toggle = not self.toggle
		self:message(tostring(self.toggle), "AutoCooker")
	end

	function AutoCooker:check_meth() -- Check if meth there is meth to take or if the lab is active, then peform the interaction
		for _, tracked_interaction in pairs({"methlab_bubbling", "taking_meth"}) do 
			local interaction
			for _, unit in pairs(managers.interaction._interactive_units) do
				interaction = unit:interaction()
				if interaction.tweak_data == tracked_interaction then
					if self.current_cooking_phase ~= 4 then
						self:interact(self.interactions[self.current_cooking_phase])
						self.current_cooking_phase = self.current_cooking_phase + 1
					end
					break
				end
			end
		end
	end

	function AutoCooker:drop_current_bag(pos)
		local carry_data = managers.player:get_my_carry_data()
		local rotation = managers.player:player_unit():camera():rotation()
		local position = pos or managers.player:player_unit():camera():position() -- local position = Vector3(5700, -10625, 100)
		local forward = managers.player:player_unit():camera():forward()
		if carry_data then
			if Network:is_server() then
				managers.player:server_drop_carry(carry_data.carry_id, carry_data.multiplier, carry_data.dye_initiated, carry_data.has_dye_pack, carry_data.dye_value_multiplier, position, rotation, forward, 1, nil, managers.network:session():local_peer())
			else
				managers.network:session():send_to_host("server_drop_carry", carry_data.carry_id, carry_data.multiplier, carry_data.dye_initiated, carry_data.has_dye_pack, carry_data.dye_value_multiplier, position, rotation, forward, 1, nil)
			end
			managers.hud:remove_teammate_carry_info( HUDManager.PLAYER_PANEL )
			managers.hud:temp_hide_carry_bag()
			managers.hud:remove_special_equipment("carrystacker")
			managers.player:update_removed_synced_carry_to_peers()
			managers.player:set_player_state("standard")
		end
	end

	-- cooker
	local dialog_backup = DialogManager.queue_dialog
	function DialogManager:queue_dialog(id, params)
		dialog_backup(self, id, params)

		-- Cook Off, Border Cristals
		if id == 'pln_rt1_20' or id == "Play_loc_mex_cook_03" then
			AutoCooker:Helper("Muriatic Acid")
			AutoCooker:interact(AutoCooker.interactions[1])
		elseif id == 'pln_rt1_22' or id == "Play_loc_mex_cook_04" then
			AutoCooker:Helper("Caustic Soda")
			AutoCooker:interact(AutoCooker.interactions[2])
		elseif id == 'pln_rt1_24' or id == "Play_loc_mex_cook_05" then
			AutoCooker:Helper("Hydrogen Chloride")
			AutoCooker:interact(AutoCooker.interactions[3])
		end

	end

	function AutoCooker:give_chems()
		self:interact("muriatic_acid")
		self:interact("caustic_soda")
		self:interact("hydrogen_chloride")
	end

	local orig_unit = ObjectInteractionManager.add_unit
	function ObjectInteractionManager:add_unit(unit)
		orig_unit(self, unit)
		local interaction = unit and unit:interaction()
		if interaction and interaction.tweak_data == 'taking_meth' then
			local pos = interaction:interact_position()
			local position = Vector3(pos.x + (-50 or 0), pos.y, pos.z + 10)
			BetterDelayedCalls:Add("pick_meth_bag", 1.2, function()
				if rawget(_G, "AutoCooker") then	
					AutoCooker:take_meth(position)
					AutoCooker:give_chems()
				end
			end)
		end
	end

	function AutoCooker:init()
		self.toggle = true
		self.helper = { enabled = false, synced = false } -- "meth helper"
		self.interactions = {'methlab_bubbling', 'methlab_caustic_cooler', 'methlab_gas_to_salt', "taking_meth"}
		self.level = Global.level_data.level_id
		self.current_cooking_phase = 1 -- miami and dockyard
		self:give_chems()

		if self.level == "crojob2" or self.level == "mia_1" then
			BetterDelayedCalls:Add("auto_check_meth", 1.5, function() 
				if rawget(_G, "AutoCooker") then
					self:check_meth() 
				end
			end, true)
		elseif self.level == "rat" then
			BetterDelayedCalls:Add("enable_circuit_boxes", 1.5, function() 
				if rawget(_G, "AutoCooker") then
					self:interact("circuit_breaker")
					self:interact("place_flare")
				end
			end, true)
		end

		self:message("Initialized","AutoCooker")
	end

	AutoCooker:init()
else
	AutoCooker:toggle_autocooker()
end
