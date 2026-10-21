-- The complete Orc source family enters the same effective catalog used by
-- live generation. Counts pin the category boundary before any selector can
-- hide a missing source map behind an unrelated candidate.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local entry = require("policy.generation.vaults.branch_entry")
local endings = require("policy.generation.vaults.end")
local effects = require("constants.vault_effects")
local extra = require("policy.generation.vaults.extra")
local features = require("constants.vault_features")
local families = require("constants.vault_families")
local grid = require("policy.generation.grid")
local generated = require("policy.generation.generated")
local garden_settings = require("constants.orc_gardens")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local saved_vaults = require("policy.save.vaults")
local shop_spec = require("policy.generation.vaults.shop_spec")
local tags = require("constants.vault_tags")
local used = require("policy.generation.vaults.used")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Give every source map the same reproducible layout stream while driving
-- the production placement owner, including substitutions and hooks.
local function random_context()
    local value = 71
    local context = {}

    function context:random_u64()
        value = (value * 48271) % 2147483647
        local high = value

        value = (value * 48271) % 2147483647

        return high, value
    end

    return context
end

-- Catalog validation cannot catch a bad substituted glyph or source
-- declaration. Place every actual MAP through the normal runtime path.
local function place_all_maps()
    local placed_count = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)
        local family = definition.family

        if (family == families.ORC_ENTRY or family == families.ORC or
            family == families.ORC_END) and #definition.rows > 0 and
            not definition.tags.dummy then
            local is_entry = family == families.ORC_ENTRY
            local player = {
                branch_id = is_entry and branches.BRANCH_DUNGEON or
                    branches.BRANCH_ORC,
                depth = is_entry and 10 or 2,
                branch_bottom = is_entry and 15 or 2,
                absolute_depth = is_entry and 10 or 11,
                branch_entries = {},
            }
            local builder = grid.new(random_context())
            local okay, map = pcall(placement.place, nil, builder,
                definition, player)

            harness.truthy(okay, id .. " placement: " .. tostring(map))
            harness.truthy(map and #map.occupied > 0,
                id .. " placed no authored cells")
            placed_count = placed_count + 1
        end
    end

    harness.equal(placed_count, 75,
        "all non-dummy source Orc MAPs place")
end

-- Eighteen non-dummy gates must retain exactly one keyed Orc stair after
-- source substitutions. The weighted one-cell dummy deliberately relies
-- on the generation owner's lone-stair fallback instead of map placement.
local function entry_contract()
    local count = 0

    for _, choice in ipairs(entry.candidates(branches.BRANCH_ORC)) do
        local definition = vaults.get(choice.definition.id)

        if definition.id ~= "orc_0_dummy" then
            local builder = grid.new(random_context())
            local player = {
                branch_id = branches.BRANCH_DUNGEON,
                depth = 10,
                branch_bottom = 15,
                absolute_depth = 10,
            }
            local map = placement.place(nil, builder, definition, player)
            local stairs = 0

            for _, record in ipairs(map.records) do
                if record.kind == effects.FEATURE and
                    record.identity == features.ENTER_ORC then
                    stairs = stairs + 1
                end
            end

            harness.equal(stairs, 1,
                definition.id .. " keyed Orc stair")
            count = count + 1
        end
    end

    harness.equal(count, 18, "all non-dummy Orc gates place")
end

-- Open terrain isolates the ending fitter from an unrelated layout draw.
-- The real end stage still handles orientation, composition, and records.
local function plain_floor()
    local ctx = random_context()
    local builder = grid.new(ctx)

    for y = 1, 68 do
        for x = 1, 78 do
            builder:set(x, y, ".")
        end
    end

    return ctx, builder
end

