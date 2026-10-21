-- The Lady's source MAP owns several entrance cells and one deep-water
-- avatar cell. Exercise those real placement records through the saved
-- trigger owner, rather than restating their coordinates in a fixture.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local component = require("constants.component")
local effects = require("constants.vault_effects")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local factory = require("policy.population.factory")
local placement = require("policy.generation.vaults.placement")
local triggers = require("policy.world.vault_triggers")
local trigger_ids = require("constants.vault_triggers")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- The source map does not need random layout variation for this trigger
-- contract; zero is a valid bounded draw at every placement step.
local function map_context()
    local context = {}

    function context:random_u64()
        return 0, 0
    end

    return context
end

-- Reuse the production Akara context and component schemas. Only the grid
-- and messages need a proxy because this Lua rule runner has no live level.
local function game_context(ctx)
    local game = setmetatable({
        messages = {},
        occupied = {},
        visible_target = false,
    }, { __index = ctx })
    local player = ctx:create()

    function game:player()
        return player
    end

    function game:walkable()
        return true
    end

    function game:actor_at(_, x, y)
        return self.occupied[x .. ":" .. y]
    end

    function game:visible()
        return self.visible_target
    end

    function game:emit(_, message)
        self.messages[#self.messages + 1] = message
    end

    return game
end

-- Preserve the generated marker records as the level's authoritative
-- intent; their final coordinates already include DES substitution.
local function source_level()
    vaults.load()

    local definition = vaults.get("grunt_lady_of_the_lake")
    local builder = grid.new(map_context())
    local player = {
        branch_id = branches.BRANCH_SWAMP,
        depth = 2,
        branch_bottom = 4,
        absolute_depth = 16,
    }
    local placed = placement.place(nil, builder, definition, player)
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

-- A failed spawn leaves both entrance groups armed. Once either succeeds,
-- all source entrances consume the same one-shot encounter.
function test.run(ctx)
    local level = source_level()
    local game = game_context(ctx)
    local entrances = {}
    local target
    local spawned = {}
    local original_spawn = factory.spawn

    for _, record in ipairs(level.vault_records) do
        if record.kind == effects.MARKER and
            record.identity == trigger_ids.LADY_OF_LAKE_SPAWN then
            entrances[#entrances + 1] = record
            triggers.materialize(game, level, record)
        elseif record.kind == effects.MARKER and
            record.identity == trigger_ids.MERFOLK_AVATAR_TARGET then
            target = record
        end
    end

    harness.truthy(#entrances > 1, "source has several entrance cells")
    harness.truthy(target, "source has one avatar target")

    factory.spawn = function(_, kind_id, level_id, x, y, options)
        local avatar = game:create()

        spawned[#spawned + 1] = {
            entity = avatar,
            kind_id = kind_id,
            level_id = level_id,
            x = x,
            y = y,
            awake = options.generate_awake,
        }

        return avatar
    end

    local okay, reason = pcall(function()
        local first = entrances[1]

        game:add(game:player(), component.POSITION, {
            level_id = level.id,
            x = first.x,
            y = first.y,
        })

        game.occupied[target.x .. ":" .. target.y] = true

        triggers.enter(game, game:player(), {
            level_id = level.id,
            x = first.x,
            y = first.y,
        })

        harness.equal(#spawned, 0, "occupied lake cell blocks spawn")
        harness.equal(#game:query({ component.WORLD_VAULT_TRIGGER }),
            #entrances, "failed attempt keeps shared trigger armed")

        game.occupied[target.x .. ":" .. target.y] = nil
        game.visible_target = true

        local second = entrances[2]

        game:set(game:player(), component.POSITION, {
            level_id = level.id,
            x = second.x,
            y = second.y,
        })

        triggers.enter(game, game:player(), {
            level_id = level.id,
            x = second.x,
            y = second.y,
        })

        harness.equal(#spawned, 1, "one avatar appears")
        harness.equal(spawned[1].kind_id,
            monsters.MONS_MERFOLK_AVATAR, "source merfolk avatar")
        harness.equal(spawned[1].x, target.x, "avatar target x")
        harness.equal(spawned[1].y, target.y, "avatar target y")
        harness.truthy(spawned[1].awake, "source awake spawn")
        harness.truthy(game:has(spawned[1].entity,
            component.WORLD_VAULT_SPAWN),
            "spawned avatar keeps its saved source marker")
        harness.equal(#game:query({ component.WORLD_VAULT_TRIGGER }),
            0, "all shared entrances are consumed")
    end)

    factory.spawn = original_spawn

    if not okay then
        error(reason)
    end
end

return test
