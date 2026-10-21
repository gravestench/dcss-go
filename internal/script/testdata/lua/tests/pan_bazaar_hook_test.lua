-- The bazaar script assigns one generated shopkeeper name across its
-- keyed shops and changes the central offer after the demonic rune.
local directives = require("constants.vault_directives")
local harness = require("tests.harness")
local runes = require("constants.runes")
local bazaar = require(
    "policy.generation.vaults.pan.nicolae_pan_bazaar_rune")

local test = {}

-- Fix the two source choices while retaining the production hook and
-- its source-ordered KFEAT emissions.
local function configure(has_demonic)
    local events = {}
    local api = {}

    function api:random_name()
        return "Ash Herald"
    end

    function api:random_from(values)
        harness.truthy(#values > 1, "source suffix pool is missing")

        return values[1]
    end

    function api:has_rune(id)
        harness.equal(id, runes.DEMONIC, "bazaar checks the demonic rune")

        return has_demonic
    end

    function api:validating()
        return false
    end

    function api:emit(kind, argument)
        events[#events + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    bazaar.configure(api)

    return events
end

-- Nine keyed shop requests share the owner; only the central Z request
-- switches between a rune deal and ordinary rarities.
function test.run()
    local first = configure(false)
    local later = configure(true)

    harness.equal(#first, 10, "bazaar emits one lord and nine shops")
    harness.equal(first[1].kind, directives.KMONS,
        "bazaar owner is a keyed Pan lord")
    harness.equal(first[1].argument,
        "Z = pandemonium lord name:Ash_Herald",
        "source spaces become safe DES name separators")
    harness.truthy(first[2].argument:find("Demonic_Rune", 1, true),
        "unclaimed rune is offered for sale")
    harness.truthy(first[2].argument:find("demonic rune of Zot", 1, true),
        "central stock contains the real rune")
    harness.truthy(later[2].argument:find("Rarities", 1, true),
        "collected rune changes the central shop")
    harness.falsy(later[2].argument:find("Demonic_Rune", 1, true),
        "collected rune cannot be sold a second time")
    harness.equal(later[10].kind, directives.KFEAT,
        "last Infernal boutique remains a shop feature")
end

return test
