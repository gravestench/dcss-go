-- Vault entity expressions resolve before population; source operation order,
-- unique-monster history, and diagnostics must survive that boundary.

local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local catalog = require("policy.generation.vaults.catalog")
local entity_specs = require("policy.generation.vaults.specs.validate")
local materializer = require("policy.population.vaults")
local component = require("constants.component")
local monsters = require("ids.monsters")
local items = require("ids.items")
local branches = require("ids.branches")

local test = {}

-- Give materialization a real player ledger, where source uniques record
-- their run-wide claim. The surrounding world still uses the test ECS.
local function world_context(ctx)
    local world = setmetatable({}, { __index = ctx })
    local player = ctx:create()

    ctx:add(player, component.PLAYER_UNIQUE_HISTORY, {
        status = {},
        monsters = {},
        pan_states = {},
    })

    function world:player()
        return player
    end

    return world
end

-- Give vault placement a reproducible 64-bit draw source for declaration tests.
local function builder_context()
    local context = {}
    local next_value = 1

    -- Advance a small deterministic sequence so repeated placements take the same branches.
    function context:random_u64()
        next_value = (next_value * 1664525 + 1013904223) % 4294967296

        return 0, next_value
    end

    return context
end

-- KMONS and ITEM glyphs become typed records while retaining the DES expression.
local function resolved_entity_records()
    local source = {
        id = "resolved_fixture",
        path = "vaults/arrival/resolved_fixture.des",
        rows = { "@ABd" },
        orientation = "centre",
        operations = {
            {
                kind = directives.KMONS,
                argument = "AB : rat",
                line = 4,
            },
            {
                kind = directives.ITEM,
                argument = "stone q:4",
                line = 5,
            },
        },
    }
    local context = builder_context()
    local placed = placement.place(context, grid.new(context), source)
    local actors = 0
    local stack

    for _, record in ipairs(placed.records) do
        if record.kind == effects.MONSTER then
            actors = actors + 1
            harness.equal(record.arguments.kind_id, monsters.MONS_RAT,
                "authored monster stable ID")
            harness.equal(record.arguments.expression, "rat",
                "original expression retained")
        elseif record.kind == effects.ITEM and record.source == "d" then
            stack = record
        end
    end

    harness.equal(actors, 2, "keyed monster cells")
    harness.truthy(stack, "item cell missing")
    harness.equal(stack.arguments.kind_id, items.MI_STONE,
        "authored item stable ID")
    harness.equal(stack.arguments.quantity, 4,
        "authored item quantity")
end

-- The authored "nothing" monster is a typed no-spawn outcome, not pending work.
local function absence_is_resolved()
    local source = {
        id = "nothing_fixture",
        path = "vaults/arrival/nothing_fixture.des",
        rows = { "@1" },
        orientation = "centre",
        operations = {
            {
                kind = directives.MONS,
                argument = "nothing",
                line = 4,
            },
        },
    }
    local context = builder_context()
    local placed = placement.place(context, grid.new(context), source)

    for _, record in ipairs(placed.records) do
        if record.kind == effects.MONSTER then
            harness.falsy(record.pending, "nothing remains pending")
            harness.truthy(record.arguments.no_spawn,
                "nothing lacks typed no-spawn outcome")
        end
    end
end

    -- Two KMONS declarations on one glyph must fail after the first actor wins that cell.
