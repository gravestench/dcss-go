-- Yredelemnul's wrath chooses a Dungeon zombie base from committed
-- population rows at a depth derived from the player's experience level.
-- This owner reads the effective mod catalog; it never imports C++ data
-- during a game or stores a parallel roster of monster names.
local branches = require("ids.branches")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local habitat = require("policy.combat.monster_habitat")
local holiness = require("constants.monster_holiness")
local pool = require("policy.population.pool")
local sentinels = require("constants.population_sentinels")
local streams = require("constants.rng_streams")

local zombie_base = {}
local MAX_DUNGEON_DEPTH = 27
local BASELINE_SPEED = 10
local ZOMBIE_SPEED_LOSS = 2
local MAX_PICK_ATTEMPTS = 256

-- The source veto asks for natural, real, generated corpse monsters that
-- can inhabit the player's terrain. A zombie loses two speed; its final
-- speed must still reach the player's baseline speed of ten.
local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Return the catalog eligibility independently of row order or file path.
-- Skeleton exclusion happens after a base draw, matching the source's
-- redraw loop when a chosen corpse cannot leave bones.
local function eligible(ctx, player, definition, species)
    local position = ctx:get(player, component.POSITION)

    return contains(species.holiness, holiness.NATURAL) and
        species.leaves_corpse and
        species.speed - ZOMBIE_SPEED_LOSS >= BASELINE_SPEED and
        not contains(species.flags, flags.NO_ZOMBIE) and
        not contains(definition.flags, flags.NO_GEN_DERIVED) and
        not contains(definition.flags, flags.UNFINISHED) and
        not contains(definition.flags, flags.UNIQUE) and
        habitat.kind_at(ctx, species.id,
            position.level_id, position.x, position.y)
end

-- Source div_rand_round supplies one extra depth with probability equal
-- to the remainder. The Dungeon zombie pool caps at D:27 afterward.
function zombie_base.depth(ctx, level)
    local source_depth = math.min(MAX_DUNGEON_DEPTH, level + 5)
    local bonus = math.floor(source_depth / 5)
    local remainder = source_depth % 5

    if remainder > 0 and
        ctx:random(streams.CARDS, 5) < remainder then
        bonus = bonus + 1
    end

    return math.min(MAX_DUNGEON_DEPTH,
        source_depth + 1 + bonus)
end

-- Keep duplicate population rows and their source rarity weights. A
-- selected sentinel or vetoed base causes another draw rather than
-- silently converting it into a different monster.
function zombie_base.pick(ctx, player, level, skeleton)
    local depth = zombie_base.depth(ctx, level)
    local choices, total = pool.at_depth(branches.BRANCH_DUNGEON,
        depth)

    if total <= 0 then
        error("Dungeon has no zombie population at depth " .. depth)
    end

    for _ = 1, MAX_PICK_ATTEMPTS do
        local kind_id = pool.pick(ctx, choices, total, streams.CARDS)

        if kind_id ~= sentinels.NO_MONSTER then
            local definition = catalog.get(categories.MONSTERS, kind_id)

            local species = catalog.get(categories.MONSTERS,
                definition.species_id or definition.id)

            if eligible(ctx, player, definition, species) and
                (not skeleton or
                    not contains(species.flags,
                        flags.NO_SKELETON)) then
                return kind_id
            end
        end
    end

    error("Dungeon zombie population yielded no valid corpse base")
end

return zombie_base
