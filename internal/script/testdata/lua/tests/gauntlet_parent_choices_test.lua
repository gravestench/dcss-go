-- Conditional parent hooks decide a branch once, then pass that tier to
-- every arena on that branch. Their choices must not leak across runs.
local directives = require("constants.vault_directives")
local gauntlet = require("constants.gauntlet")
local harness = require("tests.harness")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Capture the production hook's emitted operations without duplicating
-- its transporter, prize, or encounter implementation in this fixture.
local function compose(id, outcome)
    local emitted = {}
    local api = {}

    function api:emit(kind, argument, settings)
        emitted[#emitted + 1] = {
            kind = kind,
            argument = argument,
            settings = settings,
        }
    end

    function api:record()
        -- The source random-monster list is not a SUBVAULT choice.
    end

    function api:coinflip()
        return outcome
    end

    function api:has_placed_tag()
        -- The real placement test verifies this only after the first
        -- hook's queued arenas have been applied to the parent map.
        return true
    end

    local hook = require("policy.generation.vaults.gauntlet." .. id)

    if hook.opening then
        hook.opening(api)
        hook.finish(api)
    else
        hook.compose(api)
    end

    local arenas = {}

    for _, operation in ipairs(emitted) do
        if operation.kind == directives.SUBVAULT then
            local glyph, tag = operation.argument:match(
                "^(%S+)%s*:%s*(%S+)$")

            arenas[glyph] = {
                tag = tag,
                settings = operation.settings,
            }
        end
    end

    return arenas
end

-- Two source-position hooks let the operation engine apply the opening
-- SUBVAULTs before the conditional hook spends its coin-flip draw.
local function check_conditional_order(id)
    local definition = vaults.get(id)
    local hooks = {}

    for _, operation in ipairs(definition.operations) do
        if operation.kind == directives.HOOK_RUN then
            hooks[#hooks + 1] = operation.argument
        end
    end

    harness.equal(hooks[1], id .. ".opening",
        id .. " must place opening arenas first")
    harness.equal(hooks[2], id .. ".finish",
        id .. " must draw after opening arenas")
end

-- Exercise both sides of every tier coin flip, including the compact
-- 7x7 variant. A repeated first outcome catches shared module state.
function test.run()
    local cases = {
        {
            id = "gammafunk_gauntlet_branching",
            glyph = "e",
            first = gauntlet.FIRST_TIER_TAG,
            second = gauntlet.SECOND_TIER_TAG,
        },

        {
            id = "gammafunk_gauntlet_hard_choice",
            glyph = "q",
            first = gauntlet.FIRST_TIER_TAG,
            second = gauntlet.SECOND_TIER_TAG,
        },

        {
            id = "gammafunk_gauntlet_mixed_choke_point",
            glyph = "r",
            first = gauntlet.SECOND_TIER_TAG,
            second = gauntlet.FIRST_TIER_TAG,
        },

        {
            id = "gammafunk_gauntlet_77_escape_option",
            glyph = "q",
            first = gauntlet.FIRST_TIER_77_TAG,
            second = gauntlet.SECOND_TIER_77_TAG,
        },
    }

    for _, case in ipairs(cases) do
        check_conditional_order(case.id)

        local first = compose(case.id, true)
        local second = compose(case.id, false)
        local repeated = compose(case.id, true)

        harness.equal(first[case.glyph].tag, case.first,
            case.id .. " true branch tier")
        harness.equal(second[case.glyph].tag, case.second,
            case.id .. " false branch tier")
        harness.equal(repeated[case.glyph].tag, case.first,
            case.id .. " leaked a previous tier")
    end

    local shortcut = compose("gammafunk_gauntlet_shortcut", true)

    harness.truthy(shortcut.a.settings.extra_items ~=
        shortcut.e.settings.extra_items,
        "shortcut prize setting leaked between route segments")
end

return test
