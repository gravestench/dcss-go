-- Source-position Crypt hooks are tested through the named DES method
-- contract. Each assertion names a choice that changes live map content.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local feature_names = require("constants.vault_feature_names")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- This local hook API captures only emitted production operations. It does
-- not repeat monster, item, or marker schemas used by the placement engine.
local function run(id, method, facts)
    facts = facts or {}
    local emitted = {}
    local memory = {}
    local api = {}

    function api:emit(kind, argument)
        emitted[#emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    function api:record(kind, arguments)
        emitted[#emitted + 1] = {
            kind = kind,
            arguments = arguments,
        }
    end

    function api:branch_id()
        return facts.branch_id or branches.BRANCH_CRYPT
    end

    function api:depth()
        return facts.depth or 2
    end

    function api:branch_bottom()
        return 3
    end

    function api:roll(bound)
        harness.equal(
            bound,
            facts.bound,
            id .. " changed its source random bound"
        )

        return facts.roll
    end

    function api:coinflip()
        return facts.coinflip
    end

    function api:one_in(bound)
        local index = facts.one_in_index or 1
        local choice = facts.one_in and facts.one_in[index]

        harness.equal(
            bound,
            choice.bound,
            id .. " changed its source one-in draw"
        )
        facts.one_in_index = index + 1

        return choice.result
    end

    function api:remember(name, value)
        memory[name] = value
    end

    function api:recall(name)
        return memory[name] or facts.remembered
    end

    hooks.run(vaults.get(id), method, api)

    return emitted, memory
end

-- This map is shared by Crypt and Tar; only Tar substitutes the wet
-- source variant, while Crypt carves ordinary open corridors.
local function branch_terrain()
    local id = "minmay_shadows"
    local crypt = run(id, "choose_branch_terrain")
    local tar = run(id, "choose_branch_terrain", {
        branch_id = branches.BRANCH_TARTARUS,
    })

    harness.equal(crypt[1].kind, directives.SUBST)
    harness.equal(crypt[1].argument, "x = c, 3 = .")
    harness.equal(tar[1].kind, directives.NSUBST)
    harness.equal(tar[1].argument, "d = 1:} / 1:.")
end

-- The little mausoleum points its decoration toward the branch entrance
-- on Crypt:1 and toward the ending on Crypt:3.
local function depth_palette()
    local expected = {
        "s = ]})>",
        "s = ]})>[{(<",
        "s = [{(<",
    }

    for depth, value in ipairs(expected) do
        local emitted = run(
            "nicolae_crypt_little_mausoleum",
            "select_depth_palette",
            { depth = depth }
        )

        harness.equal(emitted[1].kind, directives.SUBST)
        harness.equal(emitted[1].argument, value)
    end
end

-- Source names are map-local typed effects. The actual collision features
-- remain tree and granite statue on every floor.
local function local_names()
    local dead = run("gammafunk_crypt_yreds_forest", "name_dead_trees")
    local stone = run("evilmike_haunted_forest", "name_gravestones")
    local remains = run("st_small_mortuary", "preserve_corpses")

    harness.equal(dead[1].kind, effects.FEATURE_NAME)
    harness.equal(dead[1].arguments.name, feature_names.DEAD_TREE)
    harness.equal(stone[1].kind, effects.FEATURE_NAME)
    harness.equal(stone[1].arguments.name,
        feature_names.CRYPT_GRAVESTONE)
    harness.equal(remains[1].kind, effects.DELAYED_DECAY)
    harness.equal(remains[1].arguments.alternatives, "human corpse")
end

-- All three Quadcrypt source outcomes leave one keyed Tomb gate. The
-- authored glyph changes but must never create two scheduled entrances.
local function quadcrypt_gates()
    local cases = {
        {
            one_in = {
                {
                    bound = 4,
                    result = true,
                },
            },
            glyph = "L",
        },
        {
            one_in = {
                {
                    bound = 4,
                    result = false,
                },
                {
                    bound = 3,
                    result = true,
                },
            },
            glyph = "_",
        },
        {
            one_in = {
                {
                    bound = 4,
                    result = false,
                },
                {
                    bound = 3,
                    result = false,
                },
            },
            glyph = ">",
        },
    }

    for _, choice in ipairs(cases) do
        local emitted = run("quadcrypt_mu", "choose_tomb_gate", choice)
        local gates = 0

        for _, operation in ipairs(emitted) do
            if
                operation.kind == directives.KFEAT
                and operation.argument == choice.glyph .. " = enter_tomb"
            then
                gates = gates + 1
            end
        end

        harness.equal(
            gates,
            1,
            "Quadcrypt choice must author exactly one Tomb gate"
        )
    end
end

-- The shared ending helper adds all seven item slots, then thins the
-- strongest glyphs through two source substitutions.
local function bonus_loot()
    local emitted = run("lightli_unholy_cathedral", "bonus_loot")
    local items = 0
    local substitutions = 0

    for _, operation in ipairs(emitted) do
        if operation.kind == directives.KITEM then
            items = items + 1
        elseif operation.kind == directives.SUBST then
            substitutions = substitutions + 1
        end
    end

    harness.equal(items, 7, "Crypt ending bonus item slots")
    harness.equal(substitutions, 2, "Crypt ending loot thinning")
end

-- Run content-sensitive paths rather than merely checking that a module
-- exists. The all-map placement test covers the remaining authored sites.
function test.run()
    branch_terrain()
    depth_palette()
    local_names()
    quadcrypt_gates()
    bonus_loot()
end

return test
