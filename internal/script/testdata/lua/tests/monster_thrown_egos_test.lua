-- Monster-held missile egos are ordinary catalog state. The AI must be
-- able to plan each source-generated stack before spending an attack.
local egos = require("constants.missile_egos")
local catalog = require("policy.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local items = require("ids.items")
local missile_egos = require("policy.combat.monster_missile_egos")
local monsters = require("ids.monsters")
local projectiles = require("policy.combat.monster_projectiles")
local ranged_fixture = require("tests.fixtures.ranged_reflection")
local ranged_actions = require("policy.combat.ranged_actions")
local confusion = require("policy.magic.player_confusion")
local rage = require("policy.character.rage")
local species = require("ids.species")
local terrain = require("constants.terrain")

local test = {}

-- Source makeitem.cc creates these particular branded stacks. A saved
-- item can also carry an explicit DES ego, so those use the same validator.
local cases = {
    {
        kind_id = items.MI_DART,
        egos = {
            egos.POISONED,
            egos.CURARE,
            egos.BLINDING,
            egos.FRENZY,
        },
    },
    {
        kind_id = items.MI_JAVELIN,
        egos = {
            "",
            egos.SILVER,
        },
    },
    {
        kind_id = items.MI_BOOMERANG,
        egos = {
            "",
            egos.SILVER,
            egos.DISPERSAL,
        },
    },
}

-- The production projectile resolver should accept generated IDs and
-- reject an unknown saved ego before damage or status policy can run.
local function supported_egos()
    harness.truthy(egos.SILVER,
        "one missile ego module must name generated silver ammo")

    for _, entry in ipairs(cases) do
        local effect = projectiles.effect(entry.kind_id)

        for _, ego in ipairs(entry.egos) do
            effect.validate({ ego = ego }, entry.kind_id)
        end

        harness.falsy(pcall(effect.validate, {
            ego = "unknown missile ego",
        }, entry.kind_id), "unknown missile ego passed validation")
    end

    projectiles.effect(items.MI_BOOMERANG).validate({},
        items.MI_BOOMERANG)
end

-- Direct brands should reach the same player owners as a Chaos-selected
-- brand. Each scene has fresh health and status components for isolation.
local function player_effects(ctx)
    local kind = catalog.get("items", items.MI_BOOMERANG)
    local definition = catalog.get("monsters", monsters.MONS_GOBLIN)
    local fire, fire_player, fire_shooter = ranged_fixture.scene(ctx,
        items.MI_BOOMERANG, false, nil, false)

    function fire.random(_, _, bound)
        return 0
    end

    missile_egos.apply_player(fire, fire_shooter, definition,
        kind, egos.FLAME, 5)
    harness.equal(ctx:get(fire_player, component.HEALTH).current, 19,
        "direct flame uses the existing player brand owner")

    local poison, poison_player, poison_shooter = ranged_fixture.scene(ctx,
        items.MI_BOOMERANG, false, nil, false)

    function poison.random(_, _, bound)
        if bound == 4 then
            return 1
        end

        return 0
    end

    missile_egos.apply_player(poison, poison_shooter, definition,
        kind, egos.POISONED, 5)
    harness.equal(ctx:get(poison_player, component.POISON).amount_scaled,
        6000, "direct poisoned ammo applies the source dose")

    local curare, curare_player, curare_shooter = ranged_fixture.scene(ctx,
        items.MI_BOOMERANG, false, nil, false)

    function curare.random()
        return 0
    end

    missile_egos.apply_player(curare, curare_shooter, definition,
        kind, egos.CURARE, 5)
    harness.equal(ctx:get(curare_player, component.HEALTH).current, 18,
        "curare deals the source 2d6 asphyxiation minimum")
    harness.equal(ctx:get(curare_player, component.POISON).amount_scaled,
        3000, "curare poisons the survivor with source 2d12+1")
end

-- Poison immunity stops both ordinary coatings and Curare before any
-- condition or breath-damage roll. The same species rule is used by spells.
local function resistant_poison(ctx)
    local kind = catalog.get("items", items.MI_BOOMERANG)
    local definition = catalog.get("monsters", monsters.MONS_GOBLIN)

    for _, ego in ipairs({ egos.POISONED, egos.CURARE }) do
        local battle, player, shooter = ranged_fixture.scene(ctx,
            items.MI_BOOMERANG, false, nil, false)
        local choice = ctx:get(player, component.PLAYER)

        choice.species_id = species.SP_GARGOYLE
        ctx:set(player, component.PLAYER, choice)

        function battle.random()
            return 0
        end

        missile_egos.apply_player(battle, shooter, definition,
            kind, ego, 5)
        harness.equal(ctx:get(player, component.HEALTH).current, 20,
            ego .. " bypassed poison immunity")
        harness.falsy(ctx:get(player, component.POISON),
            ego .. " poisoned an immune player")
    end
end

-- A Curare dart uses the same contact roll as a poisoned dart but must not
-- draw or return a poison-dart dose before its Curare effect runs.
local function unpoisoned_dart_contact(ctx)
    local battle, _, shooter, entity = ranged_fixture.scene(ctx,
        items.MI_DART, false, nil, false)
    local item = ctx:get(entity, component.ITEM)

    item.ego = egos.CURARE
    ctx:set(entity, component.ITEM, item)

    function battle.random(_, _, bound)
        return bound - 1
    end

    local defense = {
        ev = 0,
        shield_class = 0,
        shield_blocks = 0,
    }
    local definition = catalog.get("monsters", monsters.MONS_GOBLIN)
    local kind = catalog.get("items", items.MI_DART)
    local outcome, dose = projectiles.effect(kind.id).resolve(battle,
        shooter, definition, defense, kind, item)

    harness.equal(outcome.kind, "hit", "Curare dart reached the player")
    harness.equal(dose, 0, "Curare dart drew a poison-dart dose")
end

-- Cold and silver each add the source minimum damage when the player has
-- no corresponding resistance, mutation, or transformed shape.
local function direct_damage_egos(ctx)
    local kind = catalog.get("items", items.MI_BOOMERANG)
    local definition = catalog.get("monsters", monsters.MONS_GOBLIN)

    for _, ego in ipairs({ egos.FROST, egos.SILVER }) do
        local battle, player, shooter = ranged_fixture.scene(ctx,
            items.MI_BOOMERANG, false, nil, false)

        function battle.random()
            return 0
        end

        missile_egos.apply_player(battle, shooter, definition,
            kind, ego, 5)
        harness.equal(ctx:get(player, component.HEALTH).current, 19,
            ego .. " adds its source minimum damage")
    end
end

-- Source dart resistance precedes both confusion and berserk. The test
-- gives Rage its ordinary regeneration owner rather than mocking it.
local function mind_egos(ctx)
    local kind = catalog.get("items", items.MI_DART)
    local definition = catalog.get("monsters", monsters.MONS_GOBLIN)
    local blind, blind_player, blind_shooter = ranged_fixture.scene(ctx,
        items.MI_DART, false, nil, false)

    function blind.random()
        return 0
    end

    missile_egos.apply_player(blind, blind_shooter, definition,
        kind, egos.BLINDING, 6)
    harness.truthy(confusion.active(blind, blind_player),
        "blinding dart confuses an unresisting player")

    local frenzy, frenzy_player, frenzy_shooter = ranged_fixture.scene(ctx,
        items.MI_DART, false, nil, false)

    ctx:add(frenzy_player, component.REGENERATION, {
        hp_progress = 0,
        mp_progress = 0,
    })

    function frenzy.random()
        return 0
    end

    missile_egos.apply_player(frenzy, frenzy_shooter, definition,
        kind, egos.FRENZY, 6)
    harness.truthy(rage.active(frenzy, frenzy_player),
        "frenzy dart berserks an eligible player")
end

-- Dispersal chooses the farther of two sampled legal landings. A Formicid
-- with innate stasis remains at impact without consuming landing draws.
local function dispersal_ego(ctx)
    local kind = catalog.get("items", items.MI_BOOMERANG)
    local definition = catalog.get("monsters", monsters.MONS_GOBLIN)

    for _, species_id in ipairs({ species.SP_HUMAN, species.SP_FORMICID }) do
        local battle, player, shooter = ranged_fixture.scene(ctx,
            items.MI_BOOMERANG, false, nil, false)
        local choice = ctx:get(player, component.PLAYER)
        local draws = {
            8,
            8,
            9,
            9,
        }
        local next_draw = 0

        choice.species_id = species_id
        ctx:set(player, component.PLAYER, choice)

        function battle.random(_, _, bound)
            harness.equal(bound, 13, "dispersal samples nearby offsets")
            next_draw = next_draw + 1

            return draws[next_draw]
        end

        function battle.walkable()
            return true
        end

        function battle.actor_at()
            return nil
        end

        function battle.visible()
            return true
        end

        function battle.records_at()
            return {}
        end

        function battle.move_actor(_, actor, level_id, x, y)
            ctx:set(actor, component.POSITION, {
                level_id = level_id,
                x = x,
                y = y,
            })
        end

        missile_egos.apply_player(battle, shooter, definition,
            kind, egos.DISPERSAL, 5)

        local position = ctx:get(player, component.POSITION)
        local expected_x = species_id == species.SP_HUMAN and 4 or 1

        harness.equal(position.x, expected_x,
            "dispersal honors landing distance and species stasis")
    end
end

-- A zero-damage dispersal contact is still a hit, but source policy
-- requires positive base damage before teleporting the survivor.
local function zero_damage_dispersal(ctx)
    local kind = catalog.get("items", items.MI_BOOMERANG)
    local definition = catalog.get("monsters", monsters.MONS_GOBLIN)
    local battle, player, shooter = ranged_fixture.scene(ctx,
        items.MI_BOOMERANG, false, nil, false)
    local before = ctx:get(player, component.POSITION)

    missile_egos.apply_player(battle, shooter, definition,
        kind, egos.DISPERSAL, 0)

    local after = ctx:get(player, component.POSITION)

    harness.equal(after.x, before.x,
        "zero-damage dispersal leaves player position unchanged")
    harness.equal(after.y, before.y,
        "zero-damage dispersal leaves player position unchanged")
end

-- The action applies the base hit before an ego. A lethal hit cannot
-- attach a new poison condition to the already dead player entity.
local function lethal_hit_skips_ego(ctx)
    local battle, player, shooter, missile = ranged_fixture.scene(ctx,
        items.MI_BOOMERANG, false, nil, false)
    local item = ctx:get(missile, component.ITEM)
    local health = ctx:get(player, component.HEALTH)
    local draws = 0

    item.ego = egos.POISONED
    ctx:set(missile, component.ITEM, item)
    health.current = 1
    ctx:set(player, component.HEALTH, health)

    function battle.random(_, _, bound)
        draws = draws + 1

        if draws == 2 or draws == 3 then
            return 0
        end

        return bound - 1
    end

    ranged_actions.monster(battle, shooter, {
        item_id = missile,
    })

    harness.equal(ctx:get(player, component.HEALTH).current, 0,
        "fixture base shot kills the player")
    harness.falsy(ctx:get(player, component.POISON),
        "poison ego ran after a lethal base hit")
end

-- Reflection keeps the same saved ego. Returned Flame and Silver stacks
-- add their source minimum damage on top of the base boomerang return.
local function reflected_damage(ctx)
    local plain, _, plain_shooter, plain_item = ranged_fixture.scene(ctx,
        items.MI_BOOMERANG, true)

    ranged_fixture.block_then_return(plain)
    ranged_actions.monster(plain, plain_shooter, {
        item_id = plain_item,
    })

    local plain_hp = ctx:get(plain_shooter, component.HEALTH).current
    for _, ego in ipairs({ egos.FLAME, egos.SILVER }) do
        local branded, _, branded_shooter, branded_item =
            ranged_fixture.scene(ctx, items.MI_BOOMERANG, true)
        local state = ctx:get(branded_item, component.ITEM)

        state.ego = ego
        ctx:set(branded_item, component.ITEM, state)
        ranged_fixture.block_then_return(branded)
        ranged_actions.monster(branded, branded_shooter, {
            item_id = branded_item,
        })

        harness.equal(ctx:get(branded_shooter, component.HEALTH).current,
            plain_hp - 1, "reflected " .. ego .. " damages its shooter")
    end
end

-- An exploding stack uses the source radius-one fragment blast. The
-- player and a nearby actor both take its own 2d5 roll; the distant
-- shooter stays outside the affected cells.
local function exploding_impact(ctx)
    local exploding = require(
        "policy.combat.monster_missile_egos.exploding")
    local battle, player, shooter = ranged_fixture.scene(ctx,
        items.MI_BOOMERANG, false, nil, false)
    local nearby = ctx:create()

    ctx:add(nearby, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })
    ctx:add(nearby, component.HEALTH, {
        current = 20,
        max = 20,
    })
    ctx:add(nearby, component.POSITION, {
        level_id = 1,
        x = 2,
        y = 1,
    })

    function battle.random()
        return 0
    end

    function battle.cell()
        return terrain.DNGN_FLOOR
    end

    function battle.walkable()
        return true
    end

    function battle.actor_at(_, _, x, y)
        if x == 1 and y == 1 then
            return player
        end

        if x == 2 and y == 1 then
            return nearby
        end

        if x == 4 and y == 1 then
            return shooter
        end

        return nil
    end

    exploding.impact(battle, shooter, 1, 1, 1)

    harness.truthy(ctx:get(player, component.HEALTH).current < 20,
        "fragment impact damages the player")
    harness.truthy(ctx:get(nearby, component.HEALTH).current < 20,
        "fragment radius reaches a neighboring monster")
    harness.equal(ctx:get(shooter, component.HEALTH).current, 40,
        "fragment radius does not reach a distant shooter")

    ctx:set(nearby, component.HEALTH, {
        current = 20,
        max = 20,
    })

    function battle.walkable(_, _, x, y)
        return x ~= 2 or y ~= 1
    end

    exploding.impact(battle, shooter, 1, 1, 1)
    harness.equal(ctx:get(nearby, component.HEALTH).current, 20,
        "a solid cell shields its occupant from fragments")
