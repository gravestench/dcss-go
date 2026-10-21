-- The Spider basket uses the same saved marker and movement owner that a
-- mod-defined vault callback can use. Tests invoke production policy.
local component = require("constants.component")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local factory = require("policy.population.factory")
local triggers = require("policy.world.vault_triggers")
local trigger_ids = require("constants.vault_triggers")

local test = {}

-- A small ECS fixture stores the production component by its registered
-- key; it does not redeclare its schema or the Spider callback.
local function context()
    local ctx = {
        next_entity = 2,
        components = {},
        messages = {},
        blocked = {},
        occupied = {},
    }

    function ctx:player()
        return 1
    end

    function ctx:create()
        local entity = self.next_entity

        self.next_entity = self.next_entity + 1

        return entity
    end

    function ctx:add(entity, key, state)
        self.components[entity] = self.components[entity] or {}
        self.components[entity][key] = state
    end

    function ctx:get(entity, key)
        return self.components[entity] and self.components[entity][key]
    end

    function ctx:query(keys)
        local found = {}

        for entity, values in pairs(self.components) do
            if values[keys[1]] then
                found[#found + 1] = entity
            end
        end

        table.sort(found)

        return found
    end

    function ctx:destroy(entity)
        self.components[entity] = nil
    end

    function ctx:walkable(_, x, y)
        return not self.blocked[x .. ":" .. y]
    end

    function ctx:actor_at(_, x, y)
        return self.occupied[x .. ":" .. y]
    end

    function ctx:emit(_, message)
        self.messages[#self.messages + 1] = message
    end

    return ctx
end

-- A source marker becomes one one-shot ECS component, and an unrelated
-- marker does not enter the generic dispatch path.
local function marker_lifecycle()
    harness.falsy(triggers.is_record("lua:fog_machine"),
        "other source markers remain independent")

    local ctx = context()
    local level = { id = 9 }
    local record = {
        identity = trigger_ids.SPIDER_NEST_WARN,
        x = 7,
        y = 8,
        source_id = "spiders_nest_spider_trap",
        index = 4,
    }
    local materialized = triggers.materialize(ctx, level, record)

    harness.equal(materialized.index, 4,
        "marker keeps its source record index")
    harness.equal(#ctx:query({ component.WORLD_VAULT_TRIGGER }), 1,
        "one saved trigger entity")

    triggers.enter(ctx, ctx:player(), {
        level_id = 9,
        x = 6,
        y = 8,
    })

    harness.equal(#ctx.messages, 0, "other cells do not trigger")

    triggers.enter(ctx, ctx:player(), {
        level_id = 9,
        x = 7,
        y = 8,
    })

    harness.equal(#ctx.messages, 1, "warning callback reports once")
    harness.equal(#ctx:query({ component.WORLD_VAULT_TRIGGER }), 0,
        "source one-shot marker is consumed")

    triggers.enter(ctx, ctx:player(), {
        level_id = 9,
        x = 7,
        y = 8,
    })

    harness.equal(#ctx.messages, 1, "consumed marker cannot repeat")
end

-- The basket creates awake redbacks only on free passable cells around
-- the marker; the player cell and occupied cells remain untouched.
local function basket_spawns()
    local ctx = context()
    local level = { id = 9 }
    local record = {
        identity = trigger_ids.SPIDER_NEST_SPAWN,
        x = 7,
        y = 8,
        source_id = "spiders_nest_spider_trap",
        index = 5,
    }
    local spawned = {}
    local original_spawn = factory.spawn

    ctx:add(ctx:player(), component.POSITION, {
        level_id = 9,
        x = 7,
        y = 8,
    })
    ctx.blocked["6:7"] = true
    ctx.occupied["8:9"] = true

    factory.spawn = function(_, kind_id, level_id, x, y, options)
        spawned[#spawned + 1] = {
            kind_id = kind_id,
            level_id = level_id,
            x = x,
            y = y,
            awake = options.generate_awake,
        }

        return #spawned + 10
    end

    local ok, reason = pcall(function()
        triggers.materialize(ctx, level, record)
        triggers.enter(ctx, ctx:player(), {
            level_id = 9,
            x = 7,
            y = 8,
        })

        harness.equal(#spawned, 6,
            "eight neighbors minus blocked and occupied cells")
        harness.equal(spawned[1].kind_id, monsters.MONS_REDBACK,
            "source basket creates redbacks")
        harness.truthy(spawned[1].awake,
            "source generate_awake reaches monster factory")
        harness.equal(#ctx.messages, 1,
            "successful basket reports its source message")
    end)

    factory.spawn = original_spawn

    if not ok then
        error(reason)
    end
end

-- Both marker modes share the same ECS lifecycle and mod-safe dispatcher.
function test.run()
    marker_lifecycle()
    basket_spawns()
end

return test
