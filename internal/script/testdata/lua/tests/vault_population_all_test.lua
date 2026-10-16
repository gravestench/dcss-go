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

local test = {}

local function random_context(seed)
    local context = {}
    local next_value = seed

    function context:random_u64()
        next_value = (next_value * 1664525 + 1013904223) % 4294967296

        return 0, next_value
    end

    return context
end

local function entity_context()
    local world = {
        next_id = 0,
        entities = {},
        actors = {},
        cells = {},
    }

    function world:create()
        self.next_id = self.next_id + 1
        self.entities[self.next_id] = {}

        return self.next_id
    end

    function world:add(entity, kind, value)
        self.entities[entity][kind] = value
    end

    function world:get(entity, kind)
        return self.entities[entity] and self.entities[entity][kind]
    end

    function world:has(entity, kind)
        return self:get(entity, kind) ~= nil
    end

    function world:set(entity, kind, value)
        self.entities[entity][kind] = value
    end

    function world:player()
        return self.player_id
    end

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

    function world:random(_, bound)
        harness.truthy(bound > 0, "invalid source random bound")

        return 0
    end

    function world:walkable()
        return true
    end

    function world:cell(level_id, x, y)
        return self.cells[level_id .. ":" .. x .. ":" .. y] or
            terrain.DNGN_FLOOR
    end

    function world:set_cell(level_id, x, y, feature)
        self.cells[level_id .. ":" .. x .. ":" .. y] = feature
    end

    function world:actor_at(level_id, x, y)
        return self.actors[level_id .. ":" .. x .. ":" .. y]
    end

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

local function check_arrival(id, index)
    local source = catalog.get(id)
    local random = random_context(index)
    local placed = placement.place(random, grid.new(random), source)
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

    harness.equal(#outcomes, expected, id .. " materialized record count")

    local origins = {}

    for _, entity in ipairs(world:query({ component.VAULT_ORIGIN })) do
        local origin = world:get(entity, component.VAULT_ORIGIN)

        if origin.occurrence == 1 then
            origins[origin.record_index] = true
        end
    end

    for _, outcome in ipairs(outcomes) do
        harness.truthy(outcome.no_spawn or origins[outcome.index],
            id .. " selected an entity without an ECS origin")
    end
end

function test.run()
    local ids = selection.eligible_ids()

    harness.equal(#ids, 337, "selectable source arrivals")

    for index, id in ipairs(ids) do
        check_arrival(id, index)
    end
end

return test
