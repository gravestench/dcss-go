-- The Bazaar is one source corpus: 13 entries and 42 one-floor layouts.
-- Every source NAME gets its own effective DES path, and hooks must resolve
-- before the rare Bazaar is selected during live play.
local des = require("policy.generation.vaults.des")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local catalog = require("policy.generation.vaults.catalog")
local grid = require("policy.generation.grid")
local placement = require("policy.generation.vaults.placement")
local extra = require("policy.generation.vaults.extra")
local branches = require("ids.branches")
local species = require("ids.species")
local effects = require("constants.vault_effects")
local shop_spec = require("policy.generation.vaults.shop_spec")
local terrain_features = require("content.terrain_features")
local terrain = require("constants.terrain")
local bazaar_level = require("policy.generation.bazaar.level")

local test = {}

-- Give each layout an independent deterministic source of bounded draws.
-- File enumeration must not consume a prior map's RNG state.
local function random_context()
    local state = 83
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- Place a selected source layout through the same whole-floor path that
-- a live Bazaar visit will use, including script emissions and shop cells.
local function place_layout(id)
    local builder = grid.new(random_context())

    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            builder:set(x, y, ".")
        end
    end

    local player = {
        branch_id = branches.BRANCH_BAZAAR,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 18,
    }
    local okay, result = pcall(placement.place, nil, builder,
        catalog.get(id), player, {
            whole_level = true,
        })

    harness.truthy(okay, id .. " whole-floor placement: " ..
        tostring(result))
    harness.truthy(result and #result.occupied > 0,
        id .. " placed no Bazaar cells")

    local shops = 0

    for _, record in ipairs(result.records) do
        if record.kind == effects.FEATURE and
            shop_spec.is_shop(record.identity) then
            -- Population uses this exact parser before it creates stock.
            -- Validate every authored alternative, not only one drawn
            -- shop, so a rare Bazaar cannot fail at its purchase screen.
            shop_spec.parse(record.identity, {
                path = catalog.get(id).path,
                vault_id = id,
                line = record.line,
            })

            shops = shops + 1
        end
    end

    harness.truthy(shops > 0, id .. " has no resolved shop feature")

    local cells = terrain_features.decode_source_rows(builder:rows())
    terrain_features.apply_vault_terrain(cells,
        result.records, random_context(), 1)
    local exit_found = false

    for _, row in ipairs(cells) do
        for _, cell in ipairs(row) do
            if cell == terrain.DNGN_EXIT_BAZAAR then
                exit_found = true
            end
        end
    end

    harness.truthy(exit_found, id .. " has no live Bazaar exit")
end

-- Every entrance must fit as an ordinary secondary map before the rare
-- serial shop controller can request it by tag. Crystal is Pan-only.
local function place_entry(id)
    local builder = grid.new(random_context())

    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            builder:set(x, y, ".")
        end
    end

    local branch_id = id == "bzr_crystal_pan" and
        branches.BRANCH_PANDEMONIUM or branches.BRANCH_DUNGEON
    local depth = branch_id == branches.BRANCH_DUNGEON and 15 or 1
    local placed, reason = extra.place(nil, builder, catalog.get(id), {
        protected = {},
        required = {},
        player = {
            branch_id = branch_id,
            depth = depth,
            absolute_depth = 18,
            branch_bottom = 15,
            map_tag = "bzr_entry",
        },
    })

    harness.truthy(placed,
        id .. " entrance placement: " .. tostring(reason))

    local portal = false
    local marker = false

    for _, record in ipairs(placed.records) do
        if record.kind == effects.FEATURE and
            record.identity == "enter_bazaar" then
            portal = true
        elseif record.kind == effects.MARKER and record.identity and
            (record.identity:find("timed_marker", 1, true) or
                record.identity:find("one_way_stair", 1, true)) then
            marker = true
        end
    end

    harness.truthy(portal, id .. " has no Bazaar portal feature")
    harness.truthy(marker, id .. " has no timed or permanent portal marker")
end

