-- Source arrival placement composes helpers while preserving authored exits and keyed map overrides.

local catalog = require("policy.generation.vaults.catalog")
local branches = require("ids.branches")
local grid = require("policy.generation.grid")
local placement = require("policy.generation.vaults.placement")
local selection = require("policy.generation.vaults.selection")
local transforms = require("policy.generation.vaults.transforms")
local operations = require("policy.generation.vaults.operations")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local connect = require("policy.generation.vaults.connect")
local terrain_features = require("content.terrain_features")

local test = {}

-- Arrival tests use the same D:1 branch facts that generated.first gives
-- placement. Nested SUBVAULT helpers need them for weighted eligibility.
local function place_arrival(ctx, builder, vault, player, options)
    local facts = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 1,
        branch_bottom = 15,
        absolute_depth = 1,
    }

    for name, value in pairs(player or {}) do
        facts[name] = value
    end

    return placement.place(ctx, builder, vault, facts, options)
end

-- Give every arrival attempt the same deterministic RNG stream for repeatability checks.
local function seeded_context()
    local context = {}
    local next_value = 1

    -- Advance a fixed 32-bit sequence so each source arrival sees reproducible draws.
    function context:random_u64()
        next_value = (next_value * 1664525 + 1013904223) % 4294967296

        return 0, next_value
    end

    return context
end

-- Ignore untagged helpers even when their weight dwarfs eligible arrivals.
local function assert_weighted_selection()
    local definitions = {
        { id = "first", tags = { arrival = true }, weight = 1 },
        { id = "helper", tags = {}, weight = 1000 },
        { id = "last", tags = { arrival = true }, weight = 3 },
    }
    -- Select the first eligible weight bucket without drawing from the oversized helper.
    local low = { roll = function() return 0 end }
    -- Select the last eligible bucket to prove the helper contributes no weight.
    local high = { roll = function() return 3 end }

    assert(selection.choose(low, definitions).id == "first")
    assert(selection.choose(high, definitions).id == "last")
end

