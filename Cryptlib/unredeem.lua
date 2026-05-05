-- supplementary functions to cut down on ui code
local function unapply_dynatext(args)
	return DynaText{
		colours = { G.C.RED }, scale = 0.9,
		shadow = true, bump = true, float = true,

		string = args.string,
		rotate = args.rotate,
		pop_in = args.pop_in / G.SPEEDFACTOR,
		pop_in_rate = 1.5 * G.SPEEDFACTOR,
		pitch_shift = args.pitch_shift
	}
end

local function unapply_uibox(card, pos, dynatext)
	return UIBox({
		definition =
		{n=G.UIT.ROOT, config={ align="tm", r=0.15, colour=G.C.CLEAR, padding=0.15 }, nodes={
			{n=G.UIT.O, config={ object=dynatext } },
		}},
		config = {
			align = pos,
			offset = {x=0, y=0},
			parent = card
		},
	})
end

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
				top_dynatext = unapply_dynatext{
					string = localize({
						type = "name_text",
						set = self.config.center.set,
						key = self.config.center.key,
					}),
					rotate = 1, pop_in = 0.6
				}
				btm_dynatext = unapply_dynatext{
					string = localize("cry_unredeemed"),
					rotate = 2, pop_in = 1.4,
					pitch_shift = 0.25,
				}

				self:juice_up(0.3, 0.5)
				play_sound("card1")
				play_sound("timpani")

				self.children.top_disp = unapply_uibox(self, "tm", top_dynatext)
				self.children.bot_disp = unapply_uibox(self, "bm", btm_dynatext)
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
---@param center? table
---@return nil
function Card:unapply_to_run(center)
	local center_table = {
		name = center and center.name or self and self.ability.name,
		extra = self and self.ability.extra or center and center.config.extra,
	}
	local obj = center or self.config.center
	if type(obj.unredeem) == "function" then
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
