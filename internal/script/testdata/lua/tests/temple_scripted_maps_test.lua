-- Execute Temple scripts through the parsed DES hook reference. The fake
-- emitter only records policy output; production schemas and IDs are read
-- from the same modules the game uses.
local catalog = require("policy.generation.temple.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local fill = require("constants.vault_border_fill")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local settings = require("constants.temple_settings")

local test = {}

-- Read the actual named hook from DES so a renamed map method cannot leave
-- this test exercising a stale direct function import.
local function run_map(id, altar_count, rolls)
    local definition = catalog.main(id)
    local emitted = {}
    local recorded = {}
    local api = {}
    local roll_index = 0

    harness.truthy(definition, id .. " is registered")

    function api:setting(key)
        harness.equal(key, settings.ALTAR_COUNT,
            "Temple hooks read the saved plan setting")

        return altar_count
    end

    function api:roll(bound)
        roll_index = roll_index + 1

        local result = rolls and rolls[roll_index] or 0

        harness.truthy(result < bound,
            id .. " source draw fits its upper bound")

        return result
    end

    function api:emit(kind, argument)
        emitted[#emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    function api:record(kind, arguments)
        recorded[#recorded + 1] = {
            kind = kind,
            arguments = arguments,
        }
    end

    local ran = 0

    for _, operation in ipairs(definition.operations) do
        if operation.kind == directives.HOOK_RUN then
            hooks.run(definition, operation.argument, api)
            ran = ran + 1
        end
    end

    harness.truthy(ran > 0, id .. " has a named Lua hook")

    return emitted, recorded
end

-- Source map hooks retain the selected count and local environment. These
-- checks catch silently dropped Lua even while Temple travel is unfinished.
function test.run()
    -- Every scripted source map must execute at least its first legal
    -- arrangement. The targeted checks below cover alternate branches.
    for _, id in ipairs(catalog.main_ids()) do
        local definition = catalog.main(id)
        local has_hook = false
        local first_count

        for _, operation in ipairs(definition.operations) do
            if operation.kind == directives.HOOK_RUN then
                has_hook = true
            end
        end

        for tag in pairs(definition.tags) do
            local number = tag:match("^temple_altars_(%d+)$")
            local candidate

            if number then
                candidate = tonumber(number)
            end

            if candidate and (not first_count or candidate < first_count) then
                first_count = candidate
            end
        end

        if has_hook then
            run_map(id, first_count)
        end
    end

    local circle = run_map("compressed_dpeg_circular_temple", 10,
        { 29 })

    harness.equal(circle[1].argument,
        "C = B, E = G, DH<IJ = .",
        "the circular Temple opens its ten-altar ring")
    harness.equal(circle[#circle].argument, "c = red",
        "the last centre draw creates the lava colour")

    local star = run_map("hc_temple_tempest_star", 12, { 1 })

    harness.equal(star[2].kind, directives.SHUFFLE,
        "the outer-star alternative shuffles its inner points")

    local panitentiary = run_map("nicolae_temple_panitentiary", 12,
        { 5 })

    harness.equal(panitentiary[1].argument,
        "PSps = B, QRqr = U, Zz = .",
        "the high die result chooses the third twelve-altar variant")

    local ruined, ruined_records = run_map("ebering_the_none_and_only")

    harness.equal(#ruined, 0,
        "the abandoned Temple adds no dynamic DES directives")
    harness.equal(ruined_records[3].kind, effects.ENTRY_MESSAGE,
        "the source epilogue survives as a typed entry message")

    local little = run_map("nicolae_temple_little_seven", nil, { 1 })

    harness.equal(little[1].argument,
        "DEF = x, HM = G, JL = ., K = B",
        "the second little-seven layout is reachable")

    local sunken, sunken_records = run_map("chequers_temple_sunken", 9)

    harness.equal(sunken[1].argument,
        "O = 9:B / 1:O.... / *:.",
        "sunken altars use the saved count")
    harness.equal(sunken_records[1].kind, effects.BORDER_FILL,
        "sunken Temple retains its sea border")

    local colour = run_map("nicolae_temple_colour_theory", nil, { 4 })

    harness.equal(colour[1].argument, "p' = floor_pebble_lightred",
        "a palette choice drives matching source floor tiles")
    harness.equal(colour[6].argument, "Rr = brown",
        "the final region uses the same palette")

    local chambers = run_map("dpeg_chambers_temple", 10)

    harness.equal(#chambers, 2,
        "ten-altar chambers shuffle before substituting")
    harness.equal(chambers[1].kind, directives.SHUFFLE,
        "the chamber shuffle keeps its source order")
    harness.equal(chambers[2].argument, "CD = B, '\" = ., EF-~ = v",
        "ten-altar chambers preserve their source walls")

    local forest = run_map("hellmonk_temple_forest_ring", 8)

    harness.equal(#forest, 2,
        "eight-altar forest emits both source substitutions")
    harness.equal(forest[2].argument, "+DFH = c",
        "forest closes unused altar sites")

    local sept = run_map("nicolae_temple_great_sept", 14)

    harness.equal(sept[1].argument, "L = ., MN = !, O = B",
        "the great sept uses its default altar arrangement")

    local sea, sea_records = run_map("jpeg_temple_island")

    harness.equal(#sea, 0, "island emits no terrain substitution")
    harness.equal(sea_records[1].kind, effects.BORDER_FILL,
        "island records its level border")
    harness.equal(sea_records[1].arguments.style, fill.OPEN_SEA,
        "island surrounds its map with sea")

    local vapour = run_map("minmay_freezing_vapour_temple", 15)

    harness.equal(vapour[1].kind, directives.NSUBST,
        "variable Temple count uses source NSUBST")
    harness.equal(vapour[1].argument, "B = 15:B / *:'",
        "selected count reaches the authored map")

    local divided = run_map("hellmonk_temple_divided_pantheon", 19)

    harness.equal(#divided, 2,
        "both pantheon halves receive source substitutions")
    harness.equal(divided[1].argument, "D = 9:B / *:'",
        "dark half gets nine altars")
    harness.equal(divided[2].argument, "E = 9:B / *:-",
        "light half gets nine altars")

    local invalid, reason = pcall(run_map,
        "minmay_freezing_vapour_temple", nil)

    harness.falsy(invalid, "a missing Temple plan cannot choose a count")
    harness.truthy(reason:find("selected altar count", 1, true),
        "a missing plan reports its Temple cause")
end

return test
