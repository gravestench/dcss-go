-- Ice Cave hooks use the production source helper modules. The collector
-- records their typed output without inventing a second content schema.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local rules = require("constants.vault_generation_rules")

local test = {}

-- Capture one hook's source draw count and emitted operations. The real
-- placement owner consumes the same `emit` and `record` methods.
local function run_hook(handler, branch, depth, hard, draw)
    local emitted = {}
    local records = {}
    local rolls = 0
    local api = {}

    -- The entrance's outside branch is the source of its fixed difficulty.
    function api:branch_id()
        return branch
    end

    -- Local depth distinguishes easy D:13 from hard D:14 gates.
    function api:depth()
        return depth
    end

    -- Destination helpers may read only the already saved hard choice.
    function api:setting(name)
        harness.equal(name, "ice_cave_hard",
            "destination reads only the saved difficulty")

        return hard
    end

    -- Count each generation draw so a new accidental reroll fails.
    function api:roll(bound)
        rolls = rolls + 1
        harness.truthy(draw < bound, "hook draw exceeds source bound")

        return draw
    end

    -- Record DES directives in order as the production placement API does.
    function api:emit(kind, argument)
        emitted[#emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    -- Typed generation effects are distinct from immediate DES directives.
    function api:record(kind, arguments)
        records[#records + 1] = {
            kind = kind,
            arguments = arguments,
        }
    end

    handler(api)

    return emitted, records, rolls
end

-- The source draws its clock before it tests the origin branch. No second
-- difficulty roll is allowed when a player later enters the saved gate.
local function check_portal()
    local entry = require("policy.generation.vaults.ice_cave_entry.shared")
    local easy, _, easy_rolls = run_hook(entry.portal,
        branches.BRANCH_DUNGEON, 13, false, 0)
    local hard, _, hard_rolls = run_hook(entry.portal,
        branches.BRANCH_DUNGEON, 14, false, 200)

    harness.equal(easy_rolls, 1, "easy entrance draws one clock")
    harness.equal(hard_rolls, 1, "hard entrance draws one clock")
    harness.truthy(easy[1].argument:find("low = 600", 1, true),
        "minimum source lifetime")
    harness.truthy(easy[1].argument:find("hard = false", 1, true),
        "D:13 is easy")
    harness.truthy(hard[1].argument:find("low = 800", 1, true),
        "maximum source lifetime")
    harness.truthy(hard[1].argument:find("hard = true", 1, true),
        "D:14 is hard")
    harness.equal(easy[2].kind, directives.KFEAT,
        "source portal feature follows marker")
end

-- Both variants use source-owned monster and reward definitions. The
-- random monster list is a typed generation rule, not a spawned actor.
local function check_destination_helpers()
    local shared = require("policy.generation.vaults.ice_cave.shared")
    local easy, _, easy_rolls = run_hook(shared.common_loot,
        branches.BRANCH_ICE_CAVE, 1, false, 0)
    local hard = run_hook(shared.common_loot,
        branches.BRANCH_ICE_CAVE, 1, true, 0)

    harness.equal(easy_rolls, 0, "loot definitions defer item draws")
    harness.equal(#easy, 6, "source common loot glyphs")
    harness.equal(easy[1].kind, directives.KITEM,
        "armour remains a keyed item request")
    harness.truthy(not easy[1].argument:find("good_item", 1, true),
        "easy armour has ordinary quality")
    harness.truthy(hard[1].argument:find("good_item", 1, true),
        "hard armour has good-item quality")

    local natural, natural_records = run_hook(shared.natural_monsters,
        branches.BRANCH_ICE_CAVE, 1, true, 0)
    local undead, undead_records = run_hook(shared.undead_monsters,
        branches.BRANCH_ICE_CAVE, 1, false, 0)

    harness.truthy(natural[1].argument:find("polar bear", 1, true),
        "hard natural roster")
    harness.truthy(undead[1].argument:find("white imp", 1, true),
        "easy undead roster")
    harness.equal(natural_records[1].kind, effects.GENERATION_RULE,
        "natural random monster list is typed")
    harness.equal(undead_records[1].arguments.rule,
        rules.RANDOM_MONSTER_LIST,
        "undead random monster list rule")

    local appearance, names = run_hook(shared.appearance,
        branches.BRANCH_ICE_CAVE, 1, false, 0)

    harness.equal(appearance[1].argument, "< = exit_ice_cave",
        "authored return feature")
    harness.equal(names[1].kind, effects.FEATURE_NAME,
        "ice wall description remains a local record")
end

-- One actual freezing-vapour marker must carry the source delay and size
-- so the existing fog-machine owner can materialize it on the cave floor.
local function check_fog()
    local shared = require("policy.generation.vaults.ice_cave.shared")
    local fog = run_hook(shared.fog_8,
        branches.BRANCH_ICE_CAVE, 1, false, 0)

    harness.equal(fog[1].kind, directives.MARKER,
        "fog is a typed marker")
    harness.truthy(fog[1].argument:find('cloud_type = "freezing vapour"',
        1, true), "source cold cloud")
    harness.truthy(fog[1].argument:find("size = 8", 1, true),
        "source machine size")
end

-- Each helper's behavior is checked separately so a failing source rule
-- identifies its owner without requiring a random whole-floor draw.
function test.run()
    check_portal()
    check_destination_helpers()
    check_fog()
end

return test
