-- All source chance-based monster artefacts use the same saved unique
-- history, but each owner's choice stays in its own Lua gear handler.
local artefacts = require("ids.artefacts")
local component = require("constants.component")
local catalog = require("policy.catalog")
local death = require("policy.death")
local equipment = require("policy.combat.equipment")
local factory = require("policy.population.factory")
local fixture = require("tests.fixtures.monster_gear_world")
local gear = require("policy.population.gear")
local harness = require("tests.harness")
local item_ids = require("ids.items")
local monsters = require("ids.monsters")
local monster_armour = require("policy.combat.monster_armour")
local save_inventory = require("policy.save.monster_inventory")
local status = require("constants.unique_item_status")
local streams = require("constants.rng_streams")
local brands = require("constants.weapon_brands")

local test = {}

local owners = {
    {
        monster = monsters.MONS_NIKOLA,
        artefact = artefacts.UNRAND_ARC_BLADE,
        slot = "weapon",
        fallback_plus = 4,
        fallback_brand = brands.ELECTROCUTION,
    },
    {
        monster = monsters.MONS_AMAEMON,
        artefact = artefacts.UNRAND_SNAKEBITE,
        slot = "weapon",
        fallback_plus = 1,
        fallback_brand = brands.VENOM,
    },
    {
        monster = monsters.MONS_ARACHNE,
        artefact = artefacts.UNRAND_OLGREB,
        slot = "weapon",
        fallback = item_ids.STAFF_POISON,
    },
    {
        monster = monsters.MONS_MAGGIE,
        artefact = artefacts.UNRAND_WYRMBANE,
        slot = "weapon",
        plus = 9,
    },
    {
        monster = monsters.MONS_MARGERY,
        artefact = artefacts.UNRAND_WYRMBANE,
        slot = "weapon",
        plus = 10,
    },
    {
        monster = monsters.MONS_TERENCE,
        artefact = artefacts.UNRAND_THROATCUTTER,
        slot = "weapon",
    },
    {
        monster = monsters.MONS_GRUNN,
        artefact = artefacts.UNRAND_CURSES,
        slot = "weapon",
        fallback_plus = 9,
        fallback_brand = brands.DRAINING,
    },
    {
        monster = monsters.MONS_PARGHIT,
        artefact = artefacts.UNRAND_DRAGON_KING,
        slot = "body",
        fallback = item_ids.ARM_GOLD_DRAGON_ARMOUR,
    },
    {
        monster = monsters.MONS_GASTRONOK,
        artefact = artefacts.UNRAND_PONDERING,
        slot = "body",
        fallback = item_ids.ARM_HAT,
        odds = 10,
    },
}

-- Read one live equipped entity, keeping expected names and properties in
-- production catalog definitions rather than recreating them here.
local function worn_item(ctx, monster, slot)
    local worn = equipment.worn(ctx, monster, {
        [slot] = true,
    })

    return worn[slot]
end

-- The forced winning roll must produce the named item on the real monster,
-- claim run history, pass inventory checks, and drop that same entity.
local function chance_hits(ctx)
    for index, owner in ipairs(owners) do
        local world, player = fixture.new(ctx, false)
        local monster = factory.spawn(world, owner.monster,
            1, 10 + index, 10)
        local item = fixture.signature_item(ctx, monster, owner.artefact)

        harness.truthy(item, owner.monster .. " missed its winning roll")
        harness.equal(ctx:get(item, component.EQUIPPED).slot,
            owner.slot, "chance artefact slot")
        harness.truthy(ctx:get(player,
            component.PLAYER_UNIQUE_HISTORY).status[owner.artefact],
            "chance artefact did not claim history")

        if owner.plus then
            harness.equal(ctx:get(item, component.ITEM).plus,
                owner.plus, "source Wyrmbane plus")
        end

        if owner.monster == monsters.MONS_ARACHNE then
            harness.truthy(equipment.monster_melee(world, monster),
                "Arachne cannot wield Olgreb")
        end

        save_inventory.validate(world)

        local position = ctx:get(monster, component.POSITION)

        death.drop_inventory(world, monster, position)
        harness.falsy(ctx:has(item, component.CARRIED_BY),
            "chance artefact stayed on dead monster")
        harness.truthy(ctx:has(item, component.POSITION),
            "chance artefact did not drop")
    end
end

-- A losing roll keeps an ordinary item and never claims the artefact. The
-- two special fallback kinds are source-fixed, so inspect their live kinds.
local function chance_misses(ctx)
    for index, owner in ipairs(owners) do
        local world, player = fixture.new(ctx, true)
        local monster = factory.spawn(world, owner.monster,
            1, 30 + index, 10)
        local item = worn_item(world, monster, owner.slot)

        harness.truthy(item, owner.monster .. " lost ordinary gear")
        harness.falsy(fixture.signature_item(ctx,
            monster, owner.artefact),
            "losing roll granted a named artefact")
        harness.falsy(ctx:get(player,
            component.PLAYER_UNIQUE_HISTORY).status[owner.artefact],
            "losing roll claimed unique history")

        if owner.fallback then
            harness.equal(item.item.kind_id, owner.fallback,
                "source fixed fallback")
        end

        if owner.fallback_plus then
            harness.equal(item.item.plus, owner.fallback_plus,
                "source forced weapon plus")
            harness.equal(item.item.ego, owner.fallback_brand,
                "source forced weapon brand")
        end

        if owner.monster == monsters.MONS_PARGHIT then
            harness.equal(item.item.plus, 9,
                "Parghit's forced gold scales plus")
        end

        if owner.monster == monsters.MONS_ARACHNE then
            harness.truthy(equipment.monster_melee(world, monster),
                "Arachne cannot wield her poison staff")
        end

        save_inventory.validate(world)
    end