end

-- The ordinary monster action must actually trigger the fragment blast,
-- including when its narrow direct contact misses the aimed player cell.
local function exploding_shot(ctx)
    local battle, player, shooter, missile = ranged_fixture.scene(ctx,
        items.MI_BOOMERANG, false, nil, false)
    local item = ctx:get(missile, component.ITEM)

    item.ego = egos.EXPLODING
    ctx:set(missile, component.ITEM, item)

    local draws = 0

    function battle.random(_, _, bound)
        draws = draws + 1

        if draws == 2 or draws == 3 then
            return 0
        end

        return bound - 1
    end

    function battle.walkable()
        return true
    end

    function battle.actor_at(_, _, x, y)
        if x == 1 and y == 1 then
            return player
        end

        if x == 4 and y == 1 then
            return shooter
        end

        return nil
    end

    ranged_actions.monster(battle, shooter, {
        item_id = missile,
    })

    harness.truthy(ctx:get(player, component.HEALTH).current < 20,
        "exploding monster shot applies its fragment blast")
end

-- Evasion misses have no source hit_verb and cannot explode. A shield
-- block contacts the target; without reflection, its blast still occurs.
local function exploding_contact_kinds(ctx)
    for _, should_block in ipairs({ false, true }) do
        local battle, player, shooter, missile = ranged_fixture.scene(ctx,
            items.MI_BOOMERANG, false, nil, should_block)
        local item = ctx:get(missile, component.ITEM)

        item.ego = egos.EXPLODING
        ctx:set(missile, component.ITEM, item)

        function battle.walkable()
            return true
        end

        function battle.actor_at(_, _, x, y)
            if x == 1 and y == 1 then
                return player
            end

            return nil
        end

        if should_block then
            ranged_fixture.block_then_return(battle)
        else
            local draws = 0

            function battle.random(_, _, bound)
                draws = draws + 1

                if draws == 2 or draws == 3 then
                    return bound - 1
                end

                return 0
            end
        end

        ranged_actions.monster(battle, shooter, {
            item_id = missile,
        })

        local health = ctx:get(player, component.HEALTH).current

        if should_block then
            harness.truthy(health < 20,
                "unreflected shield contact causes an explosion")
        else
            harness.equal(health, 20,
                "evasion miss cannot cause an explosion")
        end
    end
