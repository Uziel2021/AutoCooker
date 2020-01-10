if not rawget(_G, "AutoCooker") then
	rawset(_G, "AutoCooker", {})

	function AutoCooker:message(text, title)
		managers.chat:_receive_message(1, (title or "SYSTEM"), text, tweak_data.system_chat_color)
	end

	function AutoCooker:Helper(text)
		if self.helper then
			self:message(text, "Helper")
		end
	end

	function AutoCooker:is_server()
		return Network:is_server()
	end

	function AutoCooker:cook_meth(chemical)
		local can_interact = function()
			return true
		end

		if not self.toggle then 
			return 
		end

		local player = managers.player:player_unit()
		if alive(player) then
			local interaction
			if type(chemical) == 'string' then
				for _, unit in pairs(managers.interaction._interactive_units) do
					interaction = unit:interaction()
					if interaction.tweak_data == chemical then
						break
					end
				end
			end
			interaction.can_interact = can_interact
			interaction:interact(player)
		end
	end

	function AutoCooker:toggle_autocooker()
		self.toggle = not self.toggle
		self:message(tostring(self.toggle), "Autocooker")
	end

	-- cooker
	local dialog_backup = DialogManager.queue_dialog
	function DialogManager:queue_dialog(id, params)
		dialog_backup(self, id, params)
		if id == 'pln_rt1_20' or id == "Play_loc_mex_cook_03" then
			AutoCooker:Helper("Muriatic Acid")
			AutoCooker:cook_meth(AutoCooker.chems[1])
		elseif id == 'pln_rt1_22' or id == "Play_loc_mex_cook_04" then
			AutoCooker:Helper("Caustic Soda")
			AutoCooker:cook_meth(AutoCooker.chems[2])
		elseif id == 'pln_rt1_24' or id == "Play_loc_mex_cook_05" then
			AutoCooker:Helper("Hydrogen Chloride")
			AutoCooker:cook_meth(AutoCooker.chems[3])
		end
	end

	function PlayerManager:verify_carry(peer, carry_id) return true end
	function NetworkPeer:verify_bag(carry_id, pickup) return true end

	local unit_backup = ObjectInteractionManager.add_unit
	function ObjectInteractionManager:add_unit(unit)
		unit_backup(self, unit)
		managers.enemy:add_delayed_clbk("launchmeth", function()
			if alive(managers.player:player_unit()) then
				local interaction = alive(unit) and unit:interaction()
				local random = math.random
				if interaction and interaction.tweak_data == 'taking_meth' then
					AutoCooker:Helper("Meth bag is done.")

					if not AutoCooker.meth_pos then
						local pos = interaction:interact_position()
						AutoCooker.meth_pos = Vector3(pos.x, pos.y, pos.z + 10)
					end
					
					if AutoCooker.toggle and AutoCooker:is_server() then
						interaction:interact(managers.player:player_unit())
						managers.player:clear_carry()
						managers.player:server_drop_carry('meth', 1, false, false, 1, AutoCooker.meth_pos, Vector3(random(-180, 180), random(-180, 180), 0), Vector3(0, 0, 1), 100, nil)
					end
				end
			end
		end, Application:time() + 0.4)
	end

	function AutoCooker:init()
		self.toggle = true
		self.helper = false -- "meth helper"
		self.chems = {'methlab_bubbling', 'methlab_caustic_cooler', 'methlab_gas_to_salt'}
		self.meth_pos = nil

		self:message("Initialized","AutoCooker")
	end

	AutoCooker:init()
else
	AutoCooker:toggle_autocooker()
end
