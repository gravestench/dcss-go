local component = require("constants.component")
local confusion = require("policy.magic.player_confusion")
local health_rules = require("policy.combat.player_health")
local potion_rules = require("policy.character.potion_rules")

local ambrosia = {}

function ambrosia.active(ctx, player)
    local state = ctx:get(player, component.POTION_AMBROSIA)

    return state ~= nil and state.remaining_aut > 0
end

function ambrosia.extend(ctx, player, turns)
    local state = ctx:get(player, component.POTION_AMBROSIA)
    local added = turns * 10

    if state then
        state.remaining_aut = state.remaining_aut + added
        ctx:set(player, component.POTION_AMBROSIA, state)
    else
        ctx:add(player, component.POTION_AMBROSIA, {
            remaining_aut = added,
        })
    end
end

local function rounded_gain(ctx, aut)
    local numerator = aut * (3 + ctx:random("potion", 3))
    local whole = math.floor(numerator / 10)
    local remainder = numerator % 10

    if remainder > 0 and ctx:random("potion", 10) < remainder then
        return whole + 1
    end

    return whole
end

-- Source: player.cc:dec_ambrosia_player. The final action still restores
-- resources even when confusion or the duration ends on that action.
function ambrosia.tick(ctx, player, aut)
    local state = ctx:get(player, component.POTION_AMBROSIA)

    if not state or aut <= 0 then
        return
    end

    if not confusion.active(ctx, player) then
        state.remaining_aut = 0
    end

    state.remaining_aut = math.max(0, state.remaining_aut - aut)

    local hp_gain = rounded_gain(ctx, aut)
    local mp_gain = rounded_gain(ctx, aut)
    local health = ctx:get(player, component.HEALTH)
    local magic = ctx:get(player, component.MAGIC)

    if not health or not magic then
        error("ambrosia requires player health and magic")
    end

    if health_rules.can_heal(ctx, player) then
        health.current = math.min(health.max,
            health.current + potion_rules.scale_healing(ctx, player,
                hp_gain))
    end

    magic.current = math.min(magic.max, magic.current + mp_gain)

    ctx:set(player, component.HEALTH, health)
    ctx:set(player, component.MAGIC, magic)

    if state.remaining_aut == 0 then
        ctx:remove(player, component.POTION_AMBROSIA)
        ctx:emit("duration", "You feel less invigorated.")
    else
        ctx:set(player, component.POTION_AMBROSIA, state)
    end
end

return ambrosia
