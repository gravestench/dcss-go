-- The Pan hook tests call production Lua methods with one recording API.
-- They assert source gameplay effects, not copies of the hook's data tables.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local harness = require("tests.harness")
local runes = require("constants.runes")
local rules = require("constants.vault_generation_rules")
local shared = require("policy.generation.vaults.pan.shared")

local test = {}

-- Capture typed instructions in source order; the real DES pipeline applies
-- the same instructions at the call site's location in each source map.
local function capture(method, pan_runes, map_tag, has_demonic)
    local events = {}
    local api = {}

    function api:emit(kind, argument)
        events[#events + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    function api:record(kind, arguments)
        events[#events + 1] = {
            kind = kind,
            arguments = arguments,
        }
    end

    -- Feed the exit hooks an explicit saved rune count; no test owns a
    -- second copy of the player rune component or its counting policy.
    function api:pan_rune_count()
        return pan_runes
    end

    -- The source fixed-rune controller requests this map by a rune or lure
    -- tag, which decides whether O holds a collectible rune or a decoy.
    function api:map_tag()
        return map_tag
    end

    function api:has_rune(id)
        harness.equal(id, runes.DEMONIC,
            "fixed rune warning checks the demonic rune")

        return has_demonic
    end

    method(api)

    return events
end

-- Rune and lord vaults must still yield a real rune, return feature, and
-- region palette after their inline Lua is replaced by named methods.
function test.run()
    local guarded = capture(shared.rune_p_lord)
    local unguarded = capture(shared.rune_e)
    local contents = capture(shared.lord_abc_stair)
    local lord = capture(shared.mnoleg)
    local direct_exit = capture(shared.exit_portal, 4)
    local abyss_exit = capture(shared.abyss_portal, 2)
    local true_rune = capture(shared.fixed_rune_or_lure, nil,
        "pan_fixed_rune_boxes")
    local lure = capture(shared.fixed_rune_or_lure, nil,
        "pan_fixed_lure_boxes")
    local lord_warning = capture(shared.mnoleg_epilogue)
    local rune_warning = capture(shared.fixed_rune_epilogue,
        nil, nil, false)
    local no_rune_warning = capture(shared.fixed_rune_epilogue,
        nil, nil, true)
    local disco_name = capture(shared.disco_ball_name)

    harness.equal(guarded[1].kind, directives.SUBST,
        "guarded rune substitutes its source cell")
    harness.equal(guarded[2].argument, "O = demonic rune of Zot",
        "guarded rune item remains keyed")
    harness.equal(guarded[3].argument, "N = exit_pandemonium",
        "guarded rune may open a Pan exit")
    harness.equal(guarded[4].argument, "PON = pandemonium lord",
        "guarded rune can spawn its lord")
    harness.equal(#unguarded, 3, "unguarded rune has no lord request")
    harness.equal(unguarded[1].argument, "e = .:6 O:1 N:2",
        "unguarded e cell follows source odds")
    harness.equal(contents[3].kind, directives.KMONS,
        "greater demon stays a keyed monster request")
    harness.truthy(contents[3].argument:find("C< = greater demon", 1, true),
        "greater demon may occupy the stair")
    harness.equal(contents[4].argument, "< = {",
        "lesser lord vault retains its return stair")
    harness.equal(lord[1].kind, effects.GENERATION_RULE,
        "lord controls its whole region's ambient population")
    harness.equal(lord[1].arguments.rule, rules.RANDOM_MONSTER_LIST,
        "lord ambient population uses the shared generation rule")
    harness.equal(lord[#lord].argument, "O = glowing rune of Zot",
        "Mnoleg protects the matching rune")
    harness.equal(direct_exit[1].argument,
        "O = exit_pandemonium w:17 / floor w:83",
        "all four Pan runes improve the direct exit chance")
    harness.equal(abyss_exit[1].argument,
        "O = exit_through_abyss w:45 / floor w:55",
        "two Pan runes improve the Abyss exit chance")
    harness.equal(#true_rune, 1,
        "a fixed-rune request must emit only one item rule")
    harness.equal(true_rune[1].argument, "O = demonic rune of zot",
        "rune request yields the real demonic rune")
    harness.equal(#lure, 1,
        "a fixed-lure request must emit only one item rule")
    harness.equal(lure[1].argument,
        "O = superb_item / demonic rune of zot mimic",
        "lure request yields a false prize")
    harness.equal(lord_warning[1].kind, effects.ENTRY_MESSAGE,
        "entering a lord realm records its warning")
    harness.truthy(lord_warning[1].arguments.text:find(
        "Mnoleg resides here", 1, true),
        "warning identifies the Pan lord")
    harness.equal(lord_warning[1].arguments.note,
        "Entered the realm of Mnoleg.",
        "lord entry note survives for the game log")
    harness.equal(rune_warning[1].kind, effects.ENTRY_MESSAGE,
        "unclaimed fixed rune has an entry warning")
    harness.equal(#no_rune_warning, 0,
        "already collected demonic rune has no warning")
    harness.equal(disco_name[1].kind, effects.FEATURE_NAME,
        "disco ball name remains a typed feature description")
    harness.equal(disco_name[1].arguments.feature,
        features.GRANITE_STATUE,
        "disco ball replaces a source granite statue")
end

return test