local function source_slot_order_prevents_double_actor(ctx)
    local source = {
        id = "same_cell_fixture",
        path = "vaults/arrival/same_cell_fixture.des",
        rows = { "@1" },
        orientation = "centre",
        operations = {
            {
                kind = directives.KMONS,
                argument = "1 = rat",
                line = 4,
            },
            {
                kind = directives.KMONS,
                argument = "1 = plant",
                line = 5,
            },
        },
    }
    local builder = builder_context()
    local placed = placement.place(builder, grid.new(builder), source)
    local records = {}

    for _, record in ipairs(placed.records) do
        if record.kind == effects.MONSTER then
            record.index = #records + 1
            record.source_id = source.id
            records[#records + 1] = record
        end
    end

    local occupied
    local world = world_context(ctx)

    -- Resolve the first source choice so the overlap assertion tests placement order.
    function world:random()
        return 0
    end

    -- Keep the target open; collision with the prior actor is the intended failure.
    function world:walkable()
        return true
    end

    -- Report the first spawned actor to catch a second occupant in the same cell.
    function world:actor_at()
        return occupied
    end

    -- Persist the first actor's position and occupancy for the second declaration.
    function world:place_actor(actor, level_id, x, y)
        occupied = actor
        ctx:add(actor, component.POSITION, {
            level_id = level_id,
            x = x,
            y = y,
        })
    end

    local ok, reason = pcall(materializer.materialize, world, {
        id = 1,
        vault_records = records,
    })

    harness.falsy(ok, "two authored actors occupied one cell")
    harness.truthy(reason:find("two actors", 1, true),
        "overlap error lacks source rule")
    harness.equal(ctx:get(occupied, component.ACTOR).kind_id,
        monsters.MONS_RAT, "source slot order changed")
end

    -- An invalid MONS modifier must identify its DES path in the validation error.
local function invalid_declaration_has_source_site()
    local source = {
        id = "invalid_fixture",
        path = "vaults/arrival/invalid_fixture.des",
    }
    local operation = {
        kind = directives.MONS,
        argument = "rat bogus:3",
        line = 7,
    }
    local ok, reason = pcall(entity_specs.operation, source, operation)

    harness.falsy(ok, "invalid static source expression accepted")
    harness.truthy(reason:find(source.path, 1, true),
        "invalid expression lacks source path")
end

    -- Repeated Sigmund declarations should produce one actor and one typed no-spawn outcome.
local function source_unique_is_not_duplicated(ctx)
    local source = {
        id = "unique_fixture",
        path = "vaults/arrival/unique_fixture.des",
        rows = { "@12" },
        orientation = "centre",
        operations = {
            {
                kind = directives.KMONS,
                argument = "1 = Sigmund",
                line = 4,
            },
            {
                kind = directives.KMONS,
                argument = "2 = Sigmund",
                line = 5,
            },
        },
    }
    local builder = builder_context()
    local placed = placement.place(builder, grid.new(builder), source)
    local records = {}

    for _, record in ipairs(placed.records) do
        if record.kind == effects.MONSTER then
            record.index = #records + 1
            record.source_id = source.id
            records[#records + 1] = record
        end
    end

    local world = world_context(ctx)

    -- Choose the first unique candidate deterministically in the duplicate test.
    function world:random()
        return 0
    end

    -- Allow both cells so unique history, not terrain, suppresses the second spawn.
    function world:walkable()
        return true
    end

    -- Separate cells stay unoccupied; only unique history should veto duplication.
    function world:actor_at()
        return nil
    end

    -- Store each actor's real position for materialization and provenance checks.
    function world:place_actor(actor, level_id, x, y)
        ctx:add(actor, component.POSITION, {
            level_id = level_id,
            x = x,
            y = y,
        })
    end

    local actors, outcomes = materializer.materialize(world, {
        id = 1,
        vault_records = records,
    })

    harness.equal(actors, 1, "duplicate source unique spawned")
    harness.truthy(outcomes[2].no_spawn,
        "duplicate unique lacks typed no-spawn result")
end

-- A source comma list retries the same cell when an earlier unique cannot
-- spawn. Grum's kennel uses this to place an ordinary gnoll after Grum.
local function source_monster_slot_falls_back(ctx)
    local source = {
        id = "fallback_fixture",
        path = "vaults/serial/grums_kennel.des",
        rows = { "@12" },
        orientation = "centre",
        operations = {
            {
                kind = directives.KMONS,
                argument = "1 = Grum",
                line = 4,
            },
            {
                kind = directives.KMONS,
                argument = "2 = Grum, gnoll",
                line = 5,
            },
        },
    }
    local builder = builder_context()
    local placed = placement.place(builder, grid.new(builder), source)
    local records = {}

    for _, record in ipairs(placed.records) do
        if record.kind == effects.MONSTER then
            record.index = #records + 1
            record.source_id = source.id
            records[#records + 1] = record
        end
    end

    harness.equal(records[2].arguments.expression, "Grum, gnoll",
        "source fallback expression was lost")
    harness.equal(records[2].arguments.monster_slots, 2,
        "source fallback slot count was lost")

    local world = world_context(ctx)

    -- Both glyphs remain open; only the unique check triggers the fallback.
    function world:random()
        return 0
    end

    function world:walkable()
        return true
    end

    function world:actor_at()
        return nil
    end

    function world:place_actor(actor, level_id, x, y)
        ctx:add(actor, component.POSITION, {
            level_id = level_id,
            x = x,
            y = y,
        })
    end

    local actors, outcomes = materializer.materialize(world, {
        id = 1,
        vault_records = records,
    })

    harness.equal(actors, 2, "source fallback did not spawn")
    harness.falsy(outcomes[2].no_spawn, "fallback was marked absent")
    harness.equal(records[2].arguments.selected_expression, "gnoll",
        "source fallback selected the wrong slot")
    harness.equal(records[2].arguments.kind_id, monsters.MONS_GNOLL,
        "source fallback resolved the wrong monster")
end

-- Each cave-to-temple helper branch must resolve tenant monsters with provenance.
local function temple_helper_entities_resolve()
    local vault = catalog.get("erik_arrival_cave_to_civilisation")

    for branch = 0, 3 do
        local context = builder_context()
        local builder = grid.new(context)

    -- Force each temple helper branch while selecting the same outer vault path.
        function builder:roll(bound)
            if bound == 15 then
                return 14
            elseif bound == 9 then
                return branch
            end

            return 0
        end

        local placed = placement.place(context, builder, vault, {
            branch_id = branches.BRANCH_DUNGEON,
            depth = 1,
            branch_bottom = 15,
            layout_family = "open",
        })
        local count = 0

        for _, record in ipairs(placed.records) do
            if record.kind == effects.MONSTER and
                record.vault_id == "erik_arrival_cave_to_temple" then
                local arguments = record.arguments or {}

                harness.truthy(arguments.kind_id ~= nil,
                    "helper monster has no selected identity")
                harness.truthy(arguments.no_spawn or arguments.kind_id ~= "",
                    "helper monster remained unresolved")
                harness.truthy(arguments.path:find("erik_arrival_cave_to_temple", 1, true),
                    "helper entity lost its source path")

                count = count + 1
            end
        end

        harness.truthy(count > 0, "temple tenant branch has no monster records")
    end
end

    -- Cover typed resolution, no-spawn, overlap, diagnostics, uniques, and helper provenance.
function test.run(ctx)
    resolved_entity_records()
    absence_is_resolved()
    source_slot_order_prevents_double_actor(ctx)
    invalid_declaration_has_source_site()
    source_unique_is_not_duplicated(ctx)
    source_monster_slot_falls_back(ctx)
    temple_helper_entities_resolve()
end

return test
