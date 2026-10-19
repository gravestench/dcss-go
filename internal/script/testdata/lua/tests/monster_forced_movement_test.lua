-- The ordinary monster spell resolver must install a saved rolling state.
-- Later movement and melee read that same state instead of an AI-only flag.
local component = require("constants.component")
local attitudes = require("constants.attitude")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local traps = require("ids.traps")
local effects = require("policy.combat.monster_spells")
local energy = require("policy.monster_energy")
local intent = require("constants.intent")
local roll = require("policy.combat.monster_roll")

local test = {}

-- A distant, open target makes rolling useful; the cast persists an
-- enchantment that later turns can consume.
function test.run(ctx)
    local game = fixture.observed_context(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_BOULDER_BEETLE,
        20, 20, 100)
    local foe = fixture.actor(ctx, monsters.MONS_RAT,
        24, 20, 100)

    function game:random()
        return 0
    end

    local effect = effects.effect(spells.SPELL_ROLL)
    local plan = effect.plan(game, caster, foe)

    harness.truthy(plan, "Roll plans a distant foe on open floor")
    effect.resolve(game, caster, foe, nil, plan)

    local state = ctx:get(caster, component.MONSTER_ROLLING)

    harness.truthy(state and state.remaining_aut >= 100,
        "Roll records its source duration on the caster")
    harness.equal(roll.attack_damage(ctx, caster, 12), 24,
        "rolling doubles the first natural attack")

    local move = energy.spend(game, {
        actor = ctx:id(caster),
        kind_id = monsters.MONS_BOULDER_BEETLE,
        intent = intent.MOVE,
        points = energy.threshold,
    })

    harness.equal(move.cost, 5,
        "rolling reduces boulder beetle movement energy by five")

    roll.finish_attack(ctx, caster)
    harness.falsy(ctx:get(caster, component.MONSTER_ROLLING),
        "melee contact uncurls the beetle")

    -- Robin throws a nearby goblin to an open cell beside a foe. This
    -- exercises production allegiance, habitat, relocation, and damage.
    local robin = fixture.actor(ctx, monsters.MONS_ROBIN,
        30, 20, 100)
    local goblin = fixture.actor(ctx, monsters.MONS_GOBLIN,
        31, 20, 100)
    local victim = fixture.actor(ctx, monsters.MONS_RAT,
        35, 20, 100)
    local plates = 0

    function game:signal(name)
        if name == "trap.pressure_plate" then
            plates = plates + 1
        end
    end

    -- Every legal destination is a pressure plate, so the throw must
    -- apply landing effects regardless of which best cell wins the draw.
    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local plate = ctx:create()

                ctx:add(plate, component.WORLD_TRAP, {
                    kind_id = traps.TRAP_PLATE,
                    level_id = 1,
                    x = 35 + dx,
                    y = 20 + dy,
                    charges = 1,
                    revealed = true,
                    source_record = "",
                })
            end
        end
    end

    ctx:add(victim, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    function game:random(_, bound)
        return bound - 1
    end

    local throw = effects.effect(spells.SPELL_THROW_ALLY)
    local toss = throw.plan(game, robin, victim)
    local before = ctx:get(victim, component.HEALTH).current

    harness.truthy(toss, "Robin plans a throw with an adjacent goblin")
    throw.resolve(game, robin, victim, nil, toss)

    local landing = ctx:get(goblin, component.POSITION)

    harness.truthy(math.max(math.abs(landing.x - 35),
        math.abs(landing.y - 20)) == 1,
        "goblin lands beside the selected foe")
    harness.truthy(ctx:get(victim, component.HEALTH).current < before,
        "thrown ally inflicts post-armour impact damage")
    harness.equal(plates, 1,
        "thrown ally triggers the landing cell's pressure plate")

    -- The Giant may throw either adjacent ally, but only the land
    -- goblin can occupy any destination beside this floor-bound foe.
    local giant = fixture.actor(ctx, monsters.MONS_IRON_GIANT,
        40, 20, 100)
    local land_ally = fixture.actor(ctx, monsters.MONS_GOBLIN,
        41, 19, 100)
    local water_ally = fixture.actor(ctx, monsters.MONS_ELECTRIC_EEL,
        41, 21, 100)
    local giant_foe = fixture.actor(ctx, monsters.MONS_RAT,
        44, 20, 100)

    ctx:add(giant_foe, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    local giant_plan = throw.plan(game, giant, giant_foe)

    harness.truthy(giant_plan,
        "Giant plans a throw when one tied ally can land")
    harness.truthy(throw.resolve(game, giant, giant_foe,
        nil, giant_plan),
        "Giant does not spend a cast selecting the unlandable eel")
    harness.truthy(ctx:get(land_ally, component.POSITION).x > 41,
        "the land-capable ally reaches the target")
    harness.equal(ctx:get(water_ally, component.POSITION).x, 41,
        "the aquatic ally stays beside the Giant")
end

return test