-- Every source Orc:2 primary, including the mapless gardens controller,
-- must complete its own children through the production end owner.
local function place_all_endings()
    local total = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == families.ORC_END then
            local ctx, builder = plain_floor()
            local player = {
                branch_id = branches.BRANCH_ORC,
                depth = 2,
                branch_bottom = 2,
                absolute_depth = 11,
                branch_entries = {},
            }
            local context = {
                branch_id = player.branch_id,
                depth = player.depth,
                branch_bottom = player.branch_bottom,
                absolute_depth = player.absolute_depth,
                end_vault_family = families.ORC_END,
                end_choice = { id = id },
                protected = {},
                required = {},
                player = player,
                used = used.new({}),
            }
            local placed = {}
            local okay, selected = pcall(endings.place, ctx, builder,
                context, placed, extra.place)

            harness.truthy(okay, id .. " ending: " .. tostring(selected))
            harness.equal(selected, id, "selected ending keeps its ID")

            if id == "grunt_orc_gardens" then
                harness.equal(#placed, 4, "four source garden helpers")

                local shops = {}
                local bosses = 0

                for _, map in ipairs(placed) do
                    harness.equal(map.id, "grunt_orc_garden",
                        "gardens use their tagged source helper")

                    for _, record in ipairs(map.records) do
                        if record.kind == effects.FEATURE then
                            shops[record.identity] = true
                        elseif record.kind == effects.MONSTER and
                            (record.identity == "orc warlord" or
                                record.identity == "stone giant") then
                            bosses = bosses + 1
                        end
                    end
                end

                for _, shop in ipairs(garden_settings.SHOPS) do
                    harness.truthy(shops[shop],
                        "garden retains distinct source shop " .. shop)
                end

                harness.equal(bosses, 1, "one source boss garden")
            elseif id == "grunt_orc_community_town_hall" then
                harness.truthy(#placed >= 7 and #placed <= 9,
                    "town hall and source house counts")

                local first_draw = grid.new(random_context())
                local source_small_count = 4 + first_draw:roll(3)

                harness.equal(placed[1].hook_values.small_house_count,
                    source_small_count,
                    "community house draw precedes map substitutions")

                local big = 0
                local small = 0

                for _, map in ipairs(placed) do
                    local child = vaults.get(map.id)

                    if child.tags[tags.ORC_BIG_HOUSE] then
                        big = big + 1
                    elseif child.tags[tags.ORC_HOUSE] then
                        small = small + 1
                    end
                end

                harness.equal(big, 2, "two source big houses")
                harness.equal(small, source_small_count,
                    "small houses use the pre-place draw")
            else
                harness.equal(#placed, 1, "ordinary ending adds one map")
            end

            total = total + 1
        end
    end

    harness.equal(total, 16, "all source Orc:2 endings complete")
end

-- A source keyed Elf gate takes over the one scheduled branch link. The
-- provisional lone stair must disappear or two Elf entrances would exist.
local function authored_elf_link()
    local builder = grid.new(random_context())
    local protected = {
        ["10:10"] = true,
    }
    local links = {
        {
            x = 10,
            y = 10,
            target_branch_id = branches.BRANCH_ELF,
        },
    }
    local maps = {
        {
            records = {
                {
                    kind = effects.FEATURE,
                    identity = features.ENTER_ELF,
                    x = 20,
                    y = 20,
                },
            },
        },
    }

    builder:set(10, 10, ">")
    builder:set(20, 20, ".")
    generated.bind_authored_branch_links(builder, links, maps, protected)

    harness.equal(builder:cell(10, 10), ".", "provisional gate cleared")
    harness.equal(builder:cell(20, 20), ">", "authored gate opens")
    harness.equal(links[1].x, 20, "link moves to authored x")
    harness.equal(links[1].y, 20, "link moves to authored y")
    harness.falsy(protected["10:10"], "old gate is no longer protected")
    harness.truthy(protected["20:20"], "authored gate is protected")
end

-- A complete Orc:2 ending must fit even when the scheduled Elf entrance
-- starts inside its fixed footprint. The final link belongs to its keyed p.
local function pubby_full_floor_link()
    local ctx, builder = plain_floor()
    local link = {
        x = 40,
        y = 35,
        target_branch_id = branches.BRANCH_ELF,
    }
    local protected = {
        ["40:35"] = true,
    }
    local player = {
        branch_id = branches.BRANCH_ORC,
        depth = 2,
        branch_bottom = 2,
        absolute_depth = 11,
        branch_entries = {
            [branches.BRANCH_ELF] = true,
        },
    }
    local context = {
        branch_id = player.branch_id,
        depth = player.depth,
        branch_bottom = player.branch_bottom,
        absolute_depth = player.absolute_depth,
        end_vault_family = families.ORC_END,
        end_choice = { id = "pubby_orc_utopia" },
        protected = protected,
        required = {},
        provisional_links = { link },
        player = player,
        used = used.new({}),
    }
    local placed = {}

    builder:set(link.x, link.y, ">")

    local selected = endings.place(ctx, builder, context, placed, extra.place)

    harness.equal(selected, "pubby_orc_utopia", "Utopia fits full Orc:2")
    generated.bind_authored_branch_links(builder, { link }, placed,
        protected)

    local gate

    for _, record in ipairs(placed[1].records) do
        if record.kind == effects.FEATURE and
            record.identity == features.ENTER_ELF then
            gate = record
        end
    end

    harness.truthy(gate, "Utopia creates its scheduled Elf gate")
    harness.equal(link.x, gate.x, "Elf link uses authored x")
    harness.equal(link.y, gate.y, "Elf link uses authored y")
    harness.equal(builder:cell(gate.x, gate.y), ">",
        "authored gate is a live stair")
end

-- The source Utopia hook emits its single keyed Elf gate only when the
-- current Orc floor owns that scheduled branch entry.
local function pubby_gate_choice()
    local definition = vaults.get("pubby_orc_utopia")

    for _, scheduled in ipairs({ false, true }) do
        local builder = grid.new(random_context())
        local player = {
            branch_id = branches.BRANCH_ORC,
            depth = 2,
            branch_bottom = 2,
            absolute_depth = 11,
            branch_entries = scheduled and {
                [branches.BRANCH_ELF] = true,
            } or {},
        }
        local map = placement.place(nil, builder, definition, player)
        local gates = 0

        for _, record in ipairs(map.records) do
            if record.kind == effects.FEATURE and
                record.identity == features.ENTER_ELF then
                gates = gates + 1
            end
        end

        harness.equal(gates, scheduled and 1 or 0,
            "Utopia gate follows saved Elf schedule")
    end
end

-- Restore checks actual child families and multiplicities, not merely the
-- selected primary ID. Helper names may repeat because source permits it.
local function saved_controller_children()
    local context = {}

    function context:query()
        return {}
    end

    local level = {
        id = "Orc:2",
        branch_id = branches.BRANCH_ORC,
        local_depth = 2,
        vault_id = "grunt_orc_gardens",
        vault_ids = {
            "grunt_orc_gardens",
            "grunt_orc_garden",
        },
        vault_records = {},
    }
    local input = {
        levels = { level },
    }

    harness.falsy(pcall(saved_vaults.validate, context, input),
        "garden ending with one child cannot restore")

    for _ = 1, 3 do
        level.vault_ids[#level.vault_ids + 1] = "grunt_orc_garden"
    end

    harness.truthy(pcall(saved_vaults.validate, context, input),
        "garden ending with four children restores")

    level.vault_ids[5] = "mines_dummy"

    harness.falsy(pcall(saved_vaults.validate, context, input),
        "an unrelated Orc map cannot stand in for a garden")

    level.vault_id = "grunt_orc_community_town_hall"
    level.vault_ids = {
        "grunt_orc_community_town_hall",
        "grunt_orc_community_big_house_1",
        "grunt_orc_community_big_house_2",
        "grunt_orc_community_house_1",
    }

    harness.falsy(pcall(saved_vaults.validate, context, input),
        "town hall without four small houses cannot restore")

    for _ = 1, 3 do
        level.vault_ids[#level.vault_ids + 1] =
            "grunt_orc_community_house_2"
    end

    harness.truthy(pcall(saved_vaults.validate, context, input),
        "complete town hall restores")
end

-- One source Orc gate puts a shop or ordinary floor at the same keyed
-- position. The non-shop alternative must consume its selection weight
-- without creating a shop entity.
local function optional_entry_shop()
    local site = {
        path = "vaults/orc_entry/orc_david_3.des",
        vault_id = "orc_david_3",
        line = 0,
    }
    local alternatives = shop_spec.parse("armour shop / .", site)
    local random = {}

    function random:roll(bound)
        return bound - 1
    end

    harness.equal(#alternatives, 2, "source optional shop alternatives")
    harness.falsy(shop_spec.choose(random, alternatives).kind_id,
        "dot alternative creates no shop")
end

-- An authored gate, ordinary map, and ending must all resolve by family;
-- source file order is irrelevant to these counts and candidate pools.
function test.run()
    vaults.load()

    local counts = {
        [families.ORC_ENTRY] = 0,
        [families.ORC] = 0,
        [families.ORC_END] = 0,
    }

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if counts[definition.family] then
            counts[definition.family] = counts[definition.family] + 1
        end
    end

    harness.equal(counts[families.ORC_ENTRY], 19,
        "all source Orc entrances are registered")
    harness.equal(counts[families.ORC], 42,
        "all source ordinary Orc maps are registered")
    harness.equal(counts[families.ORC_END], 16,
        "all source Orc endings are registered")
    harness.equal(#entry.candidates(branches.BRANCH_ORC), 19,
        "all source Orc entrances are selectable")

    local end_context = {
        branch_id = branches.BRANCH_ORC,
        depth = 2,
        branch_bottom = 2,
        absolute_depth = 11,
        end_vault_family = families.ORC_END,
    }

    harness.equal(#endings.candidates(end_context), 16,
        "all source Orc:2 endings are selectable")
    place_all_maps()
    entry_contract()
    place_all_endings()
    authored_elf_link()
    pubby_full_floor_link()
    pubby_gate_choice()
    saved_controller_children()
    optional_entry_shop()
end

return test
