-- Every selected vault population entity receives an ECS origin.

local catalog = require("policy.generation.vaults.catalog")
local component = require("constants.component")
local effects = require("constants.vault_effects")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local history = require("policy.item_generation.artefacts.history")
local placement = require("policy.generation.vaults.placement")
local population = require("policy.population.vaults")
local selection = require("policy.generation.vaults.selection")
local terrain = require("constants.terrain")
local trap_placement = require("policy.traps.placement")
local branches = require("ids.branches")

local test = {}

-- Each arrival index seeds a reproducible vault placement draw sequence.
local function random_context(seed)
    local context = {}
    local next_value = seed

    -- Derive a repeatable draw sequence from the arrival index.
    function context:random_u64()
        next_value = (next_value * 1664525 + 1013904223) % 4294967296

        return 0, next_value
    end

    return context
end

-- Materialize records in a real component store with deterministic terrain
-- and actor occupancy responses.
local function entity_context()
    local world = {
        next_id = 0,
        entities = {},
        actors = {},
        cells = {},
    }

    -- Allocate monotonically increasing IDs so fixture queries have stable order.
    function world:create()
        self.next_id = self.next_id + 1
        self.entities[self.next_id] = {}

        return self.next_id
    end

    -- Store actual components for population materialization assertions.
    function world:add(entity, kind, value)
        self.entities[entity][kind] = value
    end

    -- Read the fixture component table like the production ECS context.
    function world:get(entity, kind)
        return self.entities[entity] and self.entities[entity][kind]
    end

    -- Share get() semantics when policies test component presence.
    function world:has(entity, kind)
        return self:get(entity, kind) ~= nil
    end

    -- Replace a component in place for policies that update saved state.
    function world:set(entity, kind, value)
        self.entities[entity][kind] = value
    end

    -- Return the fixture player that owns unique-artefact history.
    function world:player()
        return self.player_id
    end

    -- Return entities having every requested component in stable ID order.
    function world:query(kinds)
        local found = {}

        for entity = 1, self.next_id do
            local has_all = true

            for _, kind in ipairs(kinds) do
                has_all = has_all and self:get(entity, kind) ~= nil
            end

            if has_all then
                found[#found + 1] = entity
            end
        end

        return found
    end

    -- Force first weighted choices while rejecting zero-sized source draws.
    function world:random(_, bound)
        harness.truthy(bound > 0, "invalid source random bound")

        return 0
    end

    -- Keep fixture cells open so unresolved records, not terrain, cause failures.
    function world:walkable()
        return true
    end

    -- Read terrain writes with floor and coordinate keys, defaulting to floor.
    function world:cell(level_id, x, y)
        return self.cells[level_id .. ":" .. x .. ":" .. y] or
            terrain.DNGN_FLOOR
    end

    -- Remember terrain changes for later habitat and trap checks.
    function world:set_cell(level_id, x, y, feature)
        self.cells[level_id .. ":" .. x .. ":" .. y] = feature
    end

    -- Expose prior actor placement so later records cannot overlap it.
    function world:actor_at(level_id, x, y)
        return self.actors[level_id .. ":" .. x .. ":" .. y]
    end

    -- Write both occupancy and ECS position for materialized actors.
    function world:place_actor(entity, level_id, x, y)
        self.actors[level_id .. ":" .. x .. ":" .. y] = entity
        self:add(entity, component.POSITION, {
            level_id = level_id,
            x = x,
            y = y,
        })
    end

    world.player_id = world:create()
    history.initialise(world, world.player_id)

    return world
end

-- Every placed entity record must become either a typed outcome or an origin
-- tracked ECS entity; authored "nothing" may resolve to no spawn.
local function check_arrival(id, index)
    local source = catalog.get(id)
    local random = random_context(index)
    local placed = placement.place(random, grid.new(random), source, {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 1,
        branch_bottom = 15,
        layout_family = "open",
    })
    local level = {
        id = 1,
        vault_records = placed.records,
    }
    local expected = 0

    for record_index, record in ipairs(level.vault_records) do
        record.index = record_index
        record.source_id = record.vault_id

        if record.kind == effects.MONSTER or record.kind == effects.ITEM then
            local arguments = record.arguments or {}

            if arguments.no_spawn then
                harness.falsy(record.pending, id .. " has pending nothing")
            elseif arguments.kind_id and arguments.kind_id ~= "" then
                expected = expected + 1
            else
                error(id .. " has unresolved entity glyph " .. tostring(record.source))
            end
        end
    end

    local world = entity_context()
    local _, outcomes = population.materialize(world, level)

    local placed_traps = world:query({ component.WORLD_TRAP })

    harness.equal(#outcomes, expected + #placed_traps,
        id .. " materialized record count")

    local origins = {}

    for _, entity in ipairs(world:query({ component.VAULT_ORIGIN })) do
        local origin = world:get(entity, component.VAULT_ORIGIN)

        if origin.occurrence == 1 then
            origins[origin.record_index] = true
        end
    end

    for _, outcome in ipairs(outcomes) do
        local record = level.vault_records[outcome.index]

        harness.truthy(outcome.no_spawn or origins[outcome.index] or
            trap_placement.is_trap(record),
            id .. " selected an entity without an ECS origin")
    end
end

-- Walk every selectable arrival and verify each resolved entity's origin or no-spawn outcome.
function test.run()
    local ids = selection.eligible_ids()

    harness.equal(#ids, 337, "selectable source arrivals")

    -- Iterate all selectable committed arrivals, including helper records.
    for index, id in ipairs(ids) do
        check_arrival(id, index)
    end
end

return test