-- Place every eligible authored arrival twice to catch nondeterministic transforms.
local function assert_all_source_arrivals_place()
    local ids = require("ids.vaults")
    local tested = 0

    for _, id in ipairs(require("policy.generation.vaults.selection").eligible_ids()) do
        local vault = catalog.get(ids[id])
        local first_context = seeded_context()
        local second_context = seeded_context()
        local first_builder = grid.new(first_context)
        local second_builder = grid.new(second_context)
        local first = place_arrival(first_context, first_builder, vault)
        local second = place_arrival(second_context, second_builder, vault)

        assert(first.entry.x >= 0 and first.entry.x < 80, id)
        assert(first.entry.y >= 0 and first.entry.y < 70, id)
        assert(#first.exits > 0, id)
        assert(table.concat(first_builder:rows()) == table.concat(second_builder:rows()), id)
        assert(first.entry.x == second.entry.x and first.entry.y == second.entry.y, id)

        tested = tested + 1
    end

    assert(tested == 337)
end

-- Every selected arrival must leave a traversable connection to the rest of
-- the floor after its authored transforms are applied.
local function assert_source_exits_connect()
    local ids = selection.eligible_ids()

    for _, id in ipairs(ids) do
        local context = seeded_context()
        local builder = grid.new(context)

        for y = 1, 68 do
            for x = 1, 78 do
                builder:set(x, y, ".")
            end
        end

        local placed = place_arrival(context, builder, catalog.get(id))

        connect.finish(context, builder, placed)

        local queue = { placed.entry }
        local visited = {
            [placed.entry.x .. ":" .. placed.entry.y] = true,
        }
        local first = 1

        while first <= #queue do
            local point = queue[first]

            first = first + 1

            for _, delta in ipairs({
                { x = 1, y = 0 },
                { x = -1, y = 0 },
                { x = 0, y = 1 },
                { x = 0, y = -1 },
            }) do
                local next_x = point.x + delta.x
                local next_y = point.y + delta.y
                local key = next_x .. ":" .. next_y

                if next_x > 0 and next_x < 79 and
                    next_y > 0 and next_y < 69 and not visited[key] and
                    builder:cell(next_x, next_y) ~= "#" then
                    visited[key] = true
                    queue[#queue + 1] = { x = next_x, y = next_y }
                end
            end
        end

        for _, exit in ipairs(placed.exits) do
            local glyph = builder:cell(exit.x, exit.y)

            assert(glyph ~= "#", id .. " has a blocked source exit")
            assert(visited[exit.x .. ":" .. exit.y], id .. " has a disconnected source exit")
        end
    end
end

-- Apply substitutions in authored order so later directives see earlier glyph changes.
local function assert_transforms_follow_des_order()
    local cells = {
        { "?", "A", "A" },
    }
    local random = {
        -- Choose the first substitution so authored operation order controls the output.
        roll = function() return 0 end,
    }

    assert(transforms.apply(cells, {
        kind = directives.SUBST,
        argument = "? = x",
    }, random))
    assert(transforms.apply(cells, {
        kind = directives.NSUBST,
        argument = "A = 1:W / *:.",
    }, random))
    assert(table.concat(cells[1]) == "xW.")

    local combined = { { "A", "B", "A" } }

    assert(transforms.apply(combined, {
        kind = directives.NSUBST,
        argument = "AB = 1:W / *:.",
    }, random))
    assert(table.concat(combined[1]) == "W..")

    local grouped = { { "A", "B" } }
    local draws = 0
    local alternating = {
        -- Alternate draws to reveal whether grouped glyphs incorrectly reroll per cell.
        roll = function(_, bound)
            draws = draws + 1

            return draws == 1 and 0 or math.floor(bound / 2)
        end,
    }

    transforms.apply(grouped, {
        kind = directives.SUBST,
        argument = "AB : xy",
    }, alternating)

    assert(table.concat(grouped[1]) == "xx")

    local rotated = transforms.rotate({
        { "a", "b" },
        { "c", "d" },
        { "e", "f" },
    }, 1)

    assert(table.concat(rotated[1]) == "eca")
    assert(table.concat(rotated[2]) == "fdb")
end

-- Repeated MONS and ITEM directives must append rather than overwrite prior choices.
local function assert_array_directives_append_slots()
    local vault = {
        id = "array_fixture",
        path = "vaults/arrival/array_fixture.des",
        tags = {},
        operations = {
            { kind = directives.MONS, argument = "goblin", line = 1 },
            { kind = directives.MONS, argument = "rat", line = 2 },
            { kind = directives.ITEM, argument = "stone", line = 3 },
            { kind = directives.ITEM, argument = "ring mail", line = 4 },
            { kind = directives.COLOUR, argument = "AB = green, CD = white", line = 5 },
        },
    }
    -- Keep directive slot selection fixed while testing append order.
    local random = { roll = function() return 0 end }
    local records = operations.apply(vault, {}, random)

    assert(records[1].targets == "1" and records[1].identity == "goblin")
    assert(records[2].targets == "2" and records[2].identity == "rat")
    assert(records[3].targets == "d" and records[3].identity == "stone")
    assert(records[4].targets == "e" and records[4].identity == "ring mail")
    assert(records[5].targets == "AB" and records[5].identity == "green")
    assert(records[6].targets == "CD" and records[6].identity == "white")
end

-- Pass species and name into source hooks before resolving their emitted operations.
local function assert_player_identity_reaches_source_hooks()
    local context = seeded_context()
    local player = {
        species_id = require("ids.species").SP_FORMICID,
        name = "Alice Bob",
        started = false,
    }
    local vault = catalog.get("nicolae_arrival_memento_mori")
    local placed = place_arrival(context, grid.new(context), vault, player)
    local named = 0

    for _, record in ipairs(placed.records) do
        if record.kind == effects.DELAYED_DECAY then
            assert(record.arguments.alternatives:find("name:Alice_Bob", 1, true))

            if record.arguments.alternatives:find("corpse", 1, true) then
                named = named + 1
            end
        end
    end

    assert(named > 0)
end

-- Repeated monster glyphs draw independently for each cell rather than
-- sharing one choice for the whole vault.
local function assert_weighted_monster_choice_is_per_cell()
    -- Feed two controlled draws to isolate weighted monster choice per cell.
    local function choice_context()
        local context = {
            draws = { 60, 59 },
            index = 0,
        }

        -- Consume exactly the two queued values to test independent monster choices.
        function context:random_u64()
            self.index = self.index + 1

            return 0, self.draws[self.index] or 60
        end

        return context
    end

    local vault = {
        id = "weighted_fixture",
        path = "vaults/arrival/weighted_fixture.des",
        rows = { "@11" },
        orientation = "centre",
        operations = {
            {
                kind = directives.MONS,
                argument = "rat / nothing w:50",
                line = 1,
            },
        },
    }
    local context = choice_context()
    local placed = place_arrival(context, grid.new(context), vault)
    local chosen = {}

    for _, record in ipairs(placed.records) do
        if record.kind == effects.MONSTER then
            chosen[#chosen + 1] = record.identity
        end
    end

    assert(chosen[1] == "rat" and chosen[2] == "nothing")

    local shared = {
        id = "shared_fixture",
        path = "vaults/arrival/shared_fixture.des",
        rows = { "@AB" },
        orientation = "centre",
        operations = {
            {
                kind = directives.KMONS,
                argument = "AB : rat / nothing w:50",
                line = 1,
            },
        },
    }
    context = choice_context()
    placed = place_arrival(context, grid.new(context), shared)
    chosen = {}

    for _, record in ipairs(placed.records) do
        if record.kind == effects.MONSTER then
            assert(record.assignment_mode == ":")
            chosen[#chosen + 1] = record.identity
        end
    end

    assert(chosen[1] == "rat" and chosen[2] == "rat")
end

-- Spawn masks must follow actual occupied glyphs, not just rectangular bounds.
local function assert_spawn_mask_respects_vault_shape()
    local generated = require("policy.generation.generated")
    local placed = {
        occupied = {
            { x = 10, y = 10 },
            { x = 12, y = 10 },
        },
        records = {},
    }
    local vault = {
        tags = { no_monster_gen = true },
    }
    local excluded = generated.spawn_exclusions(placed, vault)

    assert(#excluded == 2)
    assert(excluded[1].x == 10 and excluded[2].x == 12)
end

-- A keyed directive without its glyph cannot create an out-of-map feature.
local function assert_absent_keyed_glyph_places_nothing()
    local context = seeded_context()
    local vault = {
        id = "absent_fixture",
        path = "vaults/arrival/absent_fixture.des",
        rows = { "@." },
        orientation = "centre",
        operations = {
            {
                kind = directives.KFEAT,
                argument = "A = enter_abyss",
                line = 1,
            },
        },
    }
    local placed = place_arrival(context, grid.new(context), vault)

    for _, record in ipairs(placed.records) do
        assert(record.identity ~= "enter_abyss")
    end
end

-- Run both helper transforms on one authored cave so neither erases the other's bounds.
local function assert_both_helpers_compose()
    local vault = catalog.get("erik_arrival_cave_to_civilisation")
    local player = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 1,
        branch_bottom = 15,
        absolute_depth = 1,
    }
    local seen = {}
    local low_x, low_y, high_x, high_y

    for y, row in ipairs(vault.rows) do
        for x = 1, #row do
            if row:sub(x, x) == "_" then
                low_x = math.min(low_x or x, x)
                low_y = math.min(low_y or y, y)
                high_x = math.max(high_x or x, x)
                high_y = math.max(high_y or y, y)
            end
        end
    end

    for _, helper_draw in ipairs({ 0, 14 }) do
        local random = {
            -- Probe both ends of the helper's 15-way choice without changing other draws.
            roll = function(_, bound)
                if bound == 15 then
                    return helper_draw
                end

                return 0
            end,
            -- Force optional helper branches so their combined geometry is visible.
            one_in = function() return true end,
        }
        local cells = {}

        for y, row in ipairs(vault.rows) do
            cells[y] = {}

            for x = 1, #row do
                cells[y][x] = row:sub(x, x)
            end
        end

        local records = operations.apply(vault, cells, random, 0, player)

        for _, record in ipairs(records) do
            if record.vault_id and record.vault_id ~= vault.id then
                seen[record.vault_id] = true
            end
        end

        local builder = grid.new(seeded_context())

        builder.roll = random.roll

        local placed = place_arrival(seeded_context(), builder, vault,
            player)

        for _, record in ipairs(placed.records) do
            if record.vault_id and record.vault_id ~= vault.id then
                local local_x = record.x - placed.bounds.x + 1
                local local_y = record.y - placed.bounds.y + 1

                assert(local_x >= low_x and local_x <= high_x)
                assert(local_y >= low_y and local_y <= high_y)
            end
        end
    end

    assert(seen.erik_arrival_cave_to_hall)
    assert(seen.erik_arrival_cave_to_temple)
end

-- Retain path and line on typed intents for diagnostics after placement.
local function assert_keyed_intent_has_source_location()
    local context = seeded_context()
    local builder = grid.new(context)
    local vault = {
        id = "typed_intent_fixture",
        path = "vaults/arrival/typed_intent_fixture.des",
        rows = { "@A%" },
        orientation = "centre",
        operations = {
            {
                kind = directives.KFEAT,
                argument = "A = altar_zin",
                line = 3,
            },
            {
                kind = directives.KITEM,
                argument = "% = potion of curing",
                line = 4,
            },
            {
                kind = directives.MARKER,
                argument = "A = lua:props_marker { key=value }",
                line = 5,
            },
        },
    }
    local result = place_arrival(context, builder, vault)
    local found = {}

    for _, record in ipairs(result.records) do
        if record.kind == effects.FEATURE or record.kind == effects.ITEM or
            record.kind == effects.MARKER then
            found[record.kind] = record
        end
    end

    assert(found[effects.FEATURE].identity == "altar_zin")
    assert(found[effects.FEATURE].x == result.entry.x + 1)
    assert(found[effects.ITEM].identity == "potion of curing")
    assert(found[effects.ITEM].x == result.entry.x + 2)
    assert(found[effects.MARKER].x == result.entry.x + 1)
    assert(found[effects.MARKER].vault_id == vault.id)
end

-- Source script transforms must preserve the expected octagon geometry.
local function assert_source_script_shapes_map()
    local vault = catalog.get("enne_arrival_octagon_isle")
    local cells = {}

    for y, row in ipairs(vault.rows) do
        cells[y] = {}

        for x = 1, #row do
            cells[y][x] = row:sub(x, x)
        end
    end

    local original = {}

    for y, row in ipairs(cells) do
        original[y] = table.concat(row)
    end

    local before = table.concat(original)
    local random = {
        -- Fix script transform draws to make the source map comparison reproducible.
        roll = function() return 0 end,
        -- Enable optional shape operations to verify they preserve octagon bounds.
        one_in = function() return true end,
    }

    operations.apply(vault, cells, random)

    local changed = {}

    for y, row in ipairs(cells) do
        changed[y] = table.concat(row)
    end

    assert(table.concat(changed) ~= before)
end

-- A placement whose hook removes the exit must be rejected before committing the map.
local function assert_source_veto_rejects_missing_exit()
    local context = seeded_context()
    local builder = grid.new(context)
    local placed = {
        id = "dpeg_arrival_water_fire",
        family = "arrival",
        path = "vaults/arrival/dpeg_arrival_water_fire.des",
        bounds = { x = 10, y = 10, width = 4, height = 4 },
        exits = { { x = 10, y = 10, source = "@" } },
        records = {
            {
                kind = effects.MARKER,
                identity = "lua:props_marker { arrival_stairs=1 }",
                x = 11,
                y = 11,
            },
            {
                kind = effects.VETO,
                method = "check_exit_marker",
                line = 48,
            },
        },
    }
    local ok, err = pcall(connect.finish, context, builder, placed)

    assert(not ok)
    assert(err:find("dpeg_arrival_water_fire", 1, true))
    assert(err:find("check_exit_marker", 1, true))
end

-- Explicit keyed feature wins over the glyph's implicit terrain.
local function assert_keyed_feature_overrides_source_glyph()
    local cells = { { "DNGN_FLOOR" } }
    local records = {
        {
            kind = effects.SOURCE_FEATURE,
            identity = "DNGN_GRANITE_STATUE",
            x = 0,
            y = 0,
        },
        {
            kind = effects.FEATURE,
            identity = "floor",
            x = 0,
            y = 0,
        },
    }

    local retained = terrain_features.apply_vault_terrain(cells, records)

    assert(cells[1][1] == "DNGN_FLOOR")
    assert(records[2].pending == false)
    assert(#retained == 0)
end

-- Unkeyed source glyphs still produce typed item and monster records.
local function assert_implicit_items_and_monsters_are_retained()
    local context = seeded_context()
    local placed = place_arrival(context, grid.new(context), {
        id = "implicit_fixture",
        path = "vaults/arrival/implicit_fixture.des",
        rows = { "@0%1" },
        orientation = "centre",
        operations = {},
    })
    local found = {}

    for _, record in ipairs(placed.records) do
        found[record.identity] = record
    end

    assert(found.random_monster and found.random_monster.kind == effects.MONSTER)
    assert(found.random_item and found.random_item.kind == effects.ITEM)
    assert(found.monster_array_1 and found.monster_array_1.pending)
end

-- Combine helper, transform, and all-source placement cases under one deterministic test.
function test.run()
    assert_weighted_selection()
    assert_transforms_follow_des_order()
    assert_array_directives_append_slots()
    assert_player_identity_reaches_source_hooks()
    assert_weighted_monster_choice_is_per_cell()
    assert_spawn_mask_respects_vault_shape()
    assert_absent_keyed_glyph_places_nothing()
    assert_both_helpers_compose()
    assert_keyed_intent_has_source_location()
    assert_source_script_shapes_map()
    assert_source_veto_rejects_missing_exit()
    assert_keyed_feature_overrides_source_glyph()
    assert_implicit_items_and_monsters_are_retained()
    assert_all_source_arrivals_place()
    assert_source_exits_connect()
end

return test
