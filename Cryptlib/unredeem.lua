-- Unapply a voucher and play the corresponding animation.
---@return nil
function Card:unredeem()
		if self.ability.set == "Voucher" then
		stop_use()
		if not self.config.center.discovered then
			discover_card(self.config.center)
		end

		self.states.hover.can = false
		local top_dynatext, btm_dynatext

		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.4,
			func = function()
				top_dynatext = DynaText({
					string = localize({
						type = "name_text",
						set = self.config.center.set,
						key = self.config.center.key,
					}),
					colours = { G.C.RED },
					rotate = 1,
					shadow = true,
					bump = true,
					float = true,
					scale = 0.9,
					pop_in = 0.6 / G.SPEEDFACTOR,
					pop_in_rate = 1.5 * G.SPEEDFACTOR,
				})
				btm_dynatext = DynaText({
					string = localize("cry_unredeemed"),
					colours = { G.C.RED },
					rotate = 2,
					shadow = true,
					bump = true,
					float = true,
					scale = 0.9,
					pop_in = 1.4 / G.SPEEDFACTOR,
					pop_in_rate = 1.5 * G.SPEEDFACTOR,
					pitch_shift = 0.25,
				})

				self:juice_up(0.3, 0.5)
				play_sound("card1")
				play_sound("timpani")

				self.children.top_disp = UIBox({
					definition =
					{n=G.UIT.ROOT, config={ align="tm", r=0.15, colour=G.C.CLEAR, padding=0.15 }, nodes={
						{n=G.UIT.O, config={ object=top_dynatext } },
					}},
					config = {
						align = "tm",
						offset = {x=0, y=0},
						parent = self
					},
				})
				self.children.bot_disp = UIBox({
					definition =
					{n=G.UIT.ROOT, config={ align="tm", r=0.15, colour=G.C.CLEAR, padding=0.15 }, nodes={
						{n=G.UIT.O, config={ object=btm_dynatext } },
					}},
					config = {
						align = "bm",
						offset = {x=0, y=0},
						parent = self
					},
				})
				return true
			end,
		}))

		if not self.debuff then
			self:unapply_to_run()
		end

		delay(0.6)
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 2.6,
			func = function()
				top_dynatext:pop_out(4)
				btm_dynatext:pop_out(4)
				return true
			end,
		}))

		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.5,
			func = function()
				self.children.top_disp:remove()
				self.children.top_disp = nil
				self.children.bot_disp:remove()
				self.children.bot_disp = nil
				return true
			end,
		}))
	end

	G.E_MANAGER:add_event(Event({
		func = function()
			Spectrallib.update_used_vouchers()
			return true
		end,
	}))
end

-- Remove a voucher and its effects from the run.
---@param center table
---@return nil
function Card:unapply_to_run(center)
	local center_table = {
		name = center and center.name or self and self.ability.name,
		extra = self and self.ability.extra or center and center.config.extra,
	}
	local obj = center or self.config.center
	if obj.unredeem and type(obj.unredeem) == "function" then
		obj:unredeem(self)
		return
	end

	local vanilla_unapply_result = Spectrallib.vanilla_unapply_results[center_table.name]
	if vanilla_unapply_result then
		vanilla_unapply_result(self, center_table)
	end
end

---@return nil
function Spectrallib.update_used_vouchers()
	if not (G and G.GAME and G.vouchers) then return end

	G.GAME.used_vouchers = {}
	for _,voucher in ipairs(G.vouchers.cards) do
		G.GAME.used_vouchers[voucher.config.center_key] = true
	end
end