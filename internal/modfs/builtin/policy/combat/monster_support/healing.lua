local catalog = require("policy.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local monster_stats = require("policy.combat.monster_stats")
local roll = require("policy.combat.roll")
local senses = require("policy.character.senses")
local terrain = require("constants.terrain")
local monsters = require("ids.monsters")

local healing = {}

local tree_features = {
    [terrain.DNGN_TREE] = true,
    [terrain.DNGN_MANGROVE] = true,
    [terrain.DNGN_PETRIFIED_TREE] = true,
    [terrain.DNGN_DEMONIC_TREE] = true,
}

-- Source AI rates healing as worthwhile at or below half maximum HP.
function healing.wounded(ctx, caster)
    local health = ctx:get(caster, component.HEALTH)

    return health ~= nil and health.current > 0 and
        health.current <= math.floor(health.max / 2)
end

-- The source spell_hd starts with effective monster HD. The later Aura of
-- Brilliance projection can extend this one owner without changing spells.
local function spell_hd(ctx, caster)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    return monster_stats.spell_hit_dice(ctx, caster, definition)
end

-- All monster healing writes the recipient's existing health component.
-- Keep the HP calculation separate from spell-specific visible messages.
local function apply(ctx, target, amount)
    local health = ctx:get(target, component.HEALTH)

    if not health then
        error("monster healing target has no health")
    end

    local previous = health.current

    health.current = math.min(health.max, health.current + amount)
    ctx:set(target, component.HEALTH, health)

    return health.current - previous
end

-- Self-healing spells share their source message while the allied beam has
-- separate full-recovery and partial-recovery wording.
local function report_self(ctx, caster, gained)
    if gained > 0 and senses.player_sees_actor(ctx, caster) then
        ctx:emit(channels.SPELL, "The " .. display.name(ctx, caster) ..
            " is healed.")
    end
end

-- mon-cast.cc uses the caster's Minor Healing spell HD for either recipient.
-- The two source dice consume only the named monster spell stream.
local function minor_amount(ctx, caster)
    local sides = math.floor(spell_hd(ctx, caster) / 2)
    local dice = 0

    for _ = 1, 2 do
        if sides > 0 then
            dice = dice + 1 + roll.spell(ctx, sides)
        end
    end

    return 3 + dice
end

-- Self healing keeps its established message and recipient identity.
function healing.minor(ctx, caster)
    local gained = apply(ctx, caster, minor_amount(ctx, caster))

    report_self(ctx, caster, gained)

    return gained
end

-- Heal Other works for any missing HP; beam.cc distinguishes a complete
-- recovery from partial healing in its message to the player.
function healing.other(ctx, caster, target)
    local gained = apply(ctx, target, minor_amount(ctx, caster))

    if gained > 0 and senses.player_sees_actor(ctx, target) then
        local health = ctx:get(target, component.HEALTH)
        local suffix = " is healed somewhat."

        if health.current == health.max then
            suffix = "'s wounds heal themselves!"
        end

        ctx:emit(channels.SPELL, "The " .. display.name(ctx, target) ..
            suffix)
    end

    return gained
end

-- Major Healing's average roll uses the source monster spell stream.
function healing.major(ctx, caster)
    local bound = spell_hd(ctx, caster) * 10
    local amount = 50 + roll.average_two(ctx, "monster_spell", bound)
    local gained = apply(ctx, caster, amount)

    report_self(ctx, caster, gained)

    return gained
end

-- A tree feature or nearby Shambling Mangrove can anchor Woodweal.
-- The spell draws strength from that adjacency without consuming terrain.
function healing.near_wood(ctx, caster)
    local position = ctx:get(caster, component.POSITION)

    if not position then
        return false
    end

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = position.x + dx
                local y = position.y + dy

                if tree_features[ctx:cell(position.level_id, x, y)] then
                    return true
                end

                local neighbor = ctx:actor_at(position.level_id, x, y)
                local actor = neighbor and ctx:get(neighbor, component.ACTOR)

                if actor then
                    local definition = catalog.get("monsters", actor.kind_id)

                    if definition.genus_id ==
                        monsters.MONS_SHAMBLING_MANGROVE then
                        return true
                    end
                end
            end
        end
    end

    return false
end

-- Woodweal's 35-point base plus HD roll occurs only after a valid cast.
function healing.woodweal(ctx, caster)
    local amount = 35 + roll.spell(ctx, spell_hd(ctx, caster) * 3)
    local gained = apply(ctx, caster, amount)

    report_self(ctx, caster, gained)

    return gained
end

return healing
