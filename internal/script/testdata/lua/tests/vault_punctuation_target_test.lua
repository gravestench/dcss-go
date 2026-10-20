-- DES permits punctuation as a keyed map glyph. A comma glyph must be read
-- as the target of KPROP before commas are considered declaration separators.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local operations = require("policy.generation.vaults.operations")

local test = {}

-- This is the source shape used by Ru's path-of-blood overflow altar. The
-- property must stay attached to the comma cells, including across saves.
function test.run()
    local vault = {
        id = "punctuation_target",
        path = "vaults/altar/punctuation_target.des",
        operations = {
            {
                kind = directives.KPROP,
                argument = ", = bloody",
                line = 4,
            },
        },
    }
    local cells = {
        { ",", "." },
    }
    local records = operations.apply(vault, cells)

    harness.equal(#records, 1, "one keyed property")
    harness.equal(records[1].kind, effects.PROPERTY, "property record")
    harness.equal(records[1].targets, ",", "punctuation target")
    harness.equal(records[1].identity, "bloody", "property value")
end

return test
