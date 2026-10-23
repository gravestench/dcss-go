-- Abyss scripts come from source-position DES hooks. These checks use the
-- production modules, so the two arms of a dual-purpose map and the exit
-- choice cannot drift while the MAP text still parses successfully.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")

local test = {}

local dual_maps = {
    "hangedman_glass_garden",
    "hangedman_abyss_or_decor_stabs",
    "hangedman_abyss_or_decor_jellyfish_corner",
    "hangedman_abyss_or_decor_lesser_grid",
    "hangedman_abyss_or_decor_clamps",
    "hangedman_abyss_or_decor_passed",
    "hangedman_abyss_or_decor_stagger",
    "hangedman_abyss_or_decor_slice",
}

-- A local capture records exactly what a source hook adds to the ordinary
-- DES operation stream. It does not reimplement the map or its schema.
local function capture(branch_id, depth, bottom, roll, settings)
    local operations = {}
    local records = {}
    local api = {}

    function api:branch_id()
        return branch_id
    end

    function api:depth()
        return depth
    end

    function api:branch_bottom()
        return bottom
    end

    function api:roll()
        return roll
    end

    function api:setting(name)
        return settings and settings[name]
    end

    function api:emit(kind, argument)
        operations[#operations + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    function api:record(kind, arguments)
        records[#records + 1] = {
            kind = kind,
            arguments = arguments,
        }
    end

    return api, operations, records
end

-- Outside Abyss the shared decor maps add the extra tag. Inside they keep
-- their Abyss substitutions and do not advertise an outside-only role.
local function check_dual_map(name)
    local handler = require("policy.generation.vaults.abyss." .. name)
    local inside, inside_ops = capture(branches.BRANCH_ABYSS)
    local outside, outside_ops = capture(branches.BRANCH_DUNGEON)

    handler.conditional(inside)
    handler.conditional(outside)

    harness.truthy(#inside_ops > 0, name .. " Abyss arm")
    harness.truthy(#outside_ops > 0, name .. " outside arm")
    harness.equal(outside_ops[1].kind, directives.TAGS,
        name .. " outside source tag")
    harness.truthy(outside_ops[1].argument:find("extra", 1, true),
        name .. " outside extra role")
end

-- Source bottom exits replace the stair alternative with a six-in-ten
-- exit or guarded item; higher floors retain the six-to-four feature mix.
local function check_exit_choice()
    local shared = require("policy.generation.vaults.abyss.shared")
    local deep_exit, exit_ops = capture(branches.BRANCH_ABYSS, 7, 7, 9)
    local deep_item, item_ops = capture(branches.BRANCH_ABYSS, 7, 7, 0)
    local upper, upper_ops = capture(branches.BRANCH_ABYSS, 3, 7, 0)

    shared.exit_o(deep_exit)
    shared.exit_n(deep_item)
    shared.exit_p(upper)

    harness.equal(exit_ops[1].kind, directives.KFEAT)
    harness.equal(exit_ops[1].argument, "O = exit_abyss")
    harness.equal(item_ops[1].kind, directives.KITEM)
    harness.equal(item_ops[1].argument, "N = any no_pickup")
    harness.equal(upper_ops[1].kind, directives.KFEAT)
    harness.equal(upper_ops[1].argument,
        "P = exit_abyss w:6 / abyssal_stair w:4")
end

-- The source stable build includes Wu Jian. The other arm remains ported
-- for a modded ruleset that deliberately makes that altar unavailable.
local function check_temple_choice()
    local temple = require("policy.generation.vaults.abyss.abyss_greek_temple")
    local present, present_ops = capture(nil, nil, nil, nil, {
        wu_jian_available = true,
    })
    local absent, absent_ops = capture(nil, nil, nil, nil, {
        wu_jian_available = false,
    })

    temple.conditional(present)
    temple.conditional(absent)

    harness.equal(present_ops[1].kind, directives.SHUFFLE)
    harness.equal(#present_ops, 1)
    harness.equal(absent_ops[1].kind, directives.SHUFFLE)
    harness.equal(absent_ops[2].kind, directives.SUBST)
end

-- The repeated delayed-decay scripts are all real typed records, so a
-- generated room can preserve its corpses until the decay owner runs.
local function check_decay()
    local names = {
        "hangedman_abyss_sting",
        "hangedman_abyss_feature_spike",
        "grunt_abyss_rune_wretched_hive",
        "doesnt_abyss_rune_brain_food",
    }

    for _, name in ipairs(names) do
        local handler = require("policy.generation.vaults.abyss." .. name)
        local api, _, records = capture()

        handler.decay(api)

        harness.equal(#records, 1, name .. " decay record")
        harness.equal(records[1].kind, effects.DELAYED_DECAY)
    end
end

-- Exercise every shared script family and both branches of each conditional.
function test.run()
    for _, name in ipairs(dual_maps) do
        check_dual_map(name)
    end

    check_exit_choice()
    check_temple_choice()
    check_decay()
end

return test
