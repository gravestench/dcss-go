
local accuracy = require("policy.character.accuracy")
local auxiliary = require("policy.combat.auxiliary")
local attacks = require("constants.auxiliary_attacks")
local player_attack = require("policy.combat.player_attack")
local projectile = require("policy.magic.effects.zaps.projectile")
local sting = require("policy.magic.effects.zaps.sting")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Record each melee hit bound before comparing Missing Eye accuracy.
local function attack_context(ctx, player, draws, bounds)
    local proxy = setmetatable({}, { __index = ctx })
    local index = 0

    -- Bind policy ownership to accuracy fixture actor so player-only branches execute on that entity.
    function proxy.player()
        return player
    end

    -- Record melee bounds in draw order to verify hit formula changes before inaccuracy.
    function proxy.random(_, stream, bound)
        harness.equal(stream, "melee", "player contact uses melee RNG")
        index = index + 1
        bounds[index] = bound

        local value = draws[index] or 0

        if value < 0 or value >= bound then
            error("invalid melee draw " .. tostring(index) ..
                " for bound " .. tostring(bound))
        end

        return value
    end

    return proxy
end

-- Assemble a baseline primary hit input before mutation accuracy changes it.
local function main_contact(ctx, player)
    local input = {
        dexterity = 10,
        fighting100 = 0,
        weapon100 = 0,
        using_weapon = false,
        defender_ev = 8,
    }

    local bounds = {}
    local outcome = player_attack.contact(attack_context(ctx, player,
        { 10, 50, 0 }, bounds), input)

    return outcome, bounds[1]
end

-- Assemble a secondary strike input with one selected natural attack.
local function auxiliary_contact(ctx, player, attack_id)
    local input = {
        level = 27,
        horns = 1,
        hooves = 1,
        talons = 0,
        tentacle_spike = 0,
        strength = 10,
        dexterity = 10,
        fighting100 = 0,
        fighting30 = 0,
        defender_ev = 8,
        defender_ac = 0,
        mighty = false,
    }

    local bounds = {}
    local outcome = auxiliary.resolve_one(attack_context(ctx, player,
        { 0, 10, 1 }, bounds), input, auxiliary.get(attack_id))

    return outcome, bounds[2]
end

-- Sting uses its source hit formula before inaccuracy.
function test.run(ctx)
    local player = ctx:create()

    harness.equal(accuracy.degree(ctx, player), 0,
        "ordinary player has no inaccuracy")
    harness.equal(accuracy.zap_to_hit(ctx, player, 4), 4,
        "ordinary aimed zap retains its hit value")
    harness.equal(projectile.to_hit(ctx, player, sting.spec, 10), 10,
        "Sting uses its source hit formula before inaccuracy")
    -- Keep baseline melee and auxiliary contacts fixed before adding mutation modifiers.
    harness.equal(main_contact(ctx, player).kind, "hit",
        "ordinary main attack hits with a ten-point roll")
    harness.truthy(auxiliary_contact(ctx, player, attacks.KICK.id).hit,
        "ordinary auxiliary kick hits with a ten-point roll")
    harness.truthy(auxiliary_contact(ctx, player, attacks.HEADBUTT.id).hit,
        "ordinary auxiliary headbutt hits with a ten-point roll")

    records.grant_acquired(ctx, player, mutations.MUT_MISSING_EYE, 1)

    harness.equal(accuracy.degree(ctx, player), 1,
        "Missing Eye contributes one degree of inaccuracy")
    harness.equal(accuracy.zap_to_hit(ctx, player, 12), 7,
        "Missing Eye lowers aimed zap accuracy by five")
    harness.equal(accuracy.zap_to_hit(ctx, player, 4), 0,
        "aimed zap accuracy cannot become negative")
    harness.equal(projectile.to_hit(ctx, player, sting.spec, 10), 5,
        "the live Sting resolver applies Missing Eye to its hit value")
    -- Missing Eye changes the post-roll result, while Eyeballs changes the pre-roll bound.
    harness.equal(main_contact(ctx, player).kind, "miss",
        "Missing Eye changes the main attack after its roll")
    harness.falsy(auxiliary_contact(ctx, player, attacks.KICK.id).hit,
        "Missing Eye also changes auxiliary kick contact")
    harness.falsy(auxiliary_contact(ctx, player, attacks.HEADBUTT.id).hit,
        "Missing Eye also changes auxiliary headbutt contact")

    records.grant_acquired(ctx, player, mutations.MUT_EYEBALLS, 1)

    harness.equal(accuracy.hit_bonus(ctx, player), 3,
        "one Eyeballs level adds three to player attack accuracy")
    local _, main_bound = main_contact(ctx, player)
    local _, auxiliary_bound = auxiliary_contact(ctx, player,
        attacks.KICK.id)

    harness.equal(main_bound, 25,
        "Eyeballs raises main attack accuracy before the hit roll")
    harness.equal(auxiliary_bound, 23,
        "Eyeballs raises auxiliary accuracy before the hit roll")

    records.grant_acquired(ctx, player, mutations.MUT_EYEBALLS, 2)

    harness.equal(accuracy.hit_bonus(ctx, player), 7,
        "three Eyeballs levels add seven to attack accuracy")
    local _, highest_bound = main_contact(ctx, player)

    harness.equal(highest_bound, 29,
        "three Eyeballs levels raise the live main hit-roll bound")
    -- The positive mutation bonus belongs to physical contact, unlike Inaccuracy on zaps.
    harness.equal(accuracy.zap_to_hit(ctx, player, 12), 7,
        "Eyeballs does not change aimed spell accuracy")
end

return test
