-- everything demicolon needs (not really as simple anymore)
function Spectrallib.demicolonGetTriggerable(card)
	local n = { false, false }
	if not card then return n end

	if (
		card.config.center.demicoloncompat
		or card.config.center.demicolon_compat
		or card.config.center.forcetrigger_compat
		or Spectrallib.forcetriggerVanillaCheck(card)
	) then
		n[1] = true
	else
		n[1] = false
	end

	if card.ability.consumeable and Spectrallib.forcetriggerConsumableCheck(card) then
		n[1] = true
	end

	return n
end

local calc_ref = Card.calculate_joker
function Card:calculate_joker(...)
	local ret =  calc_ref(self, ...)
	G.slib_copied_stack = nil
	return ret
end

---@param card Card
---@param context table
---@return table
function Spectrallib.get_forcetrigger_results(card, context)
	G.slib_copied_stack = G.slib_copied_stack or {}
	if not card or Spectrallib.in_table(G.slib_copied_stack, card) then
		return {}
	end

	table.insert(G.slib_copied_stack, card)

	local results = {}
	local check = Spectrallib.forcetriggerVanillaCheck(card)

	if not check and card.ability.set == "Joker" then
		local demicontext = SMODS.shallow_copy(context)
		demicontext.forcetrigger = true
		if card.config.center.forcetrigger then
			results.jokers = card.config.center:forcetrigger(card, demicontext) or {}
		elseif card.config.center.calculate then
			results.jokers = card.config.center:calculate(card, demicontext) or {}
		end
		results.jokers.card = card
		demicontext = nil
	elseif check and card.ability.set == "Joker" then
		-- page 5
		if card.ability.name == "Cavendish" then
			results = { jokers = { xmult = card.ability.extra.Xmult, card = card } }
			G.E_MANAGER:add_event(Event({
				trigger = "after",
				delay = 0.4,
				func = function()
					SMODS.destroy_cards(card, nil, nil, true)
					return true
				end,
			}))
		end
		if card.ability.name == "Card Sharp" then
			results = { jokers = { xmult = card.ability.extra.Xmult, card = card } }
		end
		if card.ability.name == "Red Card" then
			card.ability.mult = card.ability.mult + card.ability.extra
			results = { jokers = { mult = card.ability.mult, card = card } }
		end
		if card.ability.name == "Madness" then
			card.ability.x_mult = card.ability.x_mult + card.ability.extra
			local destructable_jokers = {}
			for i = 1, #G.jokers.cards do
				if
					G.jokers.cards[i] ~= card
					and not G.jokers.cards[i].ability.eternal
					and not G.jokers.cards[i].getting_sliced
				then
					destructable_jokers[#destructable_jokers + 1] = G.jokers.cards[i]
				end
			end
			local joker_to_destroy = #destructable_jokers > 0
					and pseudorandom_element(destructable_jokers, pseudoseed("madness"))
				or nil

			if joker_to_destroy and not card.getting_sliced then
				joker_to_destroy.getting_sliced = true
				G.E_MANAGER:add_event(Event({
					func = function()
						card:juice_up(0.8, 0.8)
						joker_to_destroy:start_dissolve({ G.C.RED }, nil, 1.6)
						return true
					end,
				}))
			end
			results = { jokers = { xmult = card.ability.x_mult, card = card } }
		end
		if card.ability.name == "Square Joker" then
			card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
			results = { jokers = { chips = card.ability.extra.chips, card = card } }
		end
		if card.ability.name == "Seance" then
			G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
			G.E_MANAGER:add_event(Event({
				trigger = "after",
				delay = 0.4,
				func = function()
					local card = create_card("Spectral", G.consumeables, nil, nil, nil, nil, nil, "sea")
					card:add_to_deck()
					G.consumeables:emplace(card)
					G.GAME.consumeable_buffer = 0
					return true
				end,
			}))
		end
		if card.ability.name == "Riff-raff" then
			local jokers_to_create = math.min(2, G.jokers.config.card_limit - (#G.jokers.cards + G.GAME.joker_buffer))
			G.GAME.joker_buffer = G.GAME.joker_buffer + jokers_to_create
			G.E_MANAGER:add_event(Event({
				func = function()
					for i = 1, jokers_to_create do
						local card = create_card("Joker", G.jokers, nil, 0, nil, nil, nil, "rif")
						card:add_to_deck()
						G.jokers:emplace(card)
						card:start_materialize()
						G.GAME.joker_buffer = 0
					end
					return true
				end,
			}))
		end
		if card.ability.name == "Vampire" then
			local enhanced = {}
			if context.scoring_hand and #context.scoring_hand > 0 then
				for k, v in ipairs(context.scoring_hand) do
					if v.config.center ~= G.P_CENTERS.c_base and not v.debuff and not v.vampired then
						enhanced[#enhanced + 1] = v
						v.vampired = true
						v:set_ability(G.P_CENTERS.c_base, nil, true)
					end
					v.vampired = nil
				end
			elseif G and G.hand and #G.hand.highlighted > 0 then
				for k, v in ipairs(G.hand.highlighted) do
					if v.config.center ~= G.P_CENTERS.c_base and not v.debuff and not v.vampired then
						enhanced[#enhanced + 1] = v
						v.vampired = true
						v:set_ability(G.P_CENTERS.c_base, nil, true)
					end
					v.vampired = nil
				end
			end
			card.ability.x_mult = card.ability.x_mult + (card.ability.extra * (#enhanced or 1))
			results = { jokers = { xmult = card.ability.x_mult, card = card } }
		end
		-- if card.ability.name == "Shortcut" then results = { jokers = { } } end
		if card.ability.name == "Hologram" then
			card.ability.x_mult = card.ability.x_mult + card.ability.extra
			results = { jokers = { xmult = card.ability.x_mult, card = card } }
		end
		if card.ability.name == "Vagabond" then
			G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
			G.E_MANAGER:add_event(Event({
				trigger = "after",
				delay = 0.4,
				func = function()
					local card = create_card("Tarot", G.consumeables, nil, nil, nil, nil, nil, "vag")
					card:add_to_deck()
					G.consumeables:emplace(card)
					G.GAME.consumeable_buffer = 0
					return true
				end,
			}))
		end
		if card.ability.name == "Baron" then
			results = { jokers = { xmult = card.ability.extra, card = card } }
		end
		if card.ability.name == "Cloud 9" then
			if card.ability.nine_tally then
				ease_dollars(card.ability.extra * card.ability.nine_tally)
			else
				ease_dollars(card.ability.extra)
			end
		end
		if card.ability.name == "Rocket" then
			card.ability.extra.dollars = card.ability.extra.dollars + card.ability.extra.increase
			ease_dollars(card.ability.extra.dollars)
		end
		if card.ability.name == "Obelisk" then -- Sobelisk
			card.ability.x_mult = card.ability.x_mult + card.ability.extra
			results = { jokers = { xmult = card.ability.x_mult, card = card } }
		end
		-- page 6
		if card.ability.name == "Midas Mask" then
			if context.scoring_hand then
				for k, v in ipairs(context.scoring_hand) do
					if v:is_face() then
						v:set_ability(G.P_CENTERS.m_gold, nil, true)
						G.E_MANAGER:add_event(Event({
							trigger = "after",
							delay = 0.4,
							func = function()
								v:juice_up()
								return true
							end,
						}))
					end
				end
			elseif G and G.hand and #G.hand.highlighted > 0 then
				for k, v in ipairs(G.hand.highlighted) do
					if v:is_face() then
						v:set_ability(G.P_CENTERS.m_gold, nil, true)
						G.E_MANAGER:add_event(Event({
							trigger = "after",
							delay = 0.4,
							func = function()
								v:juice_up()
								return true
							end,
						}))
					end
				end
			end
		end
		if card.ability.name == "Luchador" then
			if G.GAME.blind and ((not G.GAME.blind.disabled) and (G.GAME.blind:get_type() == "Boss")) then
				G.GAME.blind:disable()
			end
		end
		if card.ability.name == "Photograph" then
			results = { jokers = { xmult = card.ability.extra, card = card } }
		end
		if card.ability.name == "Gift Card" then
			for k, v in ipairs(G.jokers.cards) do
				if v.set_cost then
					v.ability.extra_value = (v.ability.extra_value or 0) + card.ability.extra
					v:set_cost()
				end
			end
			for k, v in ipairs(G.consumeables.cards) do
				if v.set_cost then
					v.ability.extra_value = (v.ability.extra_value or 0) + card.ability.extra
					v:set_cost()
				end
			end
		end
		if card.ability.name == "Turtle Bean" then
			G.hand:change_size(-card.ability.extra.h_size)
			card.ability.extra.h_size = card.ability.extra.h_size - card.ability.extra.h_mod
			G.hand:change_size(card.ability.extra.h_size)
		end
		if card.ability.name == "Erosion" then
			results = {
				jokers = { mult = card.ability.extra * (G.GAME.starting_deck_size - #G.playing_cards), card = card },
			}
		end
		if card.ability.name == "Reserved Parking" then
			ease_dollars(card.ability.extra.dollars)
		end
		if card.ability.name == "Mail-In Rebate" then
			ease_dollars(card.ability.extra)
		end
		-- if card.ability.name == "To the Moon" then results = { jokers = { } } end
		if card.ability.name == "Hallucination" then
			G.E_MANAGER:add_event(Event({
				trigger = "after",
				delay = 0.4,
				func = function()
					local card = create_card("Tarot", G.consumeables, nil, nil, nil, nil, nil, "hal")
					card:add_to_deck()
					G.consumeables:emplace(card)
					G.GAME.consumeable_buffer = 0
					return true
				end,
			}))
		end
		if card.ability.name == "Fortune Teller" then
			results = { jokers = { mult = G.GAME.consumeable_usage_total.tarot or 1, card = card } }
		end
		if card.ability.name == "Juggler" then
			G.hand:change_size(card.ability.h_size)
		end
		if card.ability.name == "Drunkard" then
			ease_discard(card.ability.d_size)
		end
		if card.ability.name == "Stone Joker" then
			results = { jokers = { chips = card.ability.extra * card.ability.stone_tally, card = card } }
		end
		if card.ability.name == "Golden Joker" then
			ease_dollars(card.ability.extra)
		end
		-- page 7
		if card.ability.name == "Lucky Cat" then
			card.ability.x_mult = card.ability.x_mult + card.ability.extra
			results = { jokers = { xmult = card.ability.x_mult, card = card } }
		end
		if card.ability.name == "Baseball Card" then
			results = { jokers = { xmult = card.ability.extra, card = card } }
		end
		if card.ability.name == "Bull" then
			results = {
				jokers = {
					chips = card.ability.extra * math.max(0, (G.GAME.dollars + (G.GAME.dollar_buffer or 0))),
					card = card,
				},
			}
		end
		if card.ability.name == "Diet Cola" then
			G.E_MANAGER:add_event(Event({
				func = function()
					add_tag(Tag("tag_double"))
					play_sound("generic1", 0.9 + math.random() * 0.1, 0.8)
					play_sound("holo1", 1.2 + math.random() * 0.1, 0.4)
					return true
				end,
			}))
		end
		if card.ability.name == "Trading Card" then
			ease_dollars(card.ability.extra)
		end
		if card.ability.name == "Flash Card" then
			card.ability.mult = card.ability.mult + card.ability.extra
			results = { jokers = { mult = card.ability.mult, card = card } }
		end
		if card.ability.name == "Popcorn" then
			card.ability.mult = card.ability.mult - card.ability.extra
			results = { jokers = { mult = card.ability.mult, card = card } }
		end
		if card.ability.name == "Spare Trousers" then
			card.ability.mult = card.ability.mult + card.ability.extra
			results = { jokers = { mult = card.ability.mult, card = card } }
		end
		if card.ability.name == "Ancient Joker" then
			results = { jokers = { xmult = card.ability.extra, card = card } }
		end
		if card.ability.name == "Ramen" then
			card.ability.x_mult = card.ability.x_mult - card.ability.extra
			results = { jokers = { xmult = card.ability.x_mult, card = card } }
		end
		if card.ability.name == "Walkie Talkie" then
			results = { jokers = { mult = card.ability.extra.mult, chips = card.ability.extra.chips, card = card } }
		end
		-- if card.ability.name == "Seltzer" then results = { jokers = { } } end
		if card.ability.name == "Castle" then
			card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
			results = { jokers = { chips = card.ability.extra.chips, card = card } }
		end
		if card.ability.name == "Smiley Face" then
			results = { jokers = { mult = card.ability.extra, card = card } }
		end
		if card.ability.name == "Campfire" then
			card.ability.x_mult = card.ability.x_mult + card.ability.extra
			results = { jokers = { xmult = card.ability.x_mult, card = card } }
		end
		-- page 8
		if card.ability.name == "Golden Ticket" then
			ease_dollars(card.ability.extra)
		end
		-- if card.ability.name == "Mr Bones" then results = { jokers = { } } end
		if card.ability.name == "Acrobat" then
			results = { jokers = { xmult = card.ability.extra, card = card } }
		end
		-- if card.ability.name == "Sock and Buskin" then results = { jokers = { } } end
		if card.ability.name == "Swashbuckler" then
			results = { jokers = { mult = card.ability.mult, card = card } }
		end
		if card.ability.name == "Troubadour" then
			G.hand:change_size(card.ability.extra.h_size)
			G.GAME.round_resets.hands = G.GAME.round_resets.hands + card.ability.extra.h_plays
		end
		if card.ability.name == "Certificate" then
			local _card = create_playing_card({
				front = pseudorandom_element(G.P_CARDS, pseudoseed("cert_fr")),
				center = G.P_CENTERS.c_base,
			}, G.discard, true, nil, { G.C.SECONDARY_SET.Enhanced }, true)
			_card:set_seal(SMODS.poll_seal({ guaranteed = true, type_key = "certsl" }))
			G.E_MANAGER:add_event(Event({
				func = function()
					G.hand:emplace(_card)
					_card:start_materialize()
					G.GAME.blind:debuff_card(_card)
					G.hand:sort()
					return true
				end,
			}))
		end
		-- if card.ability.name == "Smeared Joker" then results = { jokers = { } } end
		if card.ability.name == "Throwback" then
			results = { jokers = { xmult = card.ability.x_mult, card = card } }
		end
		-- if card.ability.name == "Hanging Chad" then results = { jokers = { } } end
		if card.ability.name == "Rough Gem" then
			ease_dollars(card.ability.extra)
		end
		if card.ability.name == "Bloodstone" then
			results = { jokers = { xmult = card.ability.extra.Xmult, card = card } }
		end
		if card.ability.name == "Arrowhead" then
			results = { jokers = { chips = card.ability.extra, card = card } }
		end
		if card.ability.name == "Onyx Agate" then
			results = { jokers = { mult = card.ability.extra, card = card } }
		end
		if card.ability.name == "Glass Joker" then
			card.ability.x_mult = card.ability.x_mult + card.ability.extra
			results = { jokers = { xmult = card.ability.x_mult, card = card } }
		end
		-- page 9
		-- if card.ability.name == "Showman" then results = { jokers = { } } end
		if card.ability.name == "Flower Pot" then
			results = { jokers = { xmult = card.ability.extra, card = card } }
		end
		if card.ability.name == "Blueprint" then
			for i, other_joker in ipairs(G.jokers.cards) do
				if other_joker == card and G.jokers.cards[i+1] then
                   local  results = Spectrallib.get_forcetrigger_results(G.jokers.cards[i+1], context)
					if results and results.jokers then
						results.jokers.card = card
						SMODS.calculate_effect(results.jokers)
					end
				end
			end
		end
		if card.ability.name == "Wee Joker" then
			card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
			results = { jokers = { chips = card.ability.extra.chips, card = card } }
		end
		if card.ability.name == "Merry Andy" then
			ease_discard(card.ability.d_size)
			G.hand:change_size(card.ability.h_size)
		end
		-- if card.ability.name == "Oops! All 6s" then results = { jokers = { } } end
		if card.ability.name == "The Idol" then
			results = { jokers = { xmult = card.ability.extra, card = card } }
		end
		if card.ability.name == "Seeing Double" then
			results = { jokers = { xmult = card.ability.extra, card = card } }
		end
		if card.ability.name == "Matador" then
			ease_dollars(card.ability.extra)
		end
		if card.ability.name == "Hit The Road" then
			card.ability.x_mult = card.ability.x_mult + card.ability.extra
			results = { jokers = { xmult = card.ability.x_mult, card = card } }
		end
		if card.ability.name == "The Duo" then
			results = { jokers = { xmult = card.ability.x_mult, card = card } }
		end
		if card.ability.name == "The Trio" then
			results = { jokers = { xmult = card.ability.x_mult, card = card } }
		end
		if card.ability.name == "The Family" then
			results = { jokers = { xmult = card.ability.x_mult, card = card } }
		end
		if card.ability.name == "The Order" then
			results = { jokers = { xmult = card.ability.x_mult, card = card } }
		end
		if card.ability.name == "The Tribe" then
			results = { jokers = { xmult = card.ability.x_mult, card = card } }
		end
		-- page 10
		if card.ability.name == "Stuntman" then
			G.hand:change_size(-card.ability.extra.h_size)
			results = { jokers = { chips = card.ability.extra.chip_mod, card = card } }
		end
		if card.ability.name == "Invisible Joker" then
			card.ability.invis_rounds = card.ability.invis_rounds + 1
			local jokers = {}
			for i = 1, #G.jokers.cards do
				if G.jokers.cards[i] ~= card then
					jokers[#jokers + 1] = G.jokers.cards[i]
				end
			end
			if #jokers > 0 then
				G.E_MANAGER:add_event(Event({
					func = function()
						local chosen_joker = pseudorandom_element(jokers, pseudoseed("invisible"))
						local card = copy_card(
							chosen_joker,
							nil,
							nil,
							nil,
							chosen_joker.edition and chosen_joker.edition.negative
						)
						if card.ability.invis_rounds then
							card.ability.invis_rounds = 0
						end
						card:add_to_deck()
						G.jokers:emplace(card)
						return true
					end,
				}))
			end
		end
		if card.ability.name == "Brainstorm" then
			local other_joker = G.jokers.cards[1]
			if other_joker then
				local results = Spectrallib.get_forcetrigger_results(G.jokers.cards[1], context)
				if results and results.jokers then
					results.jokers.card = card
					SMODS.calculate_effect(results.jokers)
				end
			end
		end
		if card.ability.name == "Satellite" then
			local planets_used = 0
			for k, v in pairs(G.GAME.consumeable_usage) do
				if v.set == "Planet" then
					planets_used = planets_used + 1
				end
			end
			ease_dollars(card.ability.extra * (planets_used or 1))
		end
		if card.ability.name == "Shoot The Moon" then
			results = { jokers = { mult = 13, card = card } }
		end
		if card.ability.name == "Driver's License" then
			results = { jokers = { xmult = card.ability.extra, card = card } }
		end
		if card.ability.name == "Cartomancer" then
			G.E_MANAGER:add_event(Event({
				func = function()
					local card = create_card("Tarot", G.consumeables, nil, nil, nil, nil, nil, "car")
					card:add_to_deck()
					G.consumeables:emplace(card)
					G.GAME.consumeable_buffer = 0
					return true
				end,
			}))
		end
		-- if card.ability.name == "Astronomer" then results = { jokers = { } } end
		if card.ability.name == "Burnt Joker" then
			if #G.hand.highlighted > 0 then
				local text, disp_text = G.FUNCS.get_poker_hand_info(G.hand.highlighted)
				update_hand_text({ sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 }, {
					handname = localize(text, "poker_hands"),
					chips = G.GAME.hands[text].chips,
					mult = G.GAME.hands[text].mult,
					level = G.GAME.hands[text].level,
				})
				level_up_hand(card, text, nil, 1)
				update_hand_text(
					{ sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
					{ mult = 0, chips = 0, handname = "", level = "" }
				)
			elseif context.scoring_name then
				level_up_hand(card, context.scoring_name)
			end
		end
		if card.ability.name == "Bootstraps" then
			results = {
				jokers = {
					mult = card.ability.mult
						* math.floor((G.GAME.dollars + (G.GAME.dollar_buffer or 0)) / card.ability.extra.dollars),
					card = card,
				},
			}
		end
		if card.ability.name == "Caino" then
			card.ability.caino_xmult = card.ability.caino_xmult + card.ability.extra
			results = { jokers = { xmult = card.ability.caino_xmult, card = card } }
		end
		if card.ability.name == "Triboulet" then
			results = { jokers = { xmult = card.ability.extra, card = card } }
		end
		if card.ability.name == "Yorick" then
			card.ability.x_mult = card.ability.x_mult + card.ability.extra.xmult
			results = { jokers = { xmult = card.ability.x_mult, card = card } }
		end
		if card.ability.name == "Chicot" then
			if G.GAME.blind and G.GAME.blind:get_type() == "Boss" then
				G.GAME.blind:disable()
			end
		end
		if card.ability.name == "Perkeo" then
			local eligibleJokers = {}
			for i = 1, #G.consumeables.cards do
				if G.consumeables.cards[i].ability.consumeable then
					eligibleJokers[#eligibleJokers + 1] = G.consumeables.cards[i]
				end
			end
			if #eligibleJokers > 0 then
				G.E_MANAGER:add_event(Event({
					func = function()
						local card = copy_card(pseudorandom_element(eligibleJokers, pseudoseed("perkeo")), nil)
						card:set_edition({ negative = true }, true)
						card:add_to_deck()
						G.consumeables:emplace(card)
						return true
					end,
				}))
			end
		end
		if card.ability.name == "Perkeo (Incantation)" then
			if G.consumeables.cards[1] then
				G.E_MANAGER:add_event(Event({
					func = function()
						local total, checked, center = 0, 0, nil
						for i = 1, #G.consumeables.cards do
							total = total + (G.consumeables.cards[i]:getQty())
						end
						local poll = pseudorandom(pseudoseed("perkeo")) * total
						for i = 1, #G.consumeables.cards do
							checked = checked + (G.consumeables.cards[i]:getQty())
							if checked >= poll then
								center = G.consumeables.cards[i]
								break
							end
						end
						local _card = copy_card(center, nil)
						_card:set_edition({ negative = true }, true)
						_card:add_to_deck()
						G.consumeables:emplace(_card)
						return true
					end,
				}))
			end
		end
	elseif card.ability.consumeable and Spectrallib.forcetriggerConsumableCheck(card) then
		G.cry_force_use = true
		if
			(card.ability.consumeable.max_highlighted or card.ability.name == "Aura")
			and not card.config.center.force_use
			--and not card.config.center.force_use
		then --Cards that require cards in hand to be selected
			local _cards = {}
			local targets = {}

			--Get all cards that we can target
			for k, v in ipairs(G.hand.cards) do
				if
					not ((card.ability.name == "Aura") and (v.edition or v.will_be_editioned))
					and not v.will_be_destroyed
				then
					_cards[#_cards + 1] = v
				end
			end

			local highlight_count = to_number(math.min(#_cards, card.ability.consumeable.max_highlighted or 1))

			if highlight_count > 0 then
				--Choose random targets for consumable
				for i = 1, highlight_count do
					local selected_card, card_key = pseudorandom_element(_cards, pseudoseed("forcehighlight"))
					if card.ability.name == "Aura" then
						selected_card.will_be_editioned = true
					end
					if card.ability.name == "The Hanged Man" then
						selected_card.will_be_destroyed = true
					end
					targets[#targets + 1] = table.remove(_cards, card_key)

					--Dodgy way of doing this
					--Basically we need to highlight the cards temporarily to ensure events are created correctly
					G.hand:add_to_highlighted(selected_card, true)
				end

				G.E_MANAGER:add_event(Event({
					func = function()
						for _, v in ipairs(targets) do
							G.hand:add_to_highlighted(v, true)
							v.will_be_editioned = nil
							v.will_be_destroyed = nil
							play_sound("card1", 1)
						end
						return true
					end,
				}))

				card:use_consumeable()

				G.E_MANAGER:add_event(Event({
					func = function()
						G.hand:unhighlight_all()
						return true
					end,
				}))

				--Unhighlight once events are created
				G.hand:unhighlight_all()
			end
		else
			-- Copy rigged code to guarantee WoF and Planet.lua

			local ggpn = G.GAME.probabilities.normal
			G.GAME.probabilities.normal = 1e9
			if not card.config.center.force_use then
				card:use_consumeable()
			else
				card.config.center:force_use(card, card.area)
			end

			G.GAME.probabilities.normal = ggpn
		end
		G.cry_force_use = nil
	end
	return results
end

---Forcetriggers a given card and calculates returned effects.
---Provided `card` is the card to forcetrigger, `message_card` will display the forcetrigger message.
---`message` and `colour` control the message displayed on `message_card`.
---`silent` prevents the message from being displayed.
---`context` holds additional context information and defaults to an empty table. `context.forcetrigger` will always be set to `true` when calculating the forcetrigger.
---@param args table|{context?: table, card: Card, silent?: boolean, message_card: Card, colour?: table, message?: string}
function Spectrallib.forcetrigger(args)
	args.context = args.context or {}
	if Cryptid.demicolonGetTriggerable(args.card)[1] then
		if not Spectrallib.should_skip_animations() and not args.silent then
			G.E_MANAGER:add_event(Event({
				trigger = "before",
				func = function()
				play_sound("slib_forcetrigger", 1, 0.6)
				return true
				end,
			}))
		end
		if not args.silent then
			SMODS.calculate_effect{card = args.context.blueprint_card or args.message_card, colour = args.context.blueprint_card and G.C.BLUE or args.colour or G.C.PURPLE, message = args.message or localize("slib_forcetrigger_ex")}
		end
		local results = Spectrallib.get_forcetrigger_results(args.card, args.context)
		if results and results.jokers then
			results.jokers.card = args.card
			SMODS.calculate_effect(results.jokers)
		end
	end
end

function Spectrallib.forcetriggerVanillaCheck(card)
	if not card then
		return false
	end
	local compatvanilla = {
		"Joker",
		"Greedy Joker",
		"Lusty Joker",
		"Wrathful Joker",
		"Gluttonous Joker",
		"Jolly Joker",
		"Zany Joker",
		"Mad Joker",
		"Crazy Joker",
		"Droll Joker",
		"Sly Joker",
		"Wily Joker",
		"Clever Joker",
		"Devious Joker",
		"Crafty Joker",
		"Half Joker",
		"Joker Stencil",
		-- "Four Fingers",
		-- "Mime",
		-- "Credit Card",
		"Ceremonial Dagger",
		"Banner",
		"Mystic Summit",
		"Marble Joker",
		"Loyalty Card",
		"8 Ball",
		"Misprint",
		-- "Dusk",
		"Raised Fist",
		-- "Chaos the Clown",
		"Fibonacci",
		"Steel Joker",
		"Scary Face",
		"Abstract Joker",
		"Delayed Gratification",
		-- "Hack",
		-- "Pareidolia",
		"Gros Michel",
		"Even Steven",
		"Odd Todd",
		"Scholar",
		"Business Card",
		"Supernova",
		"Ride the Bus",
		"Space Joker",
		"Egg",
		"Burglar",
		"Blackboard",
		"Runner",
		"Ice Cream",
		"DNA",
		-- "Splash",
		"Blue Joker",
		"Sixth Sense",
		"Constellation",
		"Hiker",
		"Faceless Joker",
		"Green Joker",
		"Superposition",
		"To Do List",
		"Cavendish",
		"Card Sharp",
		"Red Card",
		"Madness",
		"Square Joker",
		"Seance",
		"Riff-Raff",
		"Vampire",
		-- "Shortcut",
		"Hologram",
		"Vagabond",
		"Baron",
		"Cloud 9",
		"Rocket",
		"Obelisk",
		"Midas Mask",
		"Luchador",
		"Photograph",
		"Gift Card",
		"Turtle Bean",
		"Erosion",
		"Reserved Parking",
		"Mail-In Rebate",
		-- "To the Moon",
		"Hallucination",
		"Fortune Teller",
		"Juggler",
		"Drunkard",
		"Stone Joker",
		"Golden Joker",
		"Lucky Cat",
		"Baseball Card",
		"Bull",
		"Diet Cola",
		"Trading Card",
		"Flash Card",
		"Popcorn",
		"Spare Trousers",
		"Ancient Joker",
		"Ramen",
		"Walkie Talkie",
		-- "Seltzer",
		"Castle",
		"Smiley Face",
		"Campfire",
		"Golden Ticket",
		-- "Mr. Bones",
		"Acrobat",
		-- "Sock and Buskin",
		"Swashbuckler",
		"Troubadour",
		"Certificate",
		-- "Smeared Joker",
		"Throwback",
		-- "Hanging Chad",
		"Rough Gem",
		"Bloodstone",
		"Arrowhead",
		"Onyx Agate",
		"Glass Joker",
		-- "Showman",
		"Flower Pot",
		"Blueprint",
		"Wee Joker",
		"Merry Andy",
		-- "Oops! All 6s",
		"The Idol",
		"Seeing Double",
		"Matador",
		"Hit the Road",
		"The Duo",
		"The Trio",
		"The Family",
		"The Order",
		"The Tribe",
		"Stuntman",
		"Invisible Joker",
		"Brainstorm",
		"Satellite",
		"Shoot the Moon",
		"Driver's License",
		"Cartomancer",
		-- "Astronomer",
		"Burnt Joker",
		"Bootstraps",
		"Caino",
		"Triboulet",
		"Yorick",
		"Chicot",
		"Perkeo",
		"Perkeo (Incantation)",
	}
	for i = 1, #compatvanilla do
		if card.ability.name == compatvanilla[i] then
			return true
		end
	end
	return false
end

function Spectrallib.forcetriggerConsumableCheck(card)
	if not card then
		return false
	end
	return card.config.center.demicoloncompat or not card.config.center.original_mod or card.config.center.forcetrigger_compat
end

SMODS.Sound({
	key = "forcetrigger",
	path = "forcetrigger.ogg",
})
SMODS.Sound({
	key = "demitrigger",
	path = "demitrigger.ogg",
})
