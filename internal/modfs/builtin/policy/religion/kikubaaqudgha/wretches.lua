-- Theory of operation: Unearth Wretches draws corpse-bearing bodies from the
-- effective branch population, places real hostile actors near the invoker,
-- and marks them for a short death timer. These are victims for Necromancy,
-- so using the summon owner would wrongly erase their corpses.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local habitat = require("policy.combat.monster_habitat")
local holiness = require("constants.monster_holiness")
local kiku = require("constants.kikubaaqudgha")
local late_branches = require("constants.late_zombie_branches")
local pool = require("policy.population.pool")
local generic_late_zombie = require("policy.population.generic_late_zombie")
local factory = require("policy.population.factory")
local power = require("policy.magic.power")
local senses = require("policy.character.senses")
local roster = require("policy.population.roster")
local scenarios = require("constants.scenarios")
local sentinels = require("constants.population_sentinels")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")

local wretches = {}
local RADIUS = kiku.WRETCH_RADIUS

-- Catalog species, rather than one hand-maintained list, determine which
-- modded monsters can leave an actual body for later Necromancy spells.
local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Reject source sentinels and bodyless species before any actor is built.
-- The no-unique rule avoids creating an unearned branch unique as fodder.
local function corpse_bearing(kind_id)
    if kind_id == sentinels.NO_MONSTER then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, kind_id)
    local species = catalog.get(categories.MONSTERS,
        definition.species_id or definition.id)

    return species.leaves_corpse and
        contains(species.holiness, holiness.NATURAL) and
        not contains(species.flags, flags.NO_ZOMBIE) and
        not contains(definition.flags, flags.NO_GEN_DERIVED) and
        not contains(definition.flags, flags.UNFINISHED) and
        not contains(definition.flags, flags.UNIQUE)
end

-- The source chooses a power-derived local branch depth, then the local
-- corpse pool gives out-of-depth zombies a modest bonus before capping it.
local function selection_depth(ctx, branch_id, adjusted)
    local branch = catalog.get(categories.BRANCHES, branch_id)
    local local_depth = adjusted - branch.absolute_depth
    local extra = math.floor(adjusted / 5)
    local remainder = adjusted % 5

    if remainder > 0 and
        ctx:random(streams.RELIGION, 5) < remainder then
        extra = extra + 1
    end

    -- Source absdungeon_depth(branch, 0) is absdepth minus one, so the
    -- constructed level starts one deeper before the zombie bonus.
    local cap = late_branches[branch_id] and 15 or
        branch.ood_cap or branch.depth

    return math.max(1, math.min(cap,
        local_depth + 2 + extra))
end

