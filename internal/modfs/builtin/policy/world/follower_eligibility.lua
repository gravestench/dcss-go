-- Source followers are selected by body, current action energy, attitude,
-- and travel mode. Keeping these gates together makes it possible to audit
-- every reason a monster stays at its departure point.
local attitudes = require("constants.attitude")
local behaviors = require("constants.ai_behaviors")
local branch_flags = require("constants.branch_flags")
local branches = require("ids.branches")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local modes = require("constants.follower_travel")
local groups = require("constants.monster_groups")
local habitat = require("policy.combat.monster_habitat")
local monsters = require("ids.monsters")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")

local eligibility = {}
local SOURCE_MINIMUM_ENERGY = 50

-- Source mons_class_can_use_stairs excludes these bodies regardless of
-- their current intelligence or attitude. Bound Soul is its one undead
-- template exception and therefore does not appear in this table.
local cannot_climb = {
    [monsters.MONS_ZOMBIE] = true,
    [monsters.MONS_ZOMBIE_SMALL] = true,
    [monsters.MONS_ZOMBIE_LARGE] = true,
    [monsters.MONS_SKELETON] = true,
    [monsters.MONS_SKELETON_SMALL] = true,
    [monsters.MONS_SKELETON_LARGE] = true,
    [monsters.MONS_SIMULACRUM] = true,
    [monsters.MONS_SIMULACRUM_SMALL] = true,
    [monsters.MONS_SIMULACRUM_LARGE] = true,
    [monsters.MONS_SPECTRAL_THING] = true,
    [monsters.MONS_SILENT_SPECTRE] = true,
    [monsters.MONS_GERYON] = true,
    [monsters.MONS_ROYAL_JELLY] = true,
    [monsters.MONS_BALL_LIGHTNING] = true,
    [monsters.MONS_FOXFIRE] = true,
}

-- Branches without cross-level travel refuse ordinary followers. The
-- source specifically allows Pandemonium despite its travel topology.
function eligibility.branch_allows(ctx, level_id)
    local branch_id = ctx:level_branch(level_id)

    if branch_id == branches.BRANCH_PANDEMONIUM then
        return true
    end

    local definition = catalog.get(categories.BRANCHES, branch_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == branch_flags.NO_X_LEVEL_TRAVEL then
            return false
        end
    end

    return true
end

-- The accepted action flag alone is not enough: Abyss feature stairs
-- and portal policies use different travel paths from linked stone stairs.
function eligibility.linked_stair(ctx, origin)
    local feature = ctx:cell(origin.level_id, origin.x, origin.y)

    if feature ~= terrain.DNGN_STONE_STAIRS_DOWN_I and
        feature ~= terrain.DNGN_STONE_STAIRS_UP_I then
        return false
    end

    local link = ctx:stair_at(origin.level_id, origin.x, origin.y)

    return link ~= nil and link.unavailable == "" and not link.exit
end

-- Search the current body's class flags, not its original identity:
-- polymorph can genuinely remove a monster's ability to use stairs.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Source eligibility is checked at tag time, including current action
-- energy. A later status tick must not retroactively admit an actor.
function eligibility.can_follow(ctx, entity, origin, mode)
    if mode ~= modes.STAIRS and mode ~= modes.TRANSPORTER then
        error("unknown follower travel mode " .. tostring(mode))
    end

    local actor = ctx:get(entity, component.ACTOR)
    local health = ctx:get(entity, component.HEALTH)
    local energy = ctx:get(entity, component.MONSTER_ENERGY)
    local ai = ctx:get(entity, component.AI)

    if not actor or not health or health.current <= 0 or
        not energy or energy.points < SOURCE_MINIMUM_ENERGY or
        not ai or ai.behavior == behaviors.SLEEP or
        ctx:has(entity, component.PARALYSIS) or
        (mode == modes.STAIRS and
            ctx:has(entity, component.SUMMON)) then
        return false
    end

    local stasis = ctx:get(entity, component.MONSTER_STASIS)

    if stasis and (stasis.petrified_aut > 0 or
        stasis.petrifying_aut > 0 or stasis.hibernating) then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    -- Transporters reject tentacles but can carry summoned and zombified
    -- bodies; the stricter source body exclusions apply only to stairs.
    if actor.speed <= 0 or
        has_flag(definition, flags.STATIONARY) or
        groups.tentacles[actor.kind_id] or
        (mode == modes.STAIRS and cannot_climb[actor.kind_id]) or
        not habitat.at(ctx, entity, origin.level_id,
            origin.x, origin.y) then
        return false
    end

    local attitude = targets.attitude(ctx, entity)

    if attitude == attitudes.FRIENDLY then
        return ai.behavior ~= behaviors.WANDER
    end

    -- Go's AI remembers a destination, rather than the C++ foe ID. A
    -- destination near the player's current cell distinguishes an active
    -- pursuit from a monster seeking another actor across the room.
    local position = ctx:get(entity, component.POSITION)
    local adjacent = math.max(math.abs(position.x - origin.x),
        math.abs(position.y - origin.y)) <= 1
    local seeking_player_cell = math.max(
        math.abs(ai.target_x - origin.x),
        math.abs(ai.target_y - origin.y)) <= 1

    return attitude == attitudes.HOSTILE and adjacent and
        ai.behavior == behaviors.SEEK and
        seeking_player_cell and
        targets.enemy(ctx, entity, ctx:player())
end

-- A nearby nonfriendly monster prevents the five-cell ally chain. This
-- decision uses occupants rather than only qualifying followers.
function eligibility.radius(ctx, origin, width, height, directions)
    for _, direction in ipairs(directions) do
        local x = origin.x + direction.x
        local y = origin.y + direction.y

        if x >= 0 and y >= 0 and x < width and y < height then
            local entity = ctx:actor_at(origin.level_id, x, y)

            if entity and targets.attitude(ctx, entity) ~=
                attitudes.FRIENDLY then
                return 1
            end
        end
    end

    return 5
end

return eligibility
