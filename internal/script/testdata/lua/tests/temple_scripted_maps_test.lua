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
local function run_map(id, altar_count)
    local definition = catalog.main(id)
    local emitted = {}
    local recorded = {}
    local api = {}
    local method

    harness.truthy(definition, id .. " is registered")

    for _, operation in ipairs(definition.operations) do
        if operation.kind == directives.HOOK_RUN then
            method = operation.argument
            break
        end
    end

    harness.truthy(method, id .. " has a named Lua hook")

    function api:setting(key)
        harness.equal(key, settings.ALTAR_COUNT,
            "Temple hooks read the saved plan setting")

        return altar_count
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

    hooks.run(definition, method, api)

    return emitted, recorded
end

-- Source map hooks retain the selected count and local environment. These
-- checks catch silently dropped Lua even while Temple travel is unfinished.
function test.run()
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
