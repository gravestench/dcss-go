-- These tests call the named production hooks through the DES resolver.
-- They check the source branch choices without copying handler functions.
local directives = require("constants.vault_directives")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Supply only the documented vault facts a hook may read. Explicit choices
-- make alternate script paths visible without depending on unrelated RNG.
local function run(id, facts)
    local emitted = {}
    local api = {}

    function api:emit(kind, argument)
        emitted[#emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    function api:depth()
        return facts.depth or 2
    end

    function api:branch_bottom()
        return 4
    end

    function api:absolute_depth()
        return facts.absolute_depth or 16
    end

    function api:depth_fraction()
        return self:depth() / self:branch_bottom()
    end

    function api:chance(numerator, denominator)
        harness.equal(numerator, 4 - self:depth(),
            id .. " chance uses remaining Snake depth")
        harness.equal(denominator, 4,
            id .. " chance uses the source branch bottom")

        return facts.chance
    end

    function api:one_in(bound)
        harness.equal(bound, facts.one_in_bound,
            id .. " uses its source one-in draw")

        return facts.one_in
    end

    function api:coinflip()
        return facts.coinflip
    end

    hooks.run(vaults.get(id), "configure", api)

    return emitted
end

-- The two pillar maps harden only on the source remaining-depth chance.
local function check_pillars()
    for _, id in ipairs({
        "hangedman_snake_thin_pillar_pass",
        "hangedman_snake_wide_pillar_pass",
    }) do
        local hardened = run(id, { depth = 1, chance = true })
        local open = run(id, { depth = 4, chance = false })

        harness.equal(#hardened, 1, id .. " hardening count")
        harness.equal(hardened[1].kind, directives.SUBST,
            id .. " hardening directive")
        harness.equal(hardened[1].argument, "c = x",
            id .. " hardening substitution")
        harness.equal(#open, 0, id .. " bottom-floor shape")
    end
end

-- Swirl and crossing change only placeholder glyph sets; the DES owns
-- every unconditional substitution and the authored map geometry.
local function check_depth_palettes()
    local swirl = "nicolae_large_snake_swirl"
    local crossing = "nicolae_snake_crotalidae_crossing"
    local depths = { 1, 2, 4 }
    local swirl_choices = { "s = ]})", "s = ]})[{(", "s = [{(" }
    local crossing_choices = { "S = )}]", "S = (){}[]", "S = ({[" }

    for index, depth in ipairs(depths) do
        local selected_swirl = run(swirl, { depth = depth })
        local selected_crossing = run(crossing, { depth = depth })

        harness.equal(selected_swirl[1].argument, swirl_choices[index],
            "swirl source depth palette")
        harness.equal(selected_crossing[1].argument,
            crossing_choices[index], "crossing source depth palette")
    end
end

-- Conditional hallways and squiggles preserve the source draw sequence.
local function check_random_shapes()
    local hallway = "nicolae_snake_yet_another_twisty_hallway"
    local squiggle = "nicolae_snake_gridmaze_squiggle"
    local inverted = run(hallway, {
        one_in_bound = 5,
        one_in = true,
    })
    local unchanged = run(hallway, {
        one_in_bound = 5,
        one_in = false,
    })

    harness.equal(inverted[1].argument,
        "x = -, . = x, @- = .", "hallway optional inversion")
    harness.equal(#unchanged, 0, "hallway ordinary shape")

    local choices = {
        { one_in = true, expected = "DHK = x, EFJ = ." },
        { one_in = false, coinflip = true, expected = "EHJ = x, DFK = ." },
        { one_in = false, coinflip = false, expected = "FJK = x, DEH = ." },
    }

    for _, choice in ipairs(choices) do
        choice.one_in_bound = 3

        local selected = run(squiggle, choice)

        harness.equal(#selected, 1, "squiggle chooses one source path")
        harness.equal(selected[1].argument, choice.expected,
            "squiggle source substitution")
    end
end

-- Aizul tests absolute depth, whereas salamander guards use local depth.
-- Keep the two keyed declarations together so neither tier mixes rosters.
local function check_monster_tiers()
    local aizul = "nicolae_aizul_guard"
    local salamanders = "nicolae_snake_salamander_stairs"
    local deep = run(aizul, { absolute_depth = 15 })
    local shallow = run(aizul, { absolute_depth = 14 })

    harness.equal(#deep, 2, "deep Aizul guard has two slots")
    harness.equal(deep[1].argument,
        "D = patrolling Aizul, patrolling nagaraja",
        "deep Aizul escort")
    harness.equal(shallow[1].argument,
        "D = patrolling Aizul, patrolling guardian serpent",
        "shallow Aizul escort")

    local first = run(salamanders, { depth = 1 })
    local second = run(salamanders, { depth = 2 })
    local deeper = run(salamanders, { depth = 3 })

    harness.equal(#first, 2, "Snake:1 salamander slots")
    harness.equal(#second, 2, "Snake:2 salamander slots")
    harness.equal(#deeper, 2, "deeper salamander slots")
    harness.equal(first[1].argument,
        "1 = salamander mystic / salamander tyrant w:5",
        "Snake:1 first guard")
    harness.equal(second[2].argument,
        "2 = salamander / salamander mystic w:2 / nothing w:50",
        "Snake:2 second guard")
    harness.equal(deeper[1].argument,
        "1 = salamander tyrant", "deeper first guard")
end

-- Run all eight source script sites and each meaningful conditional arm.
function test.run()
    check_pillars()
    check_depth_palettes()
    check_random_shapes()
    check_monster_tiers()
end

return test
