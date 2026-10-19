
local component = require("constants.component")
local causes = require("constants.damage_causes")
local restrictions = require("constants.safety_restrictions")
local mutations = require("ids.mutations")
local items = require("ids.items")
local potion_rules = require("policy.character.potion_rules")
local quaff = require("policy.commands.quaff")
local safety = require("policy.character.damage_safety")
local save_status = require("policy.save.status")
local player_health = require("policy.combat.player_health")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Capture prevented-damage messages while the live HP component proves safety.
local function battle_context(ctx, player)
    local battle = setmetatable({}, { __index = ctx })
    local messages = {}

    -- Capture damage safety events separately from the policy state being asserted.
    function battle.emit(_, _, text)
        messages[#messages + 1] = text
    end

    -- Return only prevented-damage messages from the battle proxy.
    function battle.messages()
        return messages
    end

    -- Bind policy ownership to damage safety fixture actor so player-only branches execute on that entity.
    function battle.player()
        return player
    end

    return battle
end

-- Restore rejects an invalid safety duration.
function test.run(ctx)
    local player = ctx:create()
    local battle = battle_context(ctx, player)

    ctx:add(player, component.HEALTH, {
        current = 30,
        max = 100,
    })
    records.grant_acquired(ctx, player,
        mutations.MUT_READ_SAFETY, 2)
    records.grant_acquired(ctx, player,
        mutations.MUT_DRINK_SAFETY, 2)

    player_health.damage(battle, player, 20)

    local messages = battle.messages()

    harness.equal(messages[1],
        "You feel threatened and lose the ability to read scrolls!",
        "Read Safety runs before the HP loss")
    harness.equal(messages[2],
        "You feel threatened and lose the ability to drink potions!",
        "Drink Safety rolls independently after Read Safety")
    -- Safety checks observe the same pre-damage vitals before the hit mutates HP.
    harness.equal(ctx:get(player, component.HEALTH).current, 10,
        "both restrictions use pre-hit HP and then damage is applied")
    harness.equal(safety.remaining(ctx, player, restrictions.POTIONS), 10,
        "Drink Safety begins with one turn of restriction")
    -- The two restrictions use separate rolls and saved timers.
    harness.equal(safety.remaining(ctx, player, restrictions.SCROLLS), 10,
        "Read Safety keeps an independent duration")
    harness.falsy(potion_rules.can_drink(ctx, player),
        "Drink Safety prevents potion use")

    local potion = ctx:create()

    ctx:add(potion, component.ITEM, {
        kind_id = items.POT_CURING,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(potion, component.CARRIED_BY, {
        holder = player,
    })

    local refused = quaff.prepare(battle, player, ctx:id(potion))

    harness.equal(refused.message, "You can't drink.",
        "the live potion command respects Drink Safety")

    safety.tick(battle, player, 10)

    -- The live item command must consult expiry rather than the original damage event.
    harness.truthy(potion_rules.can_drink(ctx, player),
        "potion use returns after the restriction expires")
    harness.truthy(quaff.prepare(battle, player,
        ctx:id(potion)).intent,
        "the live potion command accepts use after recovery")
    harness.equal(messages[#messages], "You can read scrolls again.",
        "Read Safety announces recovery independently")

    local poisoned = ctx:create()
    local poison_battle = battle_context(ctx, poisoned)

    ctx:add(poisoned, component.HEALTH, {
        current = 30,
        max = 100,
    })
    records.grant_acquired(ctx, poisoned,
        mutations.MUT_READ_SAFETY, 2)
    records.grant_acquired(ctx, poisoned,
        mutations.MUT_DRINK_SAFETY, 2)
    player_health.damage(poison_battle, poisoned, 20,
        false, nil, causes.POISON)

    harness.falsy(ctx:get(poisoned, component.DAMAGE_SAFETY),
        "poison damage bypasses both safety restrictions")

    local safe = ctx:create()
    local safe_battle = battle_context(ctx, safe)

    -- Fail if a safe hit draws RNG; safety should reject before threat chance.
    function safe_battle.random()
        error("safe damage must not draw a threat chance")
    end

    ctx:add(safe, component.HEALTH, {
        current = 80,
        max = 100,
    })
    records.grant_acquired(ctx, safe,
        mutations.MUT_READ_SAFETY, 1)
    player_health.damage(safe_battle, safe, 20)

    harness.falsy(ctx:get(safe, component.DAMAGE_SAFETY),
        "first-tier safety cannot trigger at high pre-hit HP")

    local corrupt = ctx:get(player, component.DAMAGE_SAFETY)
    corrupt[restrictions.POTIONS] = -1
    ctx:set(player, component.DAMAGE_SAFETY, corrupt)

    local accepted = pcall(save_status.run, battle)

    harness.falsy(accepted,
        "restore rejects an invalid safety duration")
end

return test
