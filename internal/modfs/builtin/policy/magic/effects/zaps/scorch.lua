local component = require("constants.component")
local spells = require("ids.spells")
local defense = require("policy.combat.monster_defense")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local targets = require("policy.ai.targets")
local player_contact = require("policy.combat.player_contact")

local scorch = {}

-- Read monster flags safely while excluding source-ineligible Scorch targets.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Scorch only chooses visible, threatening, non-conjured enemies in spell range.
local function candidates(ctx, player, spell)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)
    local result = {}

    for _, target in ipairs(ctx:query({
        component.ACTOR, component.HEALTH, component.POSITION,
    })) do
        if targets.enemy(ctx, player, target) then
            local position = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)
            local actor = ctx:get(target, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)

            if position.level_id == origin.level_id and health.current > 0 and
                math.max(math.abs(position.x - origin.x),
                    math.abs(position.y - origin.y)) <= reach and
                not has_flag(definition, "M_NO_THREAT") and
                not has_flag(definition, "M_CONJURED") and
                ctx:visible(origin.level_id, origin.x, origin.y, reach,
                    position.x, position.y) then
                result[#result + 1] = {
                    entity = target,
                    definition = definition,
                }
            end
        end
    end

    return result
end

-- Round fractional Scorch duration on the spell stream.
local function random_round(ctx, numerator, denominator)
    local value = math.floor(numerator / denominator)

    if ctx:random("spell", denominator) < numerator % denominator then
        value = value + 1
    end

    return value
end

-- Choose among eligible enemies with spell RNG before damage and fire-vulnerability rolls.
function scorch.resolve(ctx, player, _, spell, power)
    local found = candidates(ctx, player, spell)

    if #found == 0 then
        ctx:emit("spell", "Nothing happens.")
        return
    end

    local selected = found[1 + ctx:random("spell", #found)]
    local target = selected.entity
    local definition = selected.definition
    player_contact.report(ctx, target, definition)
    local max_damage = 10 + random_round(ctx, power, 5)
    local sides = random_round(ctx, max_damage, 2)
    local raw = 2 + ctx:random("spell", sides) +
        ctx:random("spell", sides)
    local ac = defense.armour(ctx, target, definition)
    local after_ac = math.max(0, raw - ctx:random("spell", ac + 1))
    local amount = damage.monster_elemental(ctx, target,
        after_ac, "MR_RES_FIRE")

    damage.apply(ctx, target, amount)
    ctx:emit("spell", "Flames lash the " .. definition.name .. ".")

    local health = ctx:get(target, component.HEALTH)

    if not health or health.current <= 0 or amount <= 0 then
        return
    end

    local added = (3 + random_round(ctx, amount, 3)) * 10
    local state = ctx:get(target, component.FIRE_VULNERABILITY)

    if state then
        state.remaining_aut = state.remaining_aut + added
        ctx:set(target, component.FIRE_VULNERABILITY, state)
    else
        ctx:add(target, component.FIRE_VULNERABILITY, {
            remaining_aut = added,
        })
    end

    ctx:emit("spell", "The " .. definition.name ..
        "'s fire resistance burns away.")
end

-- Example: Scorch ages a saved fire-vulnerability status before the monster’s next decision.
-- The fire-vulnerability component loses elapsed duration on later turns.
function scorch.tick(ctx, entity)
    local state = ctx:get(entity, component.FIRE_VULNERABILITY)

    if not state then
        return
    end

    state.remaining_aut = state.remaining_aut - 10

    if state.remaining_aut <= 0 then
        ctx:remove(entity, component.FIRE_VULNERABILITY)
    else
        ctx:set(entity, component.FIRE_VULNERABILITY, state)
    end
end

registry.add(spells.SPELL_SCORCH, scorch)

-- Theory of operation: Fire vulnerability loses one monster turn before the actor chooses its next action.
register.system({
    id = "zap.fire_vulnerability.tick",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = scorch.tick,
})

return scorch
