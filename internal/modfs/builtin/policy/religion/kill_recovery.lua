-- Theory of operation: divine kill recovery reads the live worshipper and
-- victim after kill conduct, so the same death's piety gain can open the
-- first-star chance gate. HP/MP amounts use the victim's original HD;
-- no persistent recovery flag or catalog name dispatch is needed.
local channels = require("constants.message_channels")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local limits = require("constants.piety")
local roll = require("policy.religion.kill_recovery.roll")
local statuses = require("policy.magic.effects.statuses.player")
local traits = require("policy.religion.conduct.monster_traits")

local recovery = {}

-- Run only for a credited XP-giving non-object death. Source eligibility
-- and the piety gate precede god amounts, while Death's Door only gates
-- the final HP write. This reaction is called before the victim vanishes.
function recovery.on_kill(ctx, player, victim, definition, xp,
    health_message_emitted)
    if xp <= 0 or traits.object(definition) then
        return
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if not worship or worship.god_id == gods.NO_GOD or
        ((worship.penance or {})[worship.god_id] or 0) > 0 or
        worship.piety <= 0 then
        return
    end

    if roll.random(ctx, worship.piety) < limits.BREAKPOINTS[1] then
        return
    end

    local god = catalog.get(categories.GODS, worship.god_id)

    if not god.kill_recovery_module then
        return
    end

    local god_recovery = require(god.kill_recovery_module)
    local hp, mp = god_recovery.amounts(ctx, victim, definition)

    if hp == 0 and mp == 0 then
        return
    end

    local health = ctx:get(player, component.HEALTH)
    local magic = ctx:get(player, component.MAGIC)

    if hp > 0 and health.current < health.max and
        not statuses.death_door_active(ctx, player) then
        health.current = math.min(health.max, health.current + hp)
        ctx:set(player, component.HEALTH, health)
        if not health_message_emitted then
            ctx:emit(channels.HEALTH, "You feel better.")
        end
    end

    if mp > 0 and magic.current < magic.max then
        magic.current = math.min(magic.max, magic.current + mp)
        ctx:set(player, component.MAGIC, magic)
        ctx:emit(channels.MAGIC, "You feel your power returning.")
    end
end

return recovery
