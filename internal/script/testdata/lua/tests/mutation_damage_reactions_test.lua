
local component = require("constants.component")
local order = require("constants.damage_reaction_order")
local agility = require("policy.character.agility")
local mutations = require("ids.mutations")
local player_health = require("policy.combat.player_health")
local reactions = require("policy.combat.player_damage_reactions")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Leave pre-damage setup empty so the reaction observes only the test hit.
function test.before_damage()
end

-- Give each damage reaction a distinct injured actor and saved health.
local function wounded_player(ctx)
    local player = ctx:create()

    ctx:add(player, component.HEALTH, {
        current = 30,
        max = 30,
    })

    return player
end

-- Might uses one duration roll after selecting the effect.
function test.run(ctx)
    local deteriorating = wounded_player(ctx)

    records.grant_acquired(ctx, deteriorating,
        mutations.MUT_DETERIORATION, 2)
    player_health.damage(ctx, deteriorating, 5)

    local loss = ctx:get(deteriorating, component.STAT_LOSS)

    harness.truthy(loss,
        "a surviving large hit can deteriorate a stat")
    harness.equal(loss.strength, 1,
        "deterioration uses the shared random stat drain")

    local lightly_hit = wounded_player(ctx)
    local draws = harness.random_context(ctx, { 0 })

    records.grant_acquired(ctx, lightly_hit,
        mutations.MUT_DETERIORATION, 2)
    player_health.damage(draws, lightly_hit, 3)

    harness.falsy(ctx:get(lightly_hit, component.STAT_LOSS),
        "damage of one tenth maximum HP cannot deteriorate a stat")
    -- The draw order remains stable even when a hit is too small to trigger stat loss.
    harness.equal(draws.draws_used(), 1,
        "the deterioration chance is drawn before the damage threshold")

    local dying = ctx:create()

    ctx:add(dying, component.HEALTH, {
        current = 5,
        max = 30,
    })
    records.grant_acquired(ctx, dying,
        mutations.MUT_DETERIORATION, 2)
    player_health.damage(ctx, dying, 5)

    harness.falsy(ctx:get(dying, component.STAT_LOSS),
        "fatal damage does not trigger deterioration")

    local pained = wounded_player(ctx)
    local draws_for_pain = harness.random_context(ctx,
        { 0, 0, 0, 0, 0, 0 })
    local power_messages = {}

    -- Collect Powered by Pain messages without relying on HP changes.
    function draws_for_pain.emit(_, _, text)
        power_messages[#power_messages + 1] = text
    end

    ctx:add(pained, component.MAGIC, {
        current = 0,
        max = 10,
    })
    ctx:add(pained, component.PROGRESSION, {
        level = 1,
    })
    records.grant_acquired(ctx, pained,
        mutations.MUT_POWERED_BY_PAIN, 1)
    player_health.damage(draws_for_pain, pained, 16)

    harness.equal(ctx:get(pained, component.MAGIC).current, 3,
        "powered by pain can restore three dice of MP")
    -- A successful trigger consumes recovery dice only after its chance draw.
    harness.equal(draws_for_pain.draws_used(), 6,
        "powered by pain preserves trigger and restoration roll order")
    harness.equal(power_messages[2],
        "You feel your power returning.",
        "MP restoration uses the source canned message")

    local mighty = wounded_player(ctx)
    local draws_for_might = harness.random_context(ctx,
        { 0, 0, 2, 0 })

    ctx:add(mighty, component.PROGRESSION, {
        level = 1,
    })
    ctx:add(mighty, component.DURATIONS, {
        might_aut = 0,
        haste_aut = 0,
    })
    records.grant_acquired(ctx, mighty,
        mutations.MUT_POWERED_BY_PAIN, 1)
    player_health.damage(draws_for_might, mighty, 16)

    harness.equal(ctx:get(mighty, component.DURATIONS).might_aut, 350,
        "powered by pain can grant source-scaled Might")
    -- Power selection and duration must stay on their separate source draws.
    harness.equal(draws_for_might.draws_used(), 4,
        "Might uses one duration roll after selecting the effect")

    local agile = wounded_player(ctx)
    local draws_for_agility = harness.random_context(ctx,
        { 0, 0, 3, 0 })
    local messages = {}

    -- Collect Agility reaction messages while its status component is checked separately.
    function draws_for_agility.emit(_, _, text)
        messages[#messages + 1] = text
    end

    ctx:add(agile, component.PROGRESSION, {
        level = 1,
    })
    records.grant_acquired(ctx, agile,
        mutations.MUT_POWERED_BY_PAIN, 1)
    player_health.damage(draws_for_agility, agile, 16)

    harness.equal(messages[2],
        "You feel agile all of a sudden.",
        "powered by pain can grant Agility")
    harness.equal(ctx:get(agile, component.AGILITY).remaining_aut, 350,
        "Agility duration is saved in a Lua component")

    agility.tick(draws_for_agility, agile, 10)

    harness.equal(ctx:get(agile, component.AGILITY).remaining_aut, 340,
        "Agility decays with player action time")

    agility.tick(draws_for_agility, agile, 340)

    harness.falsy(agility.active(ctx, agile),
        "Agility ends when its duration runs out")
    harness.equal(messages[#messages],
        "You feel a little less agile now.",
        "Agility expiration uses the source message")

    local accepted = pcall(reactions.add_before,
        mutations.MUT_DETERIORATION,
        order.READ_SAFETY, test.before_damage)

    harness.truthy(accepted,
        "a mutation may register both pre-hit and post-hit effects")
end

return test
