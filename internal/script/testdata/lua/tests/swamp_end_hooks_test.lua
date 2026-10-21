-- The four source Lua sites now live in named modules. Exercise both
-- conditional outcomes without restating their DES declarations here.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local standard = require("policy.generation.vaults.swamp_end.swamp")
local alternative = require("policy.generation.vaults.swamp_end.swamp_alternative")
local basic = require("policy.generation.vaults.swamp_end.swamp_basic_johnstein")
local byrel = require(
    "policy.generation.vaults.swamp_end.byrel_swamp_growth_death_and_undeath")

local test = {}

-- Capture the production handler's typed operations under one chosen
-- source probability result, so a test never redeclares its rule text.
local function run_choice(method, rare)
    local emitted = {}
    local api = {}

    function api:one_in(bound)
        harness.equal(bound, 11, "source unique-guardian chance")

        return rare
    end

    function api:emit(kind, argument)
        emitted[#emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    method(api)

    return emitted
end

-- Both standard endings vary one substitution; the basic ending varies
-- its entire monster and prize branch. Byrel records item decay instead.
function test.run()
    local standard_rare = run_choice(standard.rare_lernaean_hydra, true)
    local standard_common = run_choice(standard.rare_lernaean_hydra, false)
    local alternative_rare = run_choice(
        alternative.rare_lernaean_hydra, true)
    local alternative_common = run_choice(
        alternative.rare_lernaean_hydra, false)
    local basic_rare = run_choice(basic.choose_guardians, true)
    local basic_common = run_choice(basic.choose_guardians, false)

    harness.equal(#standard_rare, 1, "standard rare substitution")
    harness.equal(standard_rare[1].kind, directives.SUBST,
        "standard substitutes source guardian")
    harness.equal(#standard_common, 0, "standard common declarations remain")
    harness.equal(#alternative_rare, 1, "alternative rare substitution")
    harness.equal(alternative_rare[1].kind, directives.SUBST,
        "alternative substitutes source guardian")
    harness.equal(#alternative_common, 0,
        "alternative common declarations remain")
    harness.equal(#basic_rare, 1, "basic rare guardian")
    harness.equal(basic_rare[1].kind, directives.KMONS,
        "basic rare guardian is keyed")
    harness.equal(#basic_common, 2, "basic common guard and prize")
    harness.equal(basic_common[1].kind, directives.KMONS,
        "basic common guardians are keyed")
    harness.equal(basic_common[2].kind, directives.KITEM,
        "basic common prize is keyed")

    local recorded = {}
    local api = {}

    function api:record(kind, arguments)
        recorded[#recorded + 1] = {
            kind = kind,
            arguments = arguments,
        }
    end

    byrel.schedule_hydra_corpse(api)

    harness.equal(#recorded, 1, "byrel corpse intent")
    harness.equal(recorded[1].kind, effects.DELAYED_DECAY,
        "byrel uses existing decay resolver")
    harness.equal(recorded[1].arguments.alternatives, "hydra corpse",
        "source hydra species")
end

return test
