-- Altar names come from the shared god IDs and one production presentation
-- policy. A source B glyph is generic and does not itself identify a god.
local gods = require("constants.gods")
local harness = require("tests.harness")
local view = require("policy.presentation.view")

local test = {}

-- Check the special article in a source god name and reject invented IDs so
-- mods cannot silently label an altar for a nonexistent deity.
function test.run()
    local named = view.altar(nil, { god_id = gods.SHINING_ONE })

    harness.equal(named.name, "an altar of the Shining One",
        "altar names use the shared pantheon display name")
    harness.equal(named.glyph, string.byte("_"),
        "DCSS ASCII altars use the underscore glyph")

    local okay = pcall(view.altar, nil, { god_id = "GOD_MISSING" })

    harness.falsy(okay, "unknown altar god ID was displayed")
end

return test