-- Pin all 54 authored MAP blocks without duplicating their geometry in a
-- test fixture. The final source map is procedural and has no MAP block.
local function source_map_digest(entries, layouts)
    local authored = {}

    for _, path in ipairs(entries) do
        local map = des.parse(path, mod.read(path))

        authored[#authored + 1] = map.id .. ":" ..
            table.concat(map.rows, "\n")
    end

    for _, path in ipairs(layouts) do
        local map = des.parse(path, mod.read(path))

        if #map.rows > 0 then
            authored[#authored + 1] = map.id .. ":" ..
                table.concat(map.rows, "\n")
        end
    end

    table.sort(authored)

    local hash = 0

    for byte in (table.concat(authored, "\n")):gmatch(".") do
        hash = (hash * 31 + string.byte(byte)) % 4294967296
    end

    harness.equal(#authored, 54, "source authored Bazaar MAP count")
    harness.equal(hash, 2550309660, "complete authored Bazaar MAP corpus")
end

-- The live floor generator must use the effective catalog, keep the
-- chosen source identity, and expose resolved shops and a usable exit.
local function generated_floor()
    local result = bazaar_level.generate(random_context(), {})
    local level = result.level

    harness.equal(level.branch_id, branches.BRANCH_BAZAAR,
        "generated Bazaar branch")
    harness.equal(level.local_depth, 1, "generated Bazaar depth")
    harness.equal(level.initial_monsters, 0, "no ambient Bazaar monsters")
    harness.equal(catalog.get(level.vault_id).family, "bazaar",
        "selected source layout")
    harness.equal(level.cells[level.entry_y + 1][level.entry_x + 1],
        terrain.DNGN_FLOOR, "Bazaar arrival floor")

    local exit_found = false
    local shop_found = false

    for _, row in ipairs(level.cells) do
        for _, cell in ipairs(row) do
            exit_found = exit_found or cell == terrain.DNGN_EXIT_BAZAAR
        end
    end

    for _, record in ipairs(level.vault_records) do
        if record.kind == effects.FEATURE and
            shop_spec.is_shop(record.identity) then
            shop_found = true
        end
    end

    harness.truthy(exit_found, "generated Bazaar has no exit")
    harness.truthy(shop_found, "generated Bazaar has no shop")
end

-- Source no_species_fe belongs to the weighted Bazaar pool, not only to
-- later vault placement. A Felid must never draw the armour/weapon market.
local function species_pool()
    local human = bazaar_level.candidates({
        species_id = species.SP_HUMAN,
    })
    local felid = bazaar_level.candidates({
        species_id = species.SP_FELID,
    })
    local human_has_map = false

    for _, candidate in ipairs(human) do
        human_has_map = human_has_map or
            candidate.id == "bazaar_minmay_armour_weapon"
    end

    harness.truthy(human_has_map, "Human Bazaar pool lost source market")

    for _, candidate in ipairs(felid) do
        harness.falsy(candidate.id == "bazaar_minmay_armour_weapon",
            "Felid Bazaar pool admitted source-excluded market")
    end
end

-- Parse and resolve every map through the same named-hook contract used
-- by the production vault catalog. Entry tags must exist before hooks run.
function test.run()
    local entries = mod.paths("vaults/bzr_entry", ".des")
    local layouts = mod.paths("vaults/bazaar", ".des")

    harness.equal(#entries, 13, "source Bazaar entries")
    harness.equal(#layouts, 42, "source Bazaar layouts")

    for _, path in ipairs(entries) do
        local map = des.parse(path, mod.read(path))

        harness.truthy(map.tags.bzr_entry,
            map.id .. " is selectable before its hook runs")
        hooks.validate(map)
        place_entry(map.id)
    end

    for _, path in ipairs(layouts) do
        local map = des.parse(path, mod.read(path))

        harness.truthy(map.tags.no_monster_gen,
            map.id .. " excludes ordinary monster population")
        hooks.validate(map)
        place_layout(map.id)
    end

    source_map_digest(entries, layouts)
    species_pool()
    generated_floor()
end

return test
