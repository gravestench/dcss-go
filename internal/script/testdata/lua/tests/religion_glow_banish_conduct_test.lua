-- These actions use the production conduct rules and saved ECS schemas.
-- A fixture only chooses the acting player and supplies deterministic RNG.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local zap_ids = require("policy.magic.effects.zaps.ids")
local contamination = require("policy.magic.contamination")
local facts = require("policy.religion.conduct.monster_facts")

local test = {}

-- Zin warns when an involuntary source first makes the player glow, then
-- penalizes a controlled increase while already glowing. One action cannot
-- produce several copies of the lecture.
local function zin_glow(ctx)
    local player = ctx:create()
    local messages = {}
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    function observed:aut()
        return 50
    end

    function observed:emit(_, message)
        messages[#messages + 1] = message
    end

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.ZIN,
        piety = 50,
    })

    contamination.change(observed, player, 6000, false)

    harness.equal(ctx:get(player,
        zap_ids.component.CONTAMINATION).amount, 6000)
    harness.equal(ctx:get(player, component.RELIGION_WORSHIP).piety, 50)
    harness.equal(#messages, 1)

    contamination.change(observed, player, 1000, true)
    contamination.change(observed, player, 1000, true)

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(worship.piety, 43)
    harness.equal(worship.penance[gods.ZIN] or 0, 0)
    harness.equal(#messages, 2)
end

-- Lugonu receives banishment credit only for a hostile XP-bearing target.
-- The source reward uses the victim's experience level, not damage or HP.
local function banish_facts(ctx)
    local player = ctx:create()
    local monster = ctx:create()
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    ctx:add(monster, component.ACTOR, {
        kind_id = monsters.MONS_ORC_WIZARD,
    })

    local definition = catalog.get(categories.MONSTERS,
        monsters.MONS_ORC_WIZARD)
    local event = facts.banish(observed, monster, definition, player)

    harness.truthy(event.credit)
    harness.equal(event.level, definition.hd)

    event = facts.banish(observed, monster, definition, nil)

    harness.falsy(event.credit)
end

-- Independent cases keep a conduct failure local to its action owner.
function test.run(ctx)
    zin_glow(ctx)
    banish_facts(ctx)
end

return test
