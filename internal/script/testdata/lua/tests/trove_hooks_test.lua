-- Run the same named source hooks as DES placement with a small capturing
-- API. The fixture observes decisions and never redeclares content schemas.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")

local test = {}

-- A fresh API exposes source choices and records their ordered effects.
local function capture(draw, depth)
    local api = {
        emitted = {},
        records = {},
    }

    -- Record directive order because hooks run at their DES source sites.
    function api:emit(kind, argument)
        self.emitted[#self.emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    -- Capture typed effects that later population will materialize.
    function api:record(kind, arguments)
        self.records[#self.records + 1] = {
            kind = kind,
            arguments = arguments,
        }
    end

    -- Force both garden substitutions without another hook implementation.
    function api:coinflip()
        return draw == 1
    end

    -- Guarded entrances change their source effects with absolute depth.
    function api:absolute_depth()
        return depth
    end

    return api
end

-- Source gate setup leaves a typed price witness to fill on population;
-- it must not invent a price before the real player state is available.
local function check_entry()
    local shared = require("policy.generation.vaults.trove_entry.shared")
    local low = capture(0, 14)

    shared.portal(low)

    harness.equal(low.records[1].kind, effects.MARKER,
        "source Trove toll marker")
    harness.equal(low.records[1].arguments.glyph, "O",
        "toll source glyph")
    harness.equal(low.records[1].arguments.price, "",
        "price awaits population")
    harness.equal(low.emitted[1].argument, "O = enter_trove",
        "source entry arch")

    local guardians = require(
        "policy.generation.vaults.trove_entry.enter_trove_5")
    local shallow = capture(0, 15)
    local deep = capture(0, 16)

    guardians.guardians(shallow)
    guardians.guardians(deep)

    harness.truthy(shallow.emitted[1].argument:find(
        "vault guard", 1, true), "shallow guarded entry")
    harness.truthy(deep.emitted[1].argument:find(
        "vault guard", 1, true), "deep guarded entry")
    harness.truthy(#deep.emitted > #shallow.emitted,
        "deep source entry has extra colour and tile requests")
end

-- Shared setup and the two special map hooks keep their source effects
-- at the same directive positions as their DES calls.
local function check_destinations()
    local shared = require("policy.generation.vaults.trove.shared")
    local garden = require("policy.generation.vaults.trove.trove_garden")
    local base = capture(0, 18)

    shared.setup(base)
    shared.good_scroll(base)
    shared.blue_smoke(base)
    shared.open_sea(base)
    shared.endless_salt(base)
    shared.ruined_idol(base)

    harness.equal(base.emitted[1].argument, "< = exit_trove",
        "source return arch")
    harness.equal(base.emitted[2].kind, directives.ITEM,
        "authored scroll pool")
    harness.equal(base.records[1].kind, effects.MARKER,
        "source garden fog machine")
    harness.equal(base.records[2].kind, effects.BORDER_FILL,
        "source sea border")
    harness.equal(base.records[3].kind, effects.BORDER_FILL,
        "source salt border")
    harness.equal(base.records[4].kind, effects.FEATURE_NAME,
        "ruined idol name")

    local natural = capture(1, 18)
    local randomized = capture(0, 18)

    garden.plants(natural)
    garden.plants(randomized)

    harness.equal(natural.emitted[1].kind, directives.SUBST,
        "first garden branch starts with substitution")
    harness.truthy(#randomized.emitted > #natural.emitted,
        "second garden branch preserves extra source directives")
end

-- Source vetoes depend on the live character, while the map test harness
-- supplies ranks and deterministic draws without redefining skill schemas.
local function check_vetoes()
    local shared = require("policy.generation.vaults.trove.shared")
    local api = {
        started = true,
        weapon = 2,
        spell = 8,
        unarmed = 0,
        evocations = 1,
        device_disabled = false,
        draw = 1,
    }

    -- Preview placement cannot apply the live character veto.
    function api:game_started()
        return self.started
    end

    -- Provide the source weapon-school average to the real veto hook.
    function api:weapon_skills()
        return self.weapon
    end

    -- Provide the source magic-school average to the real veto hook.
    function api:spell_skills()
        return self.spell
    end

    -- Unarmed training affects whether a weapon room is useful.
    function api:unarmed_skill()
        return self.unarmed
    end

    -- Device rooms reject a character with little Evocations training.
    function api:evocations_skill()
        return self.evocations
    end

    -- No-artifice blocks devices regardless of skill.
    function api:cannot_use_devices()
        return self.device_disabled
    end

    -- Trigger the source one-in-three veto exception deterministically.
    function api:roll()
        return self.draw
    end

    harness.truthy(shared.weapon_eligible(api),
        "spell specialist vetoes common weapon room")
    harness.falsy(shared.library_eligible(api),
        "spell specialist accepts library")
    harness.truthy(shared.misc_eligible(api),
        "low Evocations vetoes common device room")

    api.draw = 0
    harness.falsy(shared.weapon_eligible(api),
        "one-in-three source exception admits weapon room")
    harness.falsy(shared.misc_eligible(api),
        "one-in-three source exception admits device room")

    api.device_disabled = true
    harness.truthy(shared.misc_eligible(api),
        "no-artifice sacrifice always vetoes device room")

    api.started = false
    harness.falsy(shared.weapon_eligible(api),
        "preview has no character-dependent veto")
end

-- The hook contract spans entrance, reward, and veto modules, so a
-- missing source function fails before any rare map is selected.
function test.run()
    check_entry()
    check_destinations()
    check_vetoes()
end

return test