end

-- An explosive missile that the player reflects also explodes where its
-- returned contact reaches the shooter, beyond the outbound impact blast.
local function reflected_explosion(ctx)
    local plain, _, plain_shooter, plain_item = ranged_fixture.scene(ctx,
        items.MI_BOOMERANG, true)

    ranged_fixture.block_then_return(plain)
    ranged_actions.monster(plain, plain_shooter, {
        item_id = plain_item,
    })

    local plain_hp = ctx:get(plain_shooter, component.HEALTH).current
    local battle, player, shooter, missile = ranged_fixture.scene(ctx,
        items.MI_BOOMERANG, true)
    local item = ctx:get(missile, component.ITEM)

    item.ego = egos.EXPLODING
    ctx:set(missile, component.ITEM, item)

    function battle.walkable()
        return true
    end

    function battle.actor_at(_, _, x, y)
        if x == 1 and y == 1 then
            return player
        end

        if x == 4 and y == 1 then
            return shooter
        end

        return nil
    end

    ranged_fixture.block_then_return(battle)
    ranged_actions.monster(battle, shooter, {
        item_id = missile,
    })

    harness.equal(ctx:get(player, component.HEALTH).current, 20,
        "reflection prevents an outbound explosion")
    harness.truthy(ctx:get(shooter, component.HEALTH).current < plain_hp,
        "return impact fragments damage the shooter")
end

-- Cover catalog validation, contact effects, reflection, and fragment
-- impact through the same production modules that process game turns.
function test.run(ctx)
    supported_egos()
    player_effects(ctx)
    resistant_poison(ctx)
    unpoisoned_dart_contact(ctx)
    direct_damage_egos(ctx)
    mind_egos(ctx)
    dispersal_ego(ctx)
    zero_damage_dispersal(ctx)
    lethal_hit_skips_ego(ctx)
    reflected_damage(ctx)
    exploding_impact(ctx)
    exploding_shot(ctx)
    exploding_contact_kinds(ctx)
    reflected_explosion(ctx)
end

return test
