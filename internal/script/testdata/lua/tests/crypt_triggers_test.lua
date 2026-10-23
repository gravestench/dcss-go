-- The glass ending's source markers become a saved one-shot ECS trigger.
-- Its linked grate cells come from the actual placed and oriented DES map.
local branches = require("ids.branches")
local component = require("constants.component")
local factory = require("policy.population.factory")
local monsters = require("ids.monsters")
local effects = require("constants.vault_effects")
local terrain_features = require("content.terrain_features")
local vault_features = require("constants.vault_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local terrain = require("constants.terrain")
local triggers = require("policy.world.vault_triggers")
local trigger_ids = require("constants.vault_triggers")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- The local generation stream is independent of other map selections.
local function random_context()
    local state = 41
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- The ECS store and source record shapes stay production-owned. The only
-- local stand-in is the level grid that a full game session would install.
local function game_context(ctx)
    local game = setmetatable({
        cells = {},
        messages = {},
        see_grates = true,
    }, { __index = ctx })
    local player = ctx:create()

    function game:player()
        return player
    end

    function game:cell(_, x, y)
        return self.cells[x .. ":" .. y] or terrain.DNGN_FLOOR
    end

    function game:set_cell(_, x, y, feature)
        self.cells[x .. ":" .. y] = feature
    end

    function game:visible()
        return self.see_grates
    end

    function game:emit(_, message)
        self.messages[#self.messages + 1] = message
    end

    function game:set_cell_colour(_, x, y, colour)
        self.colours = self.colours or {}
        self.colours[x .. ":" .. y] = colour
    end

    function game:random(_, bound)
        return 0 % bound
    end

    return game, player
end

-- Entering any prize marker opens every linked grate exactly once. A
-- subsequent move cannot repeat the callback or its player message.
function test.run(ctx)
    -- The source m key must become a real grate before the callback can
    -- identify what to lower on a fully generated floor.
    local terrain_cells = terrain_features.decode_source_rows({ "m" })

    terrain_features.apply_vault_terrain(terrain_cells, {
        {
            kind = effects.FEATURE,
            identity = vault_features.IRON_GRATE,
            x = 0,
            y = 0,
        },
    })
    harness.equal(
        terrain_cells[1][1],
        terrain.DNGN_GRATE,
        "source iron_grate projects to a real blocking grate"
    )

    local definition = vaults.get("david_glass_crypt")
    local placed =
        placement.place(nil, grid.new(random_context()), definition, {
            branch_id = branches.BRANCH_CRYPT,
            depth = 3,
            branch_bottom = 3,
            absolute_depth = 21,
        })
    local level = {
        id = 88,
        vault_records = placed.records,
    }
    local game, player = game_context(ctx)
    local first
    local grates = {}

    for index, record in ipairs(level.vault_records) do
        record.index = index
        record.source_id = record.vault_id
    end

    for _, record in ipairs(level.vault_records) do
        if
            record.kind == effects.MARKER
            and record.identity == trigger_ids.CRYPT_GRATES_DROP
        then
            first = first or record
            triggers.materialize(game, level, record)
        elseif
            record.kind == effects.MARKER
            and record.identity == trigger_ids.CRYPT_GRATE_TARGET
        then
            grates[#grates + 1] = record
            game:set_cell(level.id, record.x, record.y, terrain.DNGN_GRATE)
        end
    end

    harness.truthy(first, "glass ending has no source trigger")
    harness.truthy(#grates > 0, "glass ending has no linked grates")

    game:add(player, component.POSITION, {
        level_id = level.id,
        x = first.x,
        y = first.y,
    })
    triggers.enter(game, player, {
        level_id = level.id,
        x = first.x,
        y = first.y,
    })

    for _, grate in ipairs(grates) do
        harness.equal(
            game:cell(level.id, grate.x, grate.y),
            terrain.DNGN_FLOOR,
            "source grate did not fall"
        )
    end

    harness.equal(#game.messages, 1, "grate event message count")
    harness.equal(
        #game:query({ component.WORLD_VAULT_TRIGGER }),
        0,
        "glass ending trigger group is consumed"
    )

    -- The arrival uses the same saved marker machinery, but its event is
    -- visibility rather than stepping on a prize cell.
    local guard = vaults.get("grunt_crypt_arrival_guarded_gate")
    local guarded = placement.place(nil, grid.new(random_context()), guard, {
        branch_id = branches.BRANCH_CRYPT,
        depth = 1,
        branch_bottom = 3,
        absolute_depth = 19,
    })
    local arrival = {
        id = 89,
        vault_records = guarded.records,
    }
    local guard_game, guard_player = game_context(ctx)
    local watch
    local sarcophagi = {}
    local spawned = {}

    for index, record in ipairs(arrival.vault_records) do
        record.index = index
        record.source_id = record.vault_id
    end

    for _, record in ipairs(arrival.vault_records) do
        if
            record.kind == effects.MARKER
            and record.identity == trigger_ids.CRYPT_GUARDS_AWAKEN
        then
            watch = record
            triggers.materialize(guard_game, arrival, record)
        elseif
            record.kind == effects.MARKER
            and record.identity == trigger_ids.CRYPT_SARCOPHAGUS_TARGET
        then
            sarcophagi[#sarcophagi + 1] = record
            guard_game:set_cell(
                arrival.id,
                record.x,
                record.y,
                terrain.DNGN_GRANITE_STATUE
            )
        end
    end

    harness.truthy(watch, "guarded arrival has no LOS watcher")
    harness.truthy(#sarcophagi > 0, "guarded arrival has no linked sarcophagi")

    local position = {
        level_id = arrival.id,
        x = watch.x,
        y = watch.y,
    }

    guard_game:add(guard_player, component.POSITION, position)
    guard_game.see_grates = false
    triggers.player_los(guard_game, guard_player, position)
    harness.equal(
        #guard_game.messages,
        0,
        "sarcophagi wait until their watcher is visible"
    )

    local original_spawn = factory.spawn

    factory.spawn = function(_, kind_id, level_id, x, y, options)
        spawned[#spawned + 1] = {
            kind_id = kind_id,
            level_id = level_id,
            x = x,
            y = y,
            base_id = options.base_id,
        }

        return guard_game:create()
    end

    local okay, reason = pcall(function()
        guard_game.see_grates = true
        triggers.player_los(guard_game, guard_player, position)
    end)

    factory.spawn = original_spawn

    if not okay then
        error(reason)
    end

    harness.equal(
        #spawned,
        #sarcophagi,
        "each source sarcophagus releases one guard"
    )
    harness.equal(
        spawned[1].kind_id,
        monsters.MONS_SKELETON,
        "first source weighted choice is a human skeleton"
    )
    harness.equal(spawned[1].base_id, monsters.MONS_HUMAN)
    harness.equal(
        guard_game.messages[1],
        "Something awakens from inside the sarcophagi!"
    )
    harness.equal(
        #guard_game:query({ component.WORLD_VAULT_TRIGGER }),
        0,
        "guarded arrival cannot awaken twice"
    )

    for _, sarcophagus in ipairs(sarcophagi) do
        harness.equal(
            guard_game:cell(arrival.id, sarcophagus.x, sarcophagus.y),
            terrain.DNGN_FLOOR
        )
    end
end

return test
