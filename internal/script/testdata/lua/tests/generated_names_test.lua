-- Generated names use the source's one phonetic rule for ordinary, scroll,
-- and Jiyva modes, with spelling draws confined to a local PCG stream.
local harness = require("tests.harness")
local modes = require("constants.name_modes")
local seeds = require("constants.name_seeds")
local names = require("policy.names.source")
local artefact_names = require(
    "policy.item_generation.artefacts.names")
local classes = require("ids.object_classes")

local test = {}

-- The first saved source scroll label is a known output for game seed zero
-- and the pinned scroll class byte. A fixed file from the source binary
-- serves as the independent oracle for this one mode and seed.
function test.run(ctx)
    local ordinary = names.from_seed(ctx, 54, modes.ORDINARY)
    local repeated = names.from_seed(ctx, 54, modes.ORDINARY)
    local scroll = names.from_seed(ctx, 54, modes.SCROLL)
    local jiyva = names.from_seed(ctx, 54, modes.JIYVA)

    harness.equal(ordinary, repeated,
        "a name seed must replay without spending caller RNG")
    harness.truthy(ordinary:match("^[A-Z][a-z ]+$"))
    harness.truthy(scroll:match("^[A-Z ]+$"))
    harness.truthy(#scroll > #ordinary,
        "scroll mode should request a longer source name")
    harness.truthy(jiyva:match("^J[a-z]+$"))
    harness.truthy(#jiyva <= 8)
    local source_scroll_names = {
        "REFUMOPNEI",
        "ZIJUNKAOMIOW",
        "SALOHEKHLOMEO",
        "FUBAMNUNAH",
        "XETUISHRIB",
        "NEGGUG FEOGOELAU",
        "ZUOBAI LEME",
        "EHAKAE IV SEA",
    }

    for index, expected in ipairs(source_scroll_names) do
        local source_seed = seeds.SCROLL_CLASS * seeds.CLASS_BYTE +
            (index - 1) * seeds.SECOND_BYTE

        harness.equal(names.from_seed(ctx, source_seed, modes.SCROLL),
            expected, "source scroll name " .. index)
    end

    -- The source's seeded name stress test draws its first Jiyva seed
    -- from the gameplay PCG after rng::seed(27), with game seed zero.
    harness.equal(names.from_seed(ctx, 0x7c836570, modes.JIYVA),
        "Jeedwoon", "first source Jiyva name")
    harness.equal(names.from_seed(ctx, 0x4fa7d730, modes.JIYVA),
        "Juwkohi", "second source Jiyva name")
    harness.equal(names.from_seed(ctx, 0x43a8ef41, modes.JIYVA),
        "Jutygit", "third source Jiyva name")

    -- A catalog-less artefact reaches direct source make_name. The first
    -- caller draw names the item; the second seeds that fallback word.
    local item_context = setmetatable({ draws = 0 }, { __index = ctx })

    function item_context:random()
        self.draws = self.draws + 1

        if self.draws == 1 then
            return 12345
        end

        return 54321
    end

    local generated = artefact_names.generate(item_context, {
        class = classes.OBJ_MISCELLANY,
        name = "trinket",
    })
    local source_word = names.from_seed(ctx, 54321, modes.ORDINARY)

    harness.truthy(generated:find(source_word, 1, true),
        "artefact fallback bypassed the source name owner")
    harness.equal(item_context.draws, 2,
        "fallback word needs its own saved item-generation draw")
end

return test
