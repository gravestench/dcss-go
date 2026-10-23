-- Weapon conduct uses the live item and worship schemas. The test replaces
-- only Chaos's random effect choice, so the offense and identification path
-- remains the production path rather than a copied rule.
local brands = require("constants.weapon_brands")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local items = require("ids.items")
local missile_egos = require("constants.missile_egos")
local chaos = require("policy.combat.monster_target_brands.chaos")
local projectiles = require("policy.religion.conduct.projectiles")

local test = {}

-- Each action gets its own player, preventing one offense's hysteresis or
-- penance from disguising the next action's exact consequence.
local function player(ctx, god_id)
    local entity = ctx:create()
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return entity
    end

    function observed:random(stream)
        harness.equal(stream, "religion")

        return 0
    end

    ctx:add(entity, component.RELIGION_WORSHIP, {
        god_id = god_id,
        piety = 50,
    })
    ctx:add(entity, component.ITEM_KNOWLEDGE, {})

    return entity, observed
end

-- Item properties, rather than the visible base weapon type, determine
-- whether a chaos launcher or melee weapon is a deliberate offense.
local function weapon(ctx, ego, known)
    local entity = ctx:create()

    ctx:add(entity, component.ITEM, {
        kind_id = items.WPN_SPEAR,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = ego,
    })
    ctx:add(entity, component.ITEM_IDENTIFICATION, {
        known_properties = known,
    })

    return entity
end

-- A chaos melee brand reports its source severity regardless of which
-- random brand it chooses. Unknown properties get Zin's one-time pardon.
local function melee_chaos(ctx, known)
    local actor, observed = player(ctx, gods.ZIN)
    local item = weapon(ctx, brands.CHAOS, known)
    local original = chaos.choose
    local applied = false

    chaos.choose = function()
        return brands.FLAMING
    end

    chaos.apply(observed, {
        attacker = actor,
        weapon_entity = item,
        health = { current = 10 },
    }, {
        apply = function()
            applied = true
        end,
    })

    chaos.choose = original

    local state = ctx:get(actor, component.RELIGION_WORSHIP)

    harness.truthy(applied)
    harness.equal(state.penance[gods.ZIN] or 0, known and 2 or 0)
end

-- Throw.cc judges each shot once, including shots without a target. The
-- launcher uses item identification; chaotic ammunition is accidental.
local function projectile_chaos(ctx)
    local actor, observed = player(ctx, gods.ZIN)
    local launcher = weapon(ctx, brands.CHAOS, true)

    projectiles.on_shot(observed, actor, launcher, true, {
        ego = brands.CHAOS,
    })

    harness.equal(ctx:get(actor, component.RELIGION_WORSHIP)
        .penance[gods.ZIN], 2)

    local unknown, unknown_ctx = player(ctx, gods.ZIN)

    projectiles.on_shot(unknown_ctx, unknown, nil, false, {
        ego = missile_egos.CHAOS,
    })

    harness.equal(ctx:get(unknown, component.RELIGION_WORSHIP)
        .penance[gods.ZIN] or 0, 0)
end

-- Cheibriados judges a speed launcher mildly and a frenzy missile more
-- harshly even if neither shot hits a monster.
local function projectile_haste(ctx)
    local actor, observed = player(ctx, gods.CHEIBRIADOS)

    projectiles.on_shot(observed, actor, nil, true, {
        ego = brands.SPEED,
    })

    local state = ctx:get(actor, component.RELIGION_WORSHIP)

    harness.equal(state.piety_hysteresis, 1)

    projectiles.on_shot(observed, actor, nil, false, {
        ego = missile_egos.FRENZY,
    })

    state = ctx:get(actor, component.RELIGION_WORSHIP)

    harness.truthy(state.piety < 50)
    harness.equal(state.penance[gods.CHEIBRIADOS], 1)
end

-- Exercise all weapon conduct owners with real registered component shapes.
function test.run(ctx)
    melee_chaos(ctx, true)
    melee_chaos(ctx, false)
    projectile_chaos(ctx)
    projectile_haste(ctx)
end

return test
