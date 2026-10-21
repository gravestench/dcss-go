-- The holy Pan map changes its O prize after the demonic rune is found.
-- Both source branches must not remain active in the parsed DES definition.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local harness = require("tests.harness")
local runes = require("constants.runes")
local holy = require("policy.generation.vaults.pan.evilmike_holy_pan")

local test = {}

-- Capture the production hook result with one explicit player rune fact.
local function capture(method, has_demonic)
    local events = {}
    local api = {}

    function api:has_rune(id)
        harness.equal(id, runes.DEMONIC, "holy Pan checks the demonic rune")

        return has_demonic
    end

    function api:emit(kind, argument)
        events[#events + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    function api:record(kind, arguments)
        events[#events + 1] = {
            kind = kind,
            arguments = arguments,
        }
    end

    method(api)

    return events
end

-- A first visit offers the rune and warning; later visits get an exit.
function test.run()
    local first = capture(holy.rune_or_exit, false)
    local later = capture(holy.rune_or_exit, true)
    local names = capture(holy.feature_names, false)
    local population = capture(holy.population, false)
    local warning = capture(holy.epilogue, false)
    local no_warning = capture(holy.epilogue, true)

    harness.equal(#first, 1, "first visit chooses one O outcome")
    harness.equal(first[1].kind, directives.KITEM,
        "first visit leaves the real rune")
    harness.equal(first[1].argument, "O = demonic rune of Zot",
        "first visit keeps source item spelling")
    harness.equal(#later, 1, "later visit chooses one O outcome")
    harness.equal(later[1].kind, directives.KFEAT,
        "later visit opens an exit")
    harness.equal(later[1].argument, "O = exit_pandemonium",
        "later visit keeps the source exit")
    harness.equal(#names, 2, "two holy features receive source names")
    harness.equal(names[1].kind, effects.FEATURE_NAME,
        "feature name survives as typed data")
    harness.equal(names[1].arguments.feature, features.GRANITE_STATUE,
        "the golden statue labels granite terrain")
    harness.equal(population[1].kind, effects.GENERATION_RULE,
        "holy map changes the whole region's monster list")
    harness.equal(warning[1].kind, effects.ENTRY_MESSAGE,
        "unclaimed holy rune announces its presence")
    harness.equal(#no_warning, 0,
        "collected holy rune does not announce again")
end

return test
