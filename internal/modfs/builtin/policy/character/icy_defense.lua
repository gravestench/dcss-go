local component = require("constants.component")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local resistances = require("constants.resistance_ids")

local icy_defense = {}

local DEPLETION_AUT = 300

function icy_defense.active(ctx, player)
    local state = ctx:get(player, component.ICY_DEFENSE)

    return not state or state.remaining_aut == 0
end

-- Source: ouch.cc:maybe_melt_player_enchantments. The source's melt hook
-- checks Condensation Shield, even when Icemail also protects the player.
function icy_defense.melt(ctx, player, resistance_id)
    if resistance_id ~= resistances.FIRE and
        resistance_id ~= resistances.STEAM then
        return
    end

    if mutation_levels.effective(ctx, player,
        mutations.MUT_CONDENSATION_SHIELD) == 0 then
        return
    end

    local state = ctx:get(player, component.ICY_DEFENSE)
    local was_active = not state or state.remaining_aut == 0

    if was_active then
        if mutation_levels.effective(ctx, player,
            mutations.MUT_ICEMAIL) > 0 then
            ctx:emit("duration", "Your icy defenses dissipate!")
        else
            ctx:emit("duration", "Your condensation shield dissipates!")
        end
    end

    if state then
        state.remaining_aut = DEPLETION_AUT
        ctx:set(player, component.ICY_DEFENSE, state)
    else
        ctx:add(player, component.ICY_DEFENSE, {
            remaining_aut = DEPLETION_AUT,
        })
    end
end

function icy_defense.tick(ctx, player, aut)
    if aut <= 0 then
        return
    end

    local state = ctx:get(player, component.ICY_DEFENSE)

    if not state or state.remaining_aut == 0 then
        return
    end

    state.remaining_aut = math.max(0, state.remaining_aut - aut)
    ctx:set(player, component.ICY_DEFENSE, state)

    if state.remaining_aut == 0 then
        ctx:emit("duration", "Your icy envelope is restored.")
    end
end

return icy_defense
