-- Theory of operation: each god definition may name one gift rule. Piety
-- asks this owner after saving an accepted candidate point, and the rule
-- then reads the same live ECS state as memorisation and the spell menu.
-- The shared owner enforces penance and gift timeout; it never chooses a
-- spell for a god or contains a switch over bundled patrons.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")

local gifts = {}

-- Resolve the effective mod definition so replacing one god's gift module
-- requires only its own content file. Nil is a legitimate no-gift god.
local function handler(god_id)
    local definition = catalog.get(categories.GODS, god_id)

    if not definition.gift_module then
        return nil
    end

    return require(definition.gift_module)
end

-- Example: Kiku may grant a library set on the candidate that reaches one
-- star, while Trog currently has no spell gift module and does nothing.
function gifts.check(ctx, player)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state or state.god_id == gods.NO_GOD or
        (state.penance[state.god_id] or 0) > 0 or
        state.gift_timeout > 0 then
        return false
    end

    local rule = handler(state.god_id)

    if not rule or not rule.check then
        return false
    end

    return rule.check(ctx, player, state)
end

-- Both permanent library gifts and temporary offers update the source
-- counters. A cooldown slows later piety candidates, never deducts piety.
function gifts.record(ctx, player, timeout)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state or state.god_id == gods.NO_GOD then
        error("a gift requires current worship")
    end

    if type(timeout) ~= "number" or timeout % 1 ~= 0 or timeout < 0 then
        error("gift timeout must be a nonnegative integer")
    end

    local god_id = state.god_id

    state.gift_current[god_id] = (state.gift_current[god_id] or 0) + 1
    state.gift_total[god_id] = (state.gift_total[god_id] or 0) + 1
    state.gift_timeout = state.gift_timeout + timeout
    ctx:set(player, component.RELIGION_WORSHIP, state)

    return state.gift_total[god_id]
end

-- Only the current patron can offer temporary access. A stale Vehumet
-- component left after renunciation cannot make a spell learnable.
function gifts.offering(ctx, player, spell_id)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state or state.god_id == gods.NO_GOD then
        return false
    end

    local rule = handler(state.god_id)

    return rule and rule.offering and
        rule.offering(ctx, player, spell_id) or false
end

-- Memorisation completion may consume a temporary offer. Permanent book
-- knowledge is still owned by the spell record and needs no gift callback.
function gifts.accept(ctx, player, spell_id)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state or state.god_id == gods.NO_GOD then
        return false
    end

    local rule = handler(state.god_id)

    return rule and rule.accept and
        rule.accept(ctx, player, spell_id) or false
end

-- Source excommunication clears current gifts. God-specific offer cleanup
-- runs after the worship owner has recorded departure and wrath debt.
function gifts.leave(ctx, player, old_god)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    state.gift_current[old_god] = 0
    ctx:set(player, component.RELIGION_WORSHIP, state)

    local rule = handler(old_god)

    if rule and rule.leave then
        rule.leave(ctx, player)
    end
end

return gifts