end

-- The source performs the chance draw before checking whether a prior
-- owner already claimed Wyrmbane, even though no second copy may spawn.
local function preclaimed_unique_still_draws(ctx)
    local world, player = fixture.new(ctx, false)
    local history = ctx:get(player, component.PLAYER_UNIQUE_HISTORY)

    history.status[artefacts.UNRAND_WYRMBANE] = status.ORDINARY
    ctx:set(player, component.PLAYER_UNIQUE_HISTORY, history)

    local original_random = world.random
    local draws = 0

    -- Count only this direct helper invocation's gear roll.
    function world:random(stream, bound)
        harness.equal(stream, streams.MONSTER_GEAR,
            "chance uses monster gear stream")
        harness.equal(bound, 100, "Wyrmbane odds")
        draws = draws + 1

        return original_random(self, stream, bound)
    end

    harness.falsy(gear.chance_unique(world,
        artefacts.UNRAND_WYRMBANE, 100),
        "claimed Wyrmbane granted twice")
    harness.equal(draws, 1, "chance draw preceded history check")

    world.random = original_random

    local maggie = factory.spawn(world, monsters.MONS_MAGGIE,
        1, 55, 10)

    harness.falsy(fixture.signature_item(ctx,
        maggie, artefacts.UNRAND_WYRMBANE),
        "preclaimed Wyrmbane spawned on Maggie")
    harness.truthy(worn_item(world, maggie, "weapon"),
        "preclaimed Wyrmbane removed Maggie's weapon")
end

-- A blocked cell is rejected before HP or gear RNG and must not mark the
-- unique item ledger. Source monsters do not roll loot they cannot carry.
local function blocked_placement_does_not_draw(ctx)
    local world, player = fixture.new(ctx, false)
    local original_random = world.random
    local draws = 0

    world.blocked = true

    -- Count every random request; placement should short-circuit first.
    function world:random(stream, bound)
        draws = draws + 1

        return original_random(self, stream, bound)
    end

    local spawned = pcall(factory.spawn, world,
        monsters.MONS_NIKOLA, 1, 70, 10)

    harness.falsy(spawned, "blocked Nikola placement was accepted")
    harness.equal(draws, 0, "blocked monster rolled gear")
    harness.falsy(ctx:get(player,
        component.PLAYER_UNIQUE_HISTORY).status[artefacts.UNRAND_ARC_BLADE],
        "blocked monster claimed Arc Blade")
end

-- The two non-body armour restrictions share the same source monster
-- pickup rule, so Gastronok can wear a hat but not a dragon scale suit.
local function gastronok_hat_rule(ctx)
    local world = fixture.new(ctx, false)
    local gastronok = factory.spawn(world,
        monsters.MONS_GASTRONOK, 1, 80, 10)

    harness.truthy(monster_armour.wears_body(world, gastronok,
        catalog.get("items", item_ids.ARM_HAT)),
        "Gastronok's hat is not body armour")
    harness.falsy(monster_armour.wears_body(world, gastronok,
        catalog.get("items", item_ids.ARM_GOLD_DRAGON_ARMOUR)),
        "Gastronok wore ordinary body armour")
end

-- Margery's second source draw selects between +10 and +11. The ordinary
-- winning fixture takes the low edge; this case checks the upper edge.
local function margery_upper_plus(ctx)
    local world = fixture.new(ctx, false)
    local original_random = world.random

    -- Only the two-way plus choice changes, leaving the chance roll won.
    function world:random(stream, bound)
        if stream == streams.MONSTER_GEAR and bound == 2 then
            return 1
        end

        return original_random(self, stream, bound)
    end

    local loadout = gear.loadout(world, monsters.MONS_MARGERY, 1)

    harness.equal(loadout.primary.unique_id,
        artefacts.UNRAND_WYRMBANE, "Margery's winning artefact")
    harness.equal(loadout.primary.plus, 11,
        "Margery's upper Wyrmbane enchantment")
end

-- Each trial gets a fresh saved player ledger, while actual item entities
-- remain in the shared ECS so carrier edges and death paths stay real.
function test.run(ctx)
    chance_hits(ctx)
    chance_misses(ctx)
    preclaimed_unique_still_draws(ctx)
    blocked_placement_does_not_draw(ctx)
    gastronok_hat_rule(ctx)
    margery_upper_plus(ctx)
end

return test
