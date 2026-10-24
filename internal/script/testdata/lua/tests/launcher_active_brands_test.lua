-- Launcher hits use the ordinary weapon-brand owners after contact. These
-- tests call those production owners with the same target envelopes used
-- by ranged actions, rather than copying brand rules into a fixture.
local brands = require("constants.weapon_brands")
local catalog = require("policy.catalog")
local component = require("constants.component")
local fixture = require("tests.fixtures.ranged_reflection")
local harness = require("tests.harness")
local items = require("ids.items")
local monsters = require("ids.monsters")
local species = require("ids.species")
local monster_brands = require("policy.combat.monster_target_brands")
local player_brands = require("policy.combat.brands")
local resistance_potion = require("policy.potions.resistance")

local test = {}

-- A reflected or player-fired launcher carries its original brand to the
-- monster. Holy, shock, poison, and acid reuse the melee effect modules.
local function monster_facing(ctx)
    local cases = {
        {
            ego = brands.HOLY_WRATH,
            monster_id = monsters.MONS_CRIMSON_IMP,
        },
        {
            ego = brands.ELECTROCUTION,
            monster_id = monsters.MONS_GOBLIN,
        },
        {
            ego = brands.VENOM,
            monster_id = monsters.MONS_GOBLIN,
        },
        {
            ego = brands.ACID,
            monster_id = monsters.MONS_GOBLIN,
        },
        {
            ego = brands.VORPAL,
            monster_id = monsters.MONS_GOBLIN,
        },
    }

    for _, entry in ipairs(cases) do
        local battle, player, shooter, missile = fixture.scene(ctx,
            items.MI_SLING_BULLET, false, entry.monster_id, false)
        local definition = catalog.get("monsters", entry.monster_id)
        local hit = {
            attacker = player,
            attacker_name = "you",
            defender = shooter,
            definition = definition,
            damage_done = 5,
            health = ctx:get(shooter, component.HEALTH),
            weapon_entity = missile,
            projectile_name = "sling bullet",
            player_credit = true,
        }

        function battle.random(_, _, bound)
            if entry.ego == brands.VENOM and bound == 4 then
                return 1
            end

            return 0
        end

        monster_brands.apply(battle, entry.ego, hit)

        if entry.ego == brands.VENOM then
            harness.truthy(ctx:has(shooter, component.PROJECTILE_POISON),
                "Venom launcher poisons its monster target")
        else
            harness.truthy(ctx:get(shooter, component.HEALTH).current < 40,
                entry.ego .. " did not affect its monster target")
        end
    end
end

-- Holy Wrath applies to a live Demonspawn player, while positive rElec
-- stops the electrical proc before its chance and damage draws.
local function player_facing(ctx)
    local definition = catalog.get("monsters", monsters.MONS_GOBLIN)
    local holy, holy_player, holy_shooter = fixture.scene(ctx,
        items.MI_SLING_BULLET, false, nil, false)
    local choice = ctx:get(holy_player, component.PLAYER)

    choice.species_id = species.SP_DEMONSPAWN
    ctx:set(holy_player, component.PLAYER, choice)

    function holy.random()
        return 0
    end

    player_brands.apply(holy, brands.HOLY_WRATH, 5,
        definition.id, definition.name,
        ctx:get(holy_player, component.HEALTH), holy_shooter)
    harness.equal(ctx:get(holy_player, component.HEALTH).current, 19,
        "Holy Wrath gives Demonspawn its source minimum bonus")

    local shock, shock_player, shock_shooter = fixture.scene(ctx,
        items.MI_SLING_BULLET, false, nil, false)

    function shock.random()
        return 0
    end

    player_brands.apply(shock, brands.ELECTROCUTION, 5,
        definition.id, definition.name,
        ctx:get(shock_player, component.HEALTH), shock_shooter)
    harness.equal(ctx:get(shock_player, component.HEALTH).current, 12,
        "unresisted electrocution adds its source minimum")

    local resistant, resistant_player, resistant_shooter = fixture.scene(
        ctx, items.MI_SLING_BULLET, false, nil, false)
    -- Changing species alone would skip its starting mutation grants;
    -- use the production potion status to supply a live rElec pip.
    resistance_potion.extend(resistant, resistant_player, 1)

    function resistant.random()
        return 0
    end

    player_brands.apply(resistant, brands.ELECTROCUTION, 5,
        definition.id, definition.name,
        ctx:get(resistant_player, component.HEALTH), resistant_shooter)
    harness.equal(ctx:get(resistant_player, component.HEALTH).current,
        20, "positive rElec prevents the electrical brand proc")

    local venom, venom_player, venom_shooter = fixture.scene(ctx,
        items.MI_SLING_BULLET, false, nil, false)

    function venom.random(_, _, bound)
        return bound == 4 and 1 or 0
    end

    player_brands.apply(venom, brands.VENOM, 5,
        definition.id, definition.name,
        ctx:get(venom_player, component.HEALTH), venom_shooter)
    harness.equal(ctx:get(venom_player, component.POISON).amount_scaled,
        6000, "Venom launcher applies source poison dose")

    local immune, immune_player, immune_shooter = fixture.scene(ctx,
        items.MI_SLING_BULLET, false, nil, false)
    local immune_choice = ctx:get(immune_player, component.PLAYER)

    immune_choice.species_id = species.SP_GARGOYLE
    ctx:set(immune_player, component.PLAYER, immune_choice)

    function immune.random()
        return 0
    end

    player_brands.apply(immune, brands.VENOM, 5,
        definition.id, definition.name,
        ctx:get(immune_player, component.HEALTH), immune_shooter)
    harness.falsy(ctx:has(immune_player, component.POISON),
        "poison immunity prevents Venom launcher exposure")
end

-- Run both defender directions with production brand modules and ECS
-- components so target-specific resistance and status rules stay shared.
function test.run(ctx)
    monster_facing(ctx)
    player_facing(ctx)
end

return test
