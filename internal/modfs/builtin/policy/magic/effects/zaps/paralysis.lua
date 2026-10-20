local component = require("constants.component")
local spells = require("ids.spells")
local catalog = require("policy.catalog")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")
local will = require("policy.magic.effects.zaps.will")
local senses = require("policy.character.senses")
local vault_enchantments = require("policy.monsters.vault_enchantments")
local enchantments = require("constants.vault_monster_enchantments")

local paralysis = {}

-- Check stationary and other catalog flags without assuming a flag list exists.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Convert enchant power through source stepdown before storing a paralysis duration.
local function duration(power)
    -- beam.cc:_ench_pow_to_dur: stepdown(power * BASELINE_DELAY, 70).
    local scaled = 70 * math.log(1 + power * 10 / 70) / math.log(2)
    return math.floor(scaled + 0.5)
end

-- Example: can_target(ctx, player, spell) skips prompting when no living actor
-- is visible in spell range along a clear projectile path.
-- Scan live visible actors along clear paths before the spell asks for a target.
function paralysis.can_target(ctx, player, spell)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)

    for _, target in ipairs(ctx:query({
        component.ACTOR, component.POSITION, component.HEALTH,
    })) do
        if target ~= player then
            local position = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if health.current > 0 and position.level_id == origin.level_id and
                distance <= reach and
                ctx:visible(origin.level_id, origin.x, origin.y, reach,
                    position.x, position.y) and
                ctx:projectile_clear(origin.level_id, origin.x, origin.y,
                    position.x, position.y) then
                return true
            end
        end
    end

    return false
end

-- Remove the paralysis component at zero; speed consumers then see the unmodified actor.
function paralysis.tick(ctx, target)
    local state = ctx:get(target, component.PARALYSIS)

    if not state or
        vault_enchantments.active(ctx, target, enchantments.PARALYSIS) or
        vault_enchantments.active(ctx, target, enchantments.DUMB) then
        return
    end

    state.remaining_aut = state.remaining_aut - 10

    if state.remaining_aut <= 0 then
        ctx:remove(target, component.PARALYSIS)
        return
    end

    ctx:set(target, component.PARALYSIS, state)
end

-- Trace first contact, test willpower, and persist paralysis only for a susceptible target.
function paralysis.resolve(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.trace(ctx, origin.level_id, origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))
    local contact = ray.contacts[1]

    if not contact then
        ctx:emit("spell", "The paralysis beam dissipates.")
        return
    end

    local target = contact.actor
    local actor = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)

    if not actor or not health then
        error("Paralysis struck an actor without health")
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if health.current <= 0 or has_flag(definition, "M_STASIS") or
        ctx:has(target, component.PARALYSIS) then
        ctx:emit("spell", "The " .. definition.name .. " is unaffected.")
        return
    end

    -- zap-data.h:_mon_hex_zap gives player paralysis raw capped power.
    local enchant_power = math.min(power, 100)

    if will.resists(ctx, definition, enchant_power, target) then
        ctx:emit("spell", "The " .. definition.name .. " resists paralysis.")
        return
    end

    paralysis.apply_unresisted(ctx, target, definition, enchant_power)
end

-- The shared apply path handles monsters that reach the effect without a
-- willpower check, extending a saved paralysis duration if needed.
function paralysis.apply_unresisted(ctx, target, definition, enchant_power)
    local existing = ctx:get(target, component.PARALYSIS)
    local remaining = math.max(existing and existing.remaining_aut or 0,
        duration(enchant_power))
    local status = {
        remaining_aut = remaining,
    }

    if existing then
        ctx:set(target, component.PARALYSIS, status)
    else
        ctx:add(target, component.PARALYSIS, status)
    end

    if senses.player_sees_actor(ctx, target) then
        ctx:emit("spell", "The " .. definition.name ..
            " suddenly stops moving!")
    end
end

-- Tick only AI actors so player paralysis remains on its separate status clock.
function paralysis.update(ctx, entity)
    if ctx:has(entity, component.AI) then
        paralysis.tick(ctx, entity)
    end
end

registry.add(spells.SPELL_PARALYSE, paralysis)

-- The scheduler decrements saved paralysis at the monster update boundary.
-- Theory of operation: Paralysis timers decay before monster decision.
-- An actor may act when its saved timer reaches zero.
register.system({
    id = "zap.paralysis.tick",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = paralysis.update,
})

return paralysis