-- Weight only real corpse bodies. Source picker redraws rejected entries;
-- filtering first gives the same eligible distribution without a retry cap.
local function eligible_choices(choices)
    local filtered = {}
    local total = 0

    for _, choice in ipairs(choices) do
        if corpse_bearing(choice.id) then
            filtered[#filtered + 1] = choice
            total = total + choice.weight
        end
    end

    return filtered, total
end

-- Prefer the current branch's committed zombie population. Late branches
-- share a dedicated roster; ordinary branches use their ambient source rows.
local function pick_in_branch(ctx, branch_id, depth)
    local choices

    if late_branches[branch_id] then
        choices = pool.at_rows(generic_late_zombie, depth)
    else
        local allowed = roster.allowed(
            scenarios.GENERATED_DUNGEON_BASIC, branch_id)

        choices = pool.at_depth(branch_id, depth, allowed,
            scenarios.GENERATED_DUNGEON_BASIC)
    end

    local eligible, total = eligible_choices(choices)

    if total > 0 then
        return pool.pick(ctx, eligible, total, streams.RELIGION)
    end

    return nil
end

-- A branch without natural corpses falls back to all effective population
-- rows, preserving mod additions and source rarity curves without a second
-- fixed monster list. The catalog sorts definitions before this scan.
local function pick_elsewhere(ctx, adjusted)
    local choices = {}

    for _, definition in ipairs(catalog.all(categories.POPULATIONS)) do
        if not definition.scenario_id or
            definition.scenario_id ==
                scenarios.GENERATED_DUNGEON_BASIC then
            local branch = catalog.get(categories.BRANCHES,
                definition.branch_id)
            local depth = math.max(1, math.min(
                branch.ood_cap or branch.depth,
                adjusted - branch.absolute_depth + 2))
            local local_choices = pool.at_rows(definition.rows, depth)

            for _, choice in ipairs(local_choices) do
                choices[#choices + 1] = choice
            end
        end
    end

    local eligible, total = eligible_choices(choices)

    if total > 0 then
        return pool.pick(ctx, eligible, total, streams.RELIGION)
    end

    return nil
end

-- Two nested source random2 calls bias the body toward weaker local
-- monsters even when the player's Necromancy skill is high.
function wretches.kind(ctx, player)
    local position = ctx:get(player, component.POSITION)
    local branch_id = ctx:level_branch(position.level_id)
    local trained = power.training(ctx, player, skills.SK_NECROMANCY, 4)
    local first = trained > 0 and
        ctx:random(streams.RELIGION, trained) or 0
    local second = first > 0 and
        ctx:random(streams.RELIGION, first) or 0
    local adjusted = math.min(math.floor(trained / 4), second)
    local depth = selection_depth(ctx, branch_id, adjusted)

    return pick_in_branch(ctx, branch_id, depth) or
        pick_elsewhere(ctx, adjusted)
end

-- Scan a randomized radius-two square. LOS_NO_TRANS prevents actors from
-- rising behind a wall, and the habitat owner admits nonfloor bodies only
-- on terrain where that particular species can stand.
local function open_cell(ctx, position, kind_id)
    local cells = {}

    for dy = -RADIUS, RADIUS do
        for dx = -RADIUS, RADIUS do
            if dx ~= 0 or dy ~= 0 then
                cells[#cells + 1] = {
                    x = position.x + dx,
                    y = position.y + dy,
                }
            end
        end
    end

    local start = ctx:random(streams.RELIGION, #cells) + 1

    for index = 0, #cells - 1 do
        local cell = cells[(start + index - 1) % #cells + 1]

        if ctx:visible_no_trans(position.level_id, position.x,
            position.y, RADIUS, cell.x, cell.y) and
            habitat.kind_at(ctx, kind_id, position.level_id,
                cell.x, cell.y) and
            not ctx:actor_at(position.level_id, cell.x, cell.y) then
            return cell.x, cell.y
        end
    end

    return nil, nil
end

-- A successful placement uses a normal monster body and HP maximum, then
-- leaves it at one current HP. The permanent paralysis makes it fodder, not
-- a short-lived extra combatant; the timer kills it through actor.death.
function wretches.spawn(ctx, player, kind_id)
    local position = ctx:get(player, component.POSITION)
    local x, y = open_cell(ctx, position, kind_id)

    if not x then
        return nil
    end

    -- Source mgen skips starting equipment for Kiku wretches. The empty
    -- explicit loadout prevents the ordinary monster gear roller from
    -- leaving free weapons beside the guaranteed corpse.
    local creature = factory.spawn(ctx, kind_id, position.level_id,
        x, y, {
            equipment = {},
        })
    local health = ctx:get(creature, component.HEALTH)

    health.current = 1
    ctx:set(creature, component.HEALTH, health)
    ctx:add(creature, component.PARALYSIS, {
        remaining_aut = kiku.WRETCH_PARALYSIS_AUT,
    })
    ctx:add(creature, component.RELIGION_KIKU_WRETCH, {
        remaining_aut = kiku.WRETCH_MIN_LIFE_AUT +
            ctx:random(streams.RELIGION, kiku.WRETCH_LIFE_SPAN_AUT),
    })

    return creature
end

-- Source div_rand_round makes the possible count grow slowly with skill,
-- from two without training to at most eight at full Necromancy.
function wretches.count(ctx, player)
    local trained = power.training(ctx, player, skills.SK_NECROMANCY, 6)
    local extra = math.floor(trained / kiku.WRETCH_COUNT_SKILL_DIVISOR)
    local remainder = trained % kiku.WRETCH_COUNT_SKILL_DIVISOR

    if remainder > 0 and
        ctx:random(streams.RELIGION,
            kiku.WRETCH_COUNT_SKILL_DIVISOR) < remainder then
        extra = extra + 1
    end

    local maximum = kiku.WRETCH_MIN_COUNT + extra

    return kiku.WRETCH_MIN_COUNT +
        ctx:random(streams.RELIGION,
            maximum - kiku.WRETCH_MIN_COUNT + 1)
end

-- Keep each body selection independent. Space can fill after the first
-- success, but that does not roll back earlier creatures or the invocation.
function wretches.invoke(ctx, player)
    local created = 0

    for _ = 1, wretches.count(ctx, player) do
        local kind_id = wretches.kind(ctx, player)

        if kind_id and wretches.spawn(ctx, player, kind_id) then
            created = created + 1
        end
    end

    return created
end

-- Aging happens only when the monster's floor is active. Setting HP to zero
-- lets the ordinary death owner drop inventory and the guaranteed corpse.
function wretches.tick(ctx, creature, elapsed_aut)
    local marker = ctx:get(creature, component.RELIGION_KIKU_WRETCH)

    if not marker or elapsed_aut <= 0 then
        return
    end

    marker.remaining_aut = math.max(0,
        marker.remaining_aut - elapsed_aut)

    if marker.remaining_aut == 0 then
        ctx:set(creature, component.RELIGION_KIKU_WRETCH, marker)

        local health = ctx:get(creature, component.HEALTH)

        if health and health.current > 0 then
            health.current = 0
            ctx:set(creature, component.HEALTH, health)
        end

        local actor = ctx:get(creature, component.ACTOR)

        if actor and senses.player_sees_actor(ctx, creature) then
            ctx:emit("monster", "A nearby " ..
                catalog.get(categories.MONSTERS, actor.kind_id).name ..
                " perishes wretchedly.")
        end

        return
    end

    ctx:set(creature, component.RELIGION_KIKU_WRETCH, marker)
end

return wretches
