local catalog = require("policy.catalog")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local monster_stats = require("policy.combat.monster_stats")
local roll = require("policy.combat.roll")
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

-- Heal the actor's saved HP and report only an actual increase.
local function apply(ctx, caster, amount)
    local health = ctx:get(caster, component.HEALTH)

    if not health then
        error("monster healing target has no health")
    end

    local previous = health.current

    health.current = math.min(health.max, health.current + amount)
    ctx:set(caster, component.HEALTH, health)

    if health.current > previous then
        ctx:emit("spell", "The " .. display.name(ctx, caster) ..
            " is healed.")
    end

    return health.current - previous
end

-- mon-cast.cc gives Minor Healing a two-die beam, then beam.cc adds three.
function healing.minor(ctx, caster)
    local sides = math.floor(spell_hd(ctx, caster) / 2)
    local dice = 0

    for _ = 1, 2 do
        if sides > 0 then
            dice = dice + 1 + roll.spell(ctx, sides)
        end
    end

    return apply(ctx, caster, 3 + dice)
end

-- Major Healing's average roll uses the source monster spell stream.
function healing.major(ctx, caster)
    local bound = spell_hd(ctx, caster) * 10
    local amount = 50 + roll.average_two(ctx, "monster_spell", bound)

    return apply(ctx, caster, amount)
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

    return apply(ctx, caster, amount)
end

return healing
