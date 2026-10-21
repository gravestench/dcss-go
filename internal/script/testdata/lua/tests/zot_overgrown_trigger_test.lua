-- Exercise the source-authored overgrown stair markers against the real
-- ECS schema. A saved controller must resume its countdown after LOS.
local branches = require("ids.branches")
local component = require("constants.component")
local effects = require("constants.vault_effects")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local factory = require("policy.population.factory")
local placement = require("policy.generation.vaults.placement")
local overgrown = require("policy.world.zot_overgrown")
local triggers = require("constants.vault_triggers")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- A stable stream makes source substitutions deterministic without copying
-- their DES rules into this fixture.
local function map_context()
    local state = 719
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- Keep generated records and their resolved coordinates as the test input.
local function source_level()
    vaults.load()

    local definition = vaults.get("grunt_zot_stairs_overgrown")
    local builder = grid.new(map_context())
    local placed = placement.place(nil, builder, definition, {
        branch_id = branches.BRANCH_ZOT,
        depth = 2,
        branch_bottom = 5,
        absolute_depth = 28,
    })
    local level = {
        id = 9,
        vault_records = {},
    }

    for index, record in ipairs(placed.records) do
        record.source_id = record.vault_id
        record.index = index
        level.vault_records[#level.vault_records + 1] = record
    end

    return level
end

-- The real Akara context supplies storage. Only level sight, time, and the
-- source occupied cells need a proxy in a Lua-only rule test.
local function game_context(ctx)
    local game = setmetatable({
        current_aut = 0,
        seen = false,
        messages = {},
        occupied = {},
    }, { __index = ctx })
    local player = ctx:create()

    function game:player()
        return player
    end

    function game:aut()
        return self.current_aut
    end

    function game:random()
        return 0
    end

    function game:visible()
        return self.seen
    end

    function game:actor_at(_, x, y)
        return self.occupied[x .. ":" .. y]
    end

    function game:remove_actor(actor)
        for cell, occupant in pairs(self.occupied) do
            if occupant == actor then
                self.occupied[cell] = nil

                return
            end
        end
    end

    function game:emit(_, message)
        self.messages[#self.messages + 1] = message
    end

    return game
end

-- LOS arms one controller, then one elapsed timer converts a source plant
-- into an oklob and leaves its count in saved component state.
function test.run(ctx)
    local level = source_level()
    local game = game_context(ctx)
    local controller
    local target
    local spawned = {}
    local original_spawn = factory.spawn

    for _, record in ipairs(level.vault_records) do
        if record.kind == effects.MARKER and
            overgrown.is_record(record.identity) then
            overgrown.materialize(game, level, record)

            if record.identity == triggers.ZOT_OVERGROWN_START then
                controller = record
            elseif record.identity == triggers.ZOT_OVERGROWN_TARGET then
                target = record
            end
        end
    end

    harness.truthy(controller, "source LOS controller is present")
    harness.truthy(target, "source plant target is present")

    game:add(game:player(), component.POSITION, {
        level_id = level.id,
        x = controller.x,
        y = controller.y,
    })

    local plant = game:create()

    game:add(plant, component.ACTOR, {
        kind_id = monsters.MONS_PLANT,
    })
    game.occupied[target.x .. ":" .. target.y] = plant

    factory.spawn = function(_, kind_id, level_id, x, y)
        spawned[#spawned + 1] = {
            kind_id = kind_id,
            level_id = level_id,
            x = x,
            y = y,
        }

        return game:create()
    end

    local okay, reason = pcall(function()
        -- The source repeated timer keeps rolling while the LOS trigger is
        -- dormant; arriving long after generation must not use a stale
        -- deadline and convert a plant immediately after the warning.
        game.current_aut = 2000
        overgrown.update(game, game:player())
        harness.equal(#game.messages, 0, "unseen marker stays dormant")

        game.seen = true
        overgrown.update(game, game:player())
        harness.equal(game.messages[1],
            "You have a sense of imminent foreboding.",
            "source LOS warning")

        overgrown.update(game, game:player())
        harness.equal(#spawned, 0,
            "a stale pre-LOS deadline never converts immediately")

        game.current_aut = 2300
        overgrown.update(game, game:player())
        harness.equal(#spawned, 1, "first elapsed timer converts a plant")
        harness.equal(spawned[1].kind_id, monsters.MONS_OKLOB_PLANT,
            "source oklob species")

        local states = game:query({ component.WORLD_ZOT_OVERGROWN })
        local saved

        for _, entity in ipairs(states) do
            local state = game:get(entity, component.WORLD_ZOT_OVERGROWN)

            if state.role == triggers.ZOT_OVERGROWN_CONTROLLER then
                saved = state
            end
        end

        harness.equal(saved.count, 1, "saved conversion count")
        harness.truthy(saved.next_aut > game.current_aut,
            "next source countdown survives save")
    end)

    factory.spawn = original_spawn
    harness.truthy(okay, tostring(reason))
end

return test
