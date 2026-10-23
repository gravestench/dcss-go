-- Source-position hooks translate Tomb's embedded DES Lua into the game's
-- normal vault API. These checks call the production module with a tiny
-- context so changes in guardian selection and conditional source effects
-- cannot silently change every authored Tomb floor.
local directives = require("constants.vault_directives")
local harness = require("tests.harness")
local hooks = require("policy.generation.tomb.source_hooks")

local test = {}

-- The source least-used rule shares counts only during one Tomb build.
-- Returning zero from each reservoir draw makes the expected order clear.
local function guardian_context()
    local counts = {
        0,
        0,
        0,
    }
    local emitted = {}
    local context = {}

    function context:setting(name)
        harness.equal(name, "guardian_counts")

        return counts
    end

    function context:roll()
        return 0
    end

    function context:emit(kind, value)
        harness.equal(kind, directives.MONS)
        emitted[#emitted + 1] = value
    end

    return context, counts, emitted
end

-- The source coinflip only inserts statue substitutions on its true arm.
-- Keeping these effects in the hook preserves the DES operation order.
local function statue_context(choice)
    local emitted = {}
    local context = {}

    function context:coinflip()
        return choice
    end

    function context:emit(kind, value)
        harness.equal(kind, directives.SUBST)
        emitted[#emitted + 1] = value
    end

    return context, emitted
end

-- Tomb's optional first-floor slot still uses the same balanced source
-- pool, while the deeper hook emits no empty-monster alternative.
function test.run()
    local context, counts, emitted = guardian_context()

    hooks.guardian_optional(context)
    hooks.guardian(context)
    hooks.guardian(context)

    harness.equal(#emitted, 3)
    harness.equal(counts[1], 1)
    harness.equal(counts[2], 1)
    harness.equal(counts[3], 1)
    harness.truthy(emitted[1]:find("nothing w:248", 1, true),
        "first-floor optional guardian remains optional")
    harness.equal(emitted[2]:find("nothing w:248", 1, true), nil,
        "deeper guardian does not inherit the optional slot")

    local false_context, false_effects = statue_context(false)
    local true_context, true_effects = statue_context(true)

    hooks.choose_statues(false_context)
    hooks.choose_statues(true_context)

    harness.equal(#false_effects, 0, "false coinflip leaves the map untouched")
    harness.equal(#true_effects, 4, "true coinflip preserves four substitutions")
end

return test
