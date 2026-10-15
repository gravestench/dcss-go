local spells = require("ids.spells")
local component = require("constants.component")
local catalog = require("policy.catalog")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")

local spell_id = spells.SPELL_PHANTOM_MIRROR
local uncloneable = {
    MONS_ELDRITCH_TENTACLE = true,
    MONS_ELDRITCH_TENTACLE_SEGMENT = true,
    MONS_PLAYER_ILLUSION = true,
}

local function target_at(ctx, player, dx, dy)
    local position = ctx:get(player, component.POSITION)
    local x, y = position.x + dx, position.y + dy
    local target = ctx:actor_at(position.level_id, x, y)

    if not target or target == player then
        return nil
    end

    local target_position = ctx:get(target, component.POSITION)
    local health = ctx:get(target, component.HEALTH)
    local actor = ctx:get(target, component.ACTOR)

    if not target_position or not health or health.current <= 0 or
        not actor or uncloneable[actor.kind_id] or
        ctx:has(target, component.SUMMON_CONSTRUCT) or
        math.max(math.abs(dx), math.abs(dy)) > 7 or
        not ctx:visible(position.level_id, position.x, position.y,
            7, x, y) then
        return nil
    end

    return target
end

local function evocations(ctx, player)
    local skills = ctx:get(player, "core.skills")

    for _, skill in ipairs(skills and skills.entries or {}) do
        if skill.id == "SK_EVOCATIONS" then
            return skill.level
        end
    end

    return 0
end

-- Source: evoke.cc:_phantom_mirror. The clone is a full allied actor with
-- the original monster's kind, current HP, and an abjuration duration.
local spell_effects = {}

function spell_effects.prepare(ctx, player, _, dx, dy)
    if not target_at(ctx, player, dx, dy) then
        return "You can't see anything there to clone."
    end
end

function spell_effects.resolve(ctx, player, intent, _, power)
    local target = target_at(ctx, player, intent.dx, intent.dy)

    if not target then
        return
    end

    local actor = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)
    local position = ctx:get(target, component.POSITION)
    local definition = catalog.get("monsters", actor.kind_id)
    local evo = evocations(ctx, player)
    local willpower = definition.willpower or 0
    local resistance = math.floor(100 * willpower /
        math.max(1, willpower + 5 + 3 * evo + power))
    local duration = math.min(6, math.max(1,
        math.floor((math.floor(evo / 4) + 1) * (100 - resistance) / 100)))
    local clone = summons.spawn(ctx, player, spell_id, actor.kind_id,
        duration, 1, {
            anchor = position,
            hp = health.current,
            hd = math.max(1, definition.hd -
                summons.divide(ctx, definition.hd, 3)),
        })

    if clone then
        ctx:emit("spell", "You reflect the monster with the mirror!")
    end
end

registry.add(spell_id, {
    prepare = spell_effects.prepare,

    resolve = spell_effects.resolve,
})

return spell_effects
