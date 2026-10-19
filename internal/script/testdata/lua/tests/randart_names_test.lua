local catalog = require("policy.catalog")
local harness = require("tests.harness")
local name_catalog = require("policy.item_generation.artefacts.name_catalog")
local names = require("policy.item_generation.artefacts.names")
local items = require("ids.items")
local streams = require("constants.rng_streams")
local markers = require("constants.randart_name_markers")
local groups = require("constants.randart_name_groups")

local test = {}

-- Pick the first weighted row at every nested database level.
local function first_draw()
    return 0
end

-- The imported source groups are individual definitions, so adding or
-- replacing a phrase group does not depend on Lua file loading order.
local function all_source_groups_are_available()
    harness.equal(#catalog.all("randart_names"), 182,
        "five source name databases register every unique key")

    local group = catalog.get("randart_names", groups.WEAPON)

    harness.equal(group.entries[1].weight, 10,
        "source default weight retained")
    harness.equal(group.entries[1].text, "of @_power_or_anger_@",
        "source phrase retained")
end

-- A deterministic boundary draw follows weighted groups and recursively
-- replaces database markers before a phrase reaches item naming.
local function weighted_source_phrases_expand()
    harness.equal(name_catalog.draw(first_draw, groups.WEAPON, {}),
        "of Big Damage", "nested weapon name expands")
    harness.equal(name_catalog.draw(first_draw, "ring appearance", {}),
        "scintillating wooden", "ring appearance expands")
end

-- The first Okawaru row delegates to the ordinary weapon pool. Selecting
-- the following row instead proves weighted boundaries and player markers.
local function weighted_boundary_resolves_player_name()
    local calls = 0

    -- Choose the row immediately after the 400-weight ordinary fallback,
    -- then choose the first valour phrase inside that source group.
    local function boundary(bound)
        calls = calls + 1

        if calls == 1 then
            harness.truthy(bound > 400, "weighted group includes gift rows")
            return 400
        end

        return 0
    end

    local phrase = name_catalog.draw(boundary, "okawaru weapon", {
        [markers.PLAYER_NAME] = "Nyx",
    })

    harness.truthy(phrase:find("Nyx's", 1, true) ~= nil,
        "source player marker uses the supplied name")
    harness.falsy(phrase:find("@", 1, true),
        "nested source marker is fully expanded")
end

-- An item seed confines cosmetic draws to the item. The same seed and
-- effective catalog yield the same true name and hidden appearance.
local function equipment_names_use_saved_seed()
    local ctx = {
        draws = 0,
    }

    -- Count outer item-seed draws without constraining the local cosmetic
    -- generator's choices in either true names or appearances.
    function ctx:random(stream, bound)
        harness.equal(stream, streams.ITEM_GENERATION,
            "one item-generation stream supplies the cosmetic seed")
        harness.truthy(bound > 0, "name seed bound")
        self.draws = self.draws + 1

        return 12345
    end

    local weapon = catalog.get("items", items.WPN_DAGGER)
    local first, first_appearance, seed = names.generate(ctx, weapon)
    local second, second_appearance = names.generate(ctx, weapon)

    harness.equal(ctx.draws, 2, "two weapon names request two outer seeds")
    harness.equal(seed, 12345, "saved cosmetic seed")
    harness.equal(first, second, "true name repeats from saved seed")
    harness.equal(first_appearance, second_appearance,
        "hidden appearance repeats from saved seed")
    harness.falsy(first_appearance:find("@", 1, true),
        "appearance has no unresolved source markers")

    -- Each class reaches a source appearance group without revealing the
    -- subtype of jewellery whose ordinary identification is still unknown.
    local shapes = {
        [items.ARM_ROBE] = "robe",
        [items.ARM_CLOAK] = "cloak",
        [items.RING_PROTECTION] = "ring",
        [items.AMU_REFLECTION] = "amulet",
    }

    for id, shape in pairs(shapes) do
        local before = ctx.draws
        local _, hidden, item_seed = names.generate(ctx,
            catalog.get("items", id))

        harness.equal(item_seed, 12345,
            "saved cosmetic seed for " .. id)
        harness.equal(ctx.draws, before + 1,
            "outer seed draw for " .. id)

        harness.truthy(hidden:match(" " .. shape .. "$") ~= nil,
            "source appearance keeps " .. shape .. " shape")
        harness.falsy(hidden:find("non-descript", 1, true),
            "source appearance replaces generic fallback")
    end

    harness.equal(ctx.draws, 6,
        "one outer draw per generated item name")
end

-- Exercise import, expansion, and seeded naming as one catalog contract.
function test.run()
    all_source_groups_are_available()
    weighted_source_phrases_expand()
    weighted_boundary_resolves_player_name()
    equipment_names_use_saved_seed()
end

return test
