-- Each source script site resolves through the same named hook dispatcher
-- as modded maps. The assertions check decisions, not copied handler code.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local trigger_ids = require("constants.vault_triggers")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Capture just the documented generation API a source hook can read.
local function run(id, method, branch_id, depth, bottom)
    local emitted = {}
    local records = {}
    local api = {}

    function api:emit(kind, argument)
        emitted[#emitted + 1] = {
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

    function api:branch_id()
        return branch_id
    end

    function api:depth()
        return depth
    end

    function api:branch_bottom()
        return bottom
    end

    function api:depth_fraction()
        return depth / bottom
    end

    hooks.run(vaults.get(id), method, api)

    return emitted, records
end

-- The two source stair placeholders use first, middle, and last-floor
-- palettes in the same order, though the glyph they replace differs.
local function stair_palettes()
    local webbed = "nicolae_spider_webbed_stairs"
    local jumping = "nicolae_spider_jumping_sub_stairs"
    local first = run(webbed, "configure", branches.BRANCH_SPIDER, 1, 4)
    local middle = run(webbed, "configure", branches.BRANCH_SPIDER, 2, 4)
    local last = run(webbed, "configure", branches.BRANCH_SPIDER, 4, 4)

    harness.equal(first[1].argument, "s = ]})", "first webbed stair")
    harness.equal(middle[1].argument, "s = ]})[{(", "middle webbed stair")
    harness.equal(last[1].argument, "s = [{(", "last webbed stair")

    local first_jump = run(jumping, "stairs", branches.BRANCH_SPIDER, 1, 4)
    local middle_jump = run(jumping, "stairs", branches.BRANCH_SPIDER, 2, 4)
    local last_jump = run(jumping, "stairs", branches.BRANCH_SPIDER, 4, 4)

    harness.equal(first_jump[1].argument, "S = )}]", "first jumping stair")
    harness.equal(middle_jump[1].argument, "S = (){}[]", "middle jumping stair")
    harness.equal(last_jump[1].argument, "S = ({[", "last jumping stair")
end

-- All jumping children share source monster, water, and clearing policy;
-- their own DES rows retain the reason each helper looks different.
local function jumping_setup()
    local id = "nicolae_spider_jumping_sub_grid"
    local emitted = run(id, "jumping_setup.configure_repeatable",
        branches.BRANCH_SPIDER, 2, 4)

    harness.equal(#emitted, 5, "shared jumping setup directive count")
    harness.equal(emitted[1].kind, directives.MONS,
        "jumping spider source monster request")
    harness.equal(emitted[1].argument, "jumping spider",
        "source monster identity")
    harness.equal(emitted[5].kind, directives.CLEAR,
        "placeholder cleanup follows substitutions")
    harness.equal(emitted[5].argument, "-", "source clear glyph")
end

-- Zot changes more than the trap kind. Test its penultimate and ordinary
-- arms as well as Spider's independent roster and treasure choice.
local function trapstep()
    local id = "hangedman_spider_trapstep"
    local spider = run(id, "configure", branches.BRANCH_SPIDER, 2, 4)
    local late_zot = run(id, "configure", branches.BRANCH_ZOT, 4, 5)
    local early_zot = run(id, "configure", branches.BRANCH_ZOT, 2, 5)

    harness.equal(#spider, 8, "Spider source branch directive count")
    harness.equal(spider[1].argument, "2 = tarantella",
        "Spider source monster arm")
    harness.equal(spider[4].argument, "` = shaft trap",
        "Spider source trap arm")
    harness.equal(#late_zot, 8, "Zot source branch directive count")
    harness.equal(late_zot[6].argument,
        "~ = zot trap w:20 / web trap / . w:5",
        "penultimate Zot floor trap")
    harness.equal(early_zot[6].argument,
        "~ = zot trap w:15 / shaft trap / web trap w:5 / . w:5",
        "other Zot floor trap")
end

-- Source decay and player-move markers must be typed at their source
-- script positions so orientation and save use the same authored cells.
local function typed_effects()
    local _, entry_decay = run("hellmonk_spider_entry_life_and_decay",
        "decay.redback", branches.BRANCH_LAIR, 3, 5)
    local _, cave_decay = run("hangedman_creepy_crawlies",
        "decay.any_corpse", branches.BRANCH_SPIDER, 2, 4)
    local _, mine_decay = run("nicolae_spider_mines_1",
        "decay.orc_skeleton", branches.BRANCH_SPIDER, 2, 4)
    local _, basket = run("spiders_nest_spider_trap",
        "configure", branches.BRANCH_SPIDER, 2, 4)

    harness.equal(entry_decay[1].kind, effects.DELAYED_DECAY,
        "entrance remains use typed decay")
    harness.equal(entry_decay[1].arguments.alternatives,
        "redback corpse", "entrance corpse identity")
    harness.equal(cave_decay[1].arguments.alternatives,
        "any corpse", "creepy crawlies corpse choice")
    harness.equal(mine_decay[1].arguments.alternatives,
        "orc skeleton", "mine skeleton identity")
    harness.equal(basket[1].kind, effects.MARKER,
        "basket marker is typed")
    harness.equal(basket[1].arguments.identity,
        trigger_ids.SPIDER_NEST_SPAWN, "basket callback identity")
    harness.equal(basket[2].arguments.identity,
        trigger_ids.SPIDER_NEST_WARN, "warning callback identity")
end

-- Every conditional hook follows its original source branch.
function test.run()
    stair_palettes()
    jumping_setup()
    trapstep()
    typed_effects()
end

return test
