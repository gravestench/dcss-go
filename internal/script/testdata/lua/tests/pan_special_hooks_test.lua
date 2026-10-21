-- These source maps choose substitutions before their remaining static
-- directives run. Test the named production hooks at probability edges.
local directives = require("constants.vault_directives")
local harness = require("tests.harness")
local glyphs = require(
    "policy.generation.vaults.pan.nicolae_pan_strange_glyphs")
local gloorx = require(
    "policy.generation.vaults.pan.nicolae_pan_gloorx_vloqian_3")

local test = {}

-- A fixture supplies exactly one requested draw and rejects extra or
-- misbounded draws that would change later map generation for one seed.
local function run(method, expected_bound, draw)
    local emissions = {}
    local rolls = 0
    local api = {}

    function api:roll(bound)
        harness.equal(bound, expected_bound, "source draw bound")

        rolls = rolls + 1

        return draw
    end

    function api:coinflip()
        harness.equal(expected_bound, 2, "source coinflip bound")

        rolls = rolls + 1

        return draw == 0
    end

    function api:emit(kind, argument)
        harness.equal(kind, directives.SUBST,
            "conditional source hook emits a substitution")

        emissions[#emissions + 1] = argument
    end

    method(api)

    harness.equal(rolls, 1, "one source decision per hook call")

    return emissions
end

-- One 0..14 draw chooses how many glyph pairs the source suppresses.
-- Gloorx uses two independent coinflips at separate source positions.
function test.run()
    local all = run(glyphs.choose_count, 15, 0)
    local none = run(glyphs.choose_count, 15, 14)
    local three = run(glyphs.choose_count, 15, 7)
    local first_true = run(gloorx.first_pair, 2, 0)
    local first_false = run(gloorx.first_pair, 2, 1)
    local second_true = run(gloorx.second_pair, 2, 0)

    harness.equal(#all, 4, "lowest draw suppresses four extra pairs")
    harness.equal(all[1], "Ee = _", "highest pair goes first")
    harness.equal(all[4], "Bb = _", "lowest pair goes last")
    harness.equal(#none, 0, "highest draw preserves every glyph pair")
    harness.equal(#three, 2, "middle draw suppresses two pairs")
    harness.equal(#first_true, 1, "first Gloorx branch emits when true")
    harness.equal(first_true[1], "d = a, e = b, h = f, i = g",
        "first Gloorx branch maps four shuffled cells")
    harness.equal(#first_false, 0, "first Gloorx branch can be skipped")
    harness.equal(second_true[1], "f = b, g = a",
        "second Gloorx branch maps the remaining cells")
end

return test
