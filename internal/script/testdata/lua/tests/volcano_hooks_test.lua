-- Exercise production source hooks through the same emit/record API used
-- by DES placement. Assertions cover source choices, not a copied schema.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")

local test = {}

-- Capture emitted directives and source rolls without predeclaring the
-- production map's item, monster, or marker definitions in this fixture.
local function run_hook(handler, draw)
    local emitted = {}
    local records = {}
    local rolls = 0
    local api = {}

    -- A zero draw reaches the minimum of each source range.
    function api:roll(bound)
        rolls = rolls + 1
        harness.truthy(draw < bound, "invalid source draw")

        return draw
    end

    -- The production placement API receives these same directive calls.
    function api:emit(kind, argument)
        emitted[#emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    -- Feature names and timed effects remain typed source records.
    function api:record(kind, arguments)
        records[#records + 1] = {
            kind = kind,
            arguments = arguments,
        }
    end

    handler(api)

    return emitted, records, rolls
end

-- The portal hook draws exactly one 600–800-turn clock, then emits the
-- entrance feature at the same source position as the original call.
local function check_portal()
    local shared = require("policy.generation.vaults.volcano_entry.shared")
    local low, _, low_rolls = run_hook(shared.portal, 0)
    local high, _, high_rolls = run_hook(shared.portal, 200)

    harness.equal(low_rolls, 1, "Volcano entrance minimum draw")
    harness.equal(high_rolls, 1, "Volcano entrance maximum draw")
    harness.equal(low[1].kind, directives.MARKER,
        "entrance owns a timed marker")
    harness.truthy(low[1].argument:find("low = 600", 1, true),
        "minimum source clock")
    harness.truthy(high[1].argument:find("low = 800", 1, true),
        "maximum source clock")
    harness.equal(low[2].argument, "O = enter_volcano",
        "Volcano arch follows its marker")
end

-- Shared setup must keep reward requests and both return glyphs at the
-- authored site, with the blocked tunnel description as a typed record.
local function check_setup()
    local shared = require("policy.generation.vaults.volcano.shared")
    local emitted, records, rolls = run_hook(shared.setup, 0)
    local item_count = 0
    local exits = {}

    for _, operation in ipairs(emitted) do
        if operation.kind == directives.ITEM then
            item_count = item_count + 1
        elseif operation.kind == directives.KFEAT and
            operation.argument:find("exit_volcano", 1, true) then
            exits[#exits + 1] = operation.argument
        end
    end

    harness.equal(rolls, 0, "setup defers item choices")
    harness.equal(item_count, 4, "four source loot pools")
    harness.equal(exits[1], "< = exit_volcano", "first return glyph")
    harness.equal(exits[2], "I = exit_volcano", "second return glyph")
    harness.equal(records[1].kind, effects.FEATURE_NAME,
        "blocked tunnel name remains typed")
end

-- Chained and tiny volcanoes use distinct source fog sizes and delays.
-- The chained marker retains its group identity for one shared clock.
local function check_fog()
    local shared = require("policy.generation.vaults.volcano.shared")
    local tiny = run_hook(shared.fog_tiny, 0)
    local chained = run_hook(shared.fog_chained, 0)

    harness.equal(tiny[2].kind, directives.MARKER,
        "tiny Volcano marker")
    harness.truthy(tiny[2].argument:find("size = 40", 1, true),
        "tiny source size")
    harness.truthy(chained[2].argument:find("size = 100", 1, true),
        "chained source size")
    harness.truthy(chained[2].argument:find("chain =", 1, true),
        "chained fog keeps one group")
end

-- The three focused hook contracts guard the source options that would
-- otherwise turn a beautiful map into an inert or unreachable floor.
function test.run()
    check_portal()
    check_setup()
    check_fog()
end

return test
