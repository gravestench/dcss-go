-- Exercise the source controller decisions through the production Lua
-- handlers. These tests supply only controlled random and placement APIs;
-- they import the same tags, item parser, and validator used by gameplay.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local items = require("ids.items")
local item_specs = require("policy.generation.vaults.specs.item")
local finale = require("policy.generation.vaults.shoals_end.finale")
local shared = require("policy.generation.vaults.shoals_end.shared")
local tags = require("constants.vault_tags")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Capture the real rune hook's directive without restating its item syntax.
local function rune_directive(tag)
    local emitted = {}
    local api = {}

    function api:map_tag()
        return tag
    end

    function api:emit(kind, argument)
        emitted[#emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    shared.rune_o(api)

    return emitted[1]
end

-- The same item kind is visible for both huts, but only the false hut's
-- parsed request carries the mimic flag into its saved placement record.
local function check_rune_requests()
    local real = rune_directive(tags.SHOAL_RUNE_SIMPLE)
    local false_rune = rune_directive(tags.SHOAL_MIMIC_SIMPLE)
    local site = { path = "shoals test", line = 1, id = "shoalhut_rune" }
    local real_term = real.argument:match("^[^=]+=%s*(.*)$")
    local false_term = false_rune.argument:match("^[^=]+=%s*(.*)$")
    local real_item = item_specs.term(real_term, site)
    local false_item = item_specs.term(false_term, site)

    harness.equal(real.kind, directives.KITEM, "real rune directive")
    harness.equal(false_rune.kind, directives.KITEM,
        "false rune directive")
    harness.equal(real_item.name, false_item.name,
        "both huts display the same item kind")
    harness.truthy(not real_item.mimic, "real rune can be collected")
    harness.truthy(false_item.mimic, "false rune has a mimic marker")
end

-- Force both optional source branches and check the child request order.
-- A false rune reduces the ordinary hut count by two.
local function check_controller()
    local requests = {}
    local draws = 0
    local api = {}

    function api:random_range(first, last)
        harness.equal(first, 6, "simple minimum decoys")
        harness.equal(last, 7, "simple maximum decoys")

        return first
    end

    function api:one_in(bound)
        draws = draws + 1
        harness.equal(bound, draws == 1 and 5 or 10,
            "guardian draw precedes mimic draw")

        return true
    end

    function api:place_maps(tag, count)
        requests[#requests + 1] = {
            tag = tag,
            count = count,
        }

        return count
    end

    finale.assemble(api, {
        rune = tags.SHOAL_RUNE_SIMPLE,
        mimic = tags.SHOAL_MIMIC_SIMPLE,
        hut = tags.SHOAL_HUT_SIMPLE,
        minimum = 6,
        maximum = 7,
    })

    harness.equal(#requests, 4, "rune, guardian, mimic, decoys")
    harness.equal(requests[1].tag, tags.SHOAL_RUNE_SIMPLE,
        "real rune first")
    harness.equal(requests[2].tag, tags.SHOAL_GUARDIAN,
        "optional guardian second")
    harness.equal(requests[3].tag, tags.SHOAL_MIMIC_SIMPLE,
        "optional false rune third")
    harness.equal(requests[4].count, 4,
        "false rune replaces two ordinary huts")
end

-- Generation and save validation must agree on a real helper owner and
-- reject an unrelated source record even if a matching helper is listed.
local function check_owner()
    vaults.load()

    local theme = { rune = tags.SHOAL_RUNE_SIMPLE }
    local result = {
        vault_ids = { "shoalhut_rune" },
        records = {
            {
                kind = effects.ITEM,
                vault_id = "shoalhut_rune",
                arguments = { kind_id = items.RUNE_SHOALS },
            },
        },
    }

    harness.truthy(finale.require_rune(result, theme),
        "selected child owns the real rune")

    result.records[1].vault_id = "shoals_garden_rune"

    local okay = pcall(finale.require_rune, result, theme)

    harness.truthy(not okay, "another theme cannot own this rune")
end

-- Keep the hook choices and ownership invariant in one source-linked test.
function test.run()
    check_rune_requests()
    check_controller()
    check_owner()
end

return test
