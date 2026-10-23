local relocation = require("policy.world.monster_relocation")
local component = require("constants.component")
local pikel = require("policy.combat.monster_tactical.pikel")
local constants = require("constants.abyss")
local generator = require("policy.generation.abyss")
local state = require("policy.generation.abyss.state")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local branches = require("ids.branches")
local terrain = require("constants.terrain")
local rune = require("policy.world.abyss.rune")
local population = require("policy.world.abyss.population")
local transit = require("policy.world.abyss.transit")
local streams = require("constants.rng_streams")
local conduct = require("policy.religion.conduct")
local monster_facts = require("policy.religion.conduct.monster_facts")

local abyss = {}

-- Keep branch levels outside the Dungeon depth IDs.
abyss.level_id = constants.LEVEL_ID

-- The source's proto feature pass places Lugonu's altar near the entry,
-- guaranteed for the pocket start and occasional for ordinary arrivals.
-- Choosing among open nearby cells leaves the exit under the player.
local function place_altar(ctx, level, guaranteed)
    if not guaranteed and
        ctx:random("abyss-placement", 5) ~= 0 then
        return
    end

    local nearby = {}

    for y = level.entry_y - constants.POCKET_ALTAR_RADIUS,
        level.entry_y + constants.POCKET_ALTAR_RADIUS do
        for x = level.entry_x - constants.POCKET_ALTAR_RADIUS,
            level.entry_x + constants.POCKET_ALTAR_RADIUS do
            if level.cells[y + 1] and
                level.cells[y + 1][x + 1] == terrain.DNGN_FLOOR and
                (x ~= level.entry_x or y ~= level.entry_y) then
                nearby[#nearby + 1] = { x = x, y = y }
            end
        end
    end

    if #nearby == 0 then
        if guaranteed then
            error("pocket Abyss has no cell for Lugonu's altar")
        end

        return
    end

    local altar = nearby[ctx:random("abyss-placement", #nearby) + 1]

    level.cells[altar.y + 1][altar.x + 1] =
        terrain.DNGN_ALTAR_LUGONU
end

-- Pick a walkable Abyss cell before saving a return point or moving an actor.
local function landing(ctx)
    for _ = 1, 200 do
        local x = ctx:random("abyss-placement", 78) + 1
        local y = ctx:random("abyss-placement", 68) + 1

        if ctx:walkable(abyss.level_id, x, y) and
            not ctx:actor_at(abyss.level_id, x, y) then
            return x, y
        end
    end

    error("the Abyss has no open landing cell")
end

-- Reentering or descending discards the previous visible window. Actors
-- are retired by the grid permutation; positioned loot and coordinate
-- based clouds then leave the same action with their old terrain.
local function plan_old_window(ctx, level, player)
    for _, actor in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
    })) do
        local position = ctx:get(actor, component.POSITION)

        if actor ~= player and position.level_id == abyss.level_id then
            level.actor_retire[#level.actor_retire + 1] = actor
        end
    end
end

local function retire_old_window(ctx, discarded)
    transit.retire(ctx, discarded)

    for _, entity in ipairs(ctx:query({ component.POSITION })) do
        local position = ctx:get(entity, component.POSITION)

        if not ctx:has(entity, component.ACTOR) and
            position.level_id == abyss.level_id then
            ctx:destroy(entity)
        end
    end

    for _, cloud in ipairs(ctx:query({ component.WORLD_CLOUD })) do
        local fields = ctx:get(cloud, component.WORLD_CLOUD)

        if fields.level_id == abyss.level_id then
            ctx:destroy(cloud)
        end
    end

    -- Fog machines are map-bound ECS clocks without core.position. Their
    -- source markers become inactive when this entire window is replaced.
    for _, machine in ipairs(ctx:query({ component.FOG_MACHINE })) do
        local fields = ctx:get(machine, component.FOG_MACHINE)

        if fields.level_id == abyss.level_id then
            ctx:destroy(machine)
        end
    end
end

-- A carried item can outlive the map that authored it. Keep inactive
-- source records ahead of the fresh map's records so its saved origin
-- index remains meaningful across reentry, descent, and teleportation.
local function retain_provenance(ctx, level)
    local prior = ctx:region_plan(abyss.level_id)
    local records = {}

    for _, record in ipairs(prior.vault_records or {}) do
        local copy = {}

        for name, value in pairs(record) do
            copy[name] = value
        end

        copy.overridden = true
        copy.pending = false
        records[#records + 1] = copy
    end

    for _, record in ipairs(level.vault_records or {}) do
        records[#records + 1] = record
    end

    level.vault_records = records
end

-- A fresh visit or depth change replaces the old window as one grid
-- transaction. The player moves to its safe centre; old entities retire
-- before new rune and vault entities are materialized on that terrain.
local function replace_visited_area(ctx, player, next_state, message)
    local level
    local protected

    level, next_state, protected = generator.generate(ctx, next_state)
    local rune_cell = rune.plan(ctx, level, next_state, protected)

    retain_provenance(ctx, level)
    level.actor_moves = {
        {
            actor = player,
            level_id = abyss.level_id,
            x = level.entry_x,
            y = level.entry_y,
        },
    }
    plan_old_window(ctx, level, player)
    local parked, discarded = transit.plan(ctx,
        level.actor_retire, next_state)

    ctx:replace_region(abyss.level_id, level)
    transit.store(ctx, parked)
    retire_old_window(ctx, discarded)
    rune.spawn(ctx, rune_cell)
    population.materialize(ctx, level)
    transit.release(ctx, next_state)
    ctx:replace_session_state(constants.SESSION_STATE, next_state)
    ctx:emit("banishment", message)
end

-- Both ordinary banishment and a Pan exit enter the same generated
-- window. The caller supplies the outside return site because Pan's
-- original Dungeon portal, rather than its temporary floor, owns it.
function abyss.enter(ctx, player, site, options)
    local current = ctx:session_state(constants.SESSION_STATE)
    options = options or {}
    local next_state = state.new(ctx, {
        branch_depth = options.branch_depth,
        return_site = site,
    })
    next_state.transit = current and current.transit or {}
    local level
    local protected

    level, next_state, protected = generator.generate(ctx, next_state, site)
    place_altar(ctx, level, false)
    local rune_cell = rune.plan(ctx, level, next_state, protected)

    retain_provenance(ctx, level)
    plan_old_window(ctx, level, player)
    local parked, discarded = transit.plan(ctx,
        level.actor_retire, next_state)

    -- The region must precede every ECS mutation in this action. Its
    -- structural command publishes the authored map before the player
    -- move; a later error reverses state and then the map.
    ctx:replace_region(abyss.level_id, level)
    transit.store(ctx, parked)
    retire_old_window(ctx, discarded)
    rune.spawn(ctx, rune_cell)

    ctx:add(player, component.BANISHMENT, {
        origin_level_id = site.level_id,
        origin_x = site.x,
        origin_y = site.y,
    })
    ctx:move_actor(player, abyss.level_id,
        level.entry_x, level.entry_y)
    population.materialize(ctx, level)
    transit.release(ctx, next_state)
    ctx:replace_session_state(constants.SESSION_STATE, next_state)
end

-- A Lugonu devotee begins in the pocket Abyss. D:1 already exists as the
-- return floor, but this start has no banishment component: its exit is a
-- chapter transition, not an escape from a hostile banishment effect.
function abyss.pocket_start(ctx, player)
    local position = ctx:get(player, component.POSITION)

    if not position or position.level_id ~= 1 then
        error("pocket Abyss start requires the new D:1 player")
    end

    local next_state = state.new(ctx, {
        pocket_start = true,
        return_site = {
            level_id = position.level_id,
            x = position.x,
            y = position.y,
        },
    })
    local level

    level, next_state = generator.generate(ctx, next_state)
    level.cells[level.entry_y + 1][level.entry_x + 1] =
        terrain.DNGN_EXIT_ABYSS
    place_altar(ctx, level, true)

    ctx:replace_region(abyss.level_id, level)
    ctx:replace_session_state(constants.SESSION_STATE, next_state)
    ctx:move_actor(player, abyss.level_id,
        level.entry_x, level.entry_y)
    population.materialize(ctx, level)
end

-- Banishment depth follows the source's rounded upper bound and inclusive
-- range. This is shared by divine wrath and monster effects with a power.
function abyss.depth_for_power(ctx, power, stream)
    local numerator = power + 5
    local maximum = math.floor(numerator / 6)
    local remainder = numerator % 6

    if remainder > 0 and ctx:random(stream, 6) < remainder then
        maximum = maximum + 1
    end

    local minimum = math.floor((4 * power + 7) / 23)
    local span = maximum - minimum + 1
    local depth = minimum

    if span > 1 then
        depth = depth + ctx:random(stream, span)
    end

    local bottom = catalog.get(categories.BRANCHES,
        branches.BRANCH_ABYSS).depth

    return math.min(bottom, math.max(1, depth))
end

-- Ordinary banishment remembers the outside cell. Forced rebanishment in
-- the Abyss descends one floor, or shifts the window at the branch bottom.
function abyss.banish(ctx, player, options)
    local position = ctx:get(player, component.POSITION)

    if not position then
        return
    end

    options = options or {}

    if position.level_id == abyss.level_id then
        if options.force then
            local current = ctx:session_state(constants.SESSION_STATE)
            local bottom = catalog.get(categories.BRANCHES,
                branches.BRANCH_ABYSS).depth

            if current.branch_depth < bottom then
                abyss.descend(ctx, player)
            else
                abyss.teleport(ctx, player)
            end
        end

        return
    end

    local depth = options.power and
        abyss.depth_for_power(ctx, options.power,
            options.stream or streams.PLACEMENT) or 1

    abyss.enter(ctx, player, {
        level_id = position.level_id,
        x = position.x,
        y = position.y,
    }, {
        branch_depth = depth,
    })
    ctx:emit("banishment", "You are cast into the Abyss!")
end

-- A source Abyssal stair changes branch depth and makes a fresh moving
-- window. The outside return site survives, while stale terrain entities
-- from the old window are retired at the same action barrier.
function abyss.descend(ctx, player)
    local current = ctx:session_state(constants.SESSION_STATE)
    local bottom = catalog.get(categories.BRANCHES,
        branches.BRANCH_ABYSS).depth

    if not current or current.branch_depth >= bottom then
        error("the Abyss has no deeper floor")
    end

    local next_state = state.new(ctx, {
        branch_depth = current.branch_depth + 1,
        return_site = current.return_site,
    })

    next_state.exit_xp = current.exit_xp
    next_state.exit_spawned = current.exit_spawned
    next_state.min_branch_depth = math.max(current.min_branch_depth,
        next_state.branch_depth)
    next_state.transit = current.transit

    replace_visited_area(ctx, player, next_state,
        "You descend deeper into the Abyss.")
end

-- Source Abyss teleportation either pulls a high-level character one
-- floor deeper or resets the visible window at the same branch depth.
-- Morph depth remains an independent clock and XP exit progress survives.
function abyss.teleport(ctx, player)
    local current = ctx:session_state(constants.SESSION_STATE)
    local position = ctx:get(player, component.POSITION)

    if not current or not position or
        position.level_id ~= abyss.level_id then
        error("Abyss teleport requires an active visit")
    end

    local progress = ctx:get(player, component.PROGRESSION)
    local bottom = catalog.get(categories.BRANCHES,
        branches.BRANCH_ABYSS).depth
    local difference = math.max(0,
        progress.level - current.branch_depth)

    if current.branch_depth < bottom and
        ctx:random(streams.PLACEMENT, 729 * 3) <
        difference * difference then
        abyss.descend(ctx, player)

        return
    end

    local next_state = state.new(ctx, {
        branch_depth = current.branch_depth,
        return_site = current.return_site,
        pocket_start = current.pocket_start,
    })

    next_state.exit_xp = current.exit_xp
    next_state.exit_spawned = current.exit_spawned
    next_state.min_branch_depth = current.min_branch_depth
    next_state.transit = current.transit

    replace_visited_area(ctx, player, next_state,
        "You are suddenly pulled into a different region of the Abyss!")
end

-- Distortion moves a monster to the existing Abyss level without a kill.
-- Its origin is saved so future Abyss and branch rules can find the actor.
function abyss.banish_monster(ctx, monster, definition, attacker)
    local position = ctx:get(monster, "core.position")

    if not position or position.level_id == abyss.level_id then
        return false
    end

    local event = monster_facts.banish(ctx, monster, definition, attacker)

    if event.credit then
        conduct.record(ctx, event)
    end

    local x, y = landing(ctx)

    ctx:add(monster, component.BANISHMENT, {
        origin_level_id = position.level_id,
        origin_x = position.x,
        origin_y = position.y,
    })
    relocation.move(ctx, monster, abyss.level_id, x, y)
    pikel.depart(ctx, monster, definition)
    ctx:emit("banishment", "The " .. definition.name ..
        " is cast into the Abyss!")

    return true
end

-- Use the saved banishment origin when returning; the Abyss level is not the source floor.
function abyss.escape(ctx, player)
    local return_to = ctx:get(player, component.BANISHMENT)

    if not return_to then
        local current = ctx:session_state(constants.SESSION_STATE)

        if current and current.pocket_start then
            return_to = {
                origin_level_id = current.return_site.level_id,
                origin_x = current.return_site.x,
                origin_y = current.return_site.y,
            }
            current.pocket_start = false
            ctx:replace_session_state(constants.SESSION_STATE, current)
        end
    end

    if not return_to then
        error("Abyss escape has no banishment origin")
    end

    local level_id = return_to.origin_level_id
    local x = return_to.origin_x
    local y = return_to.origin_y

    if not ctx:walkable(level_id, x, y) or ctx:actor_at(level_id, x, y) then
        local found = false

        for radius = 1, 12 do
            for offset_y = -radius, radius do
                for offset_x = -radius, radius do
                    local candidate_x = x + offset_x
                    local candidate_y = y + offset_y

                    if ctx:walkable(level_id, candidate_x, candidate_y) and
                        not ctx:actor_at(level_id, candidate_x, candidate_y) then
                        x = candidate_x
                        y = candidate_y
                        found = true
                        break
                    end
                end

                if found then
                    break
                end
            end

            if found then
                break
            end
        end

        if not found then
            error("Abyss escape has no safe return cell")
        end
    end

    ctx:move_actor(player, level_id, x, y)

    if ctx:has(player, component.BANISHMENT) then
        ctx:remove(player, component.BANISHMENT)
    end
    ctx:emit("stairs", "You escape the Abyss!")
end

return abyss
