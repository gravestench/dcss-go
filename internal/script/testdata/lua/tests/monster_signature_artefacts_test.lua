-- Named bosses carry their guaranteed unrand artefacts as physical items.
-- The factory, artefact history, equipment, and death owners share entities.
local artefacts = require("ids.artefacts")
local catalog = require("policy.catalog")
local component = require("constants.component")
local death = require("policy.death")
local equipment = require("policy.combat.equipment")
local factory = require("policy.population.factory")
local generation = require("policy.item_generation")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local purpose = require("constants.item_generation_purpose")
local quality = require("constants.vault_item_quality")
local save_inventory = require("policy.save.monster_inventory")
local terrain = require("constants.terrain")
local unique = require("policy.item_generation.artefacts.unique")

local test = {}

local signatures = {
    {
        monster = monsters.MONS_CEREBOV,
        artefact = artefacts.UNRAND_CEREBOV,
        slot = "weapon",
    },
    {
        monster = monsters.MONS_DISPATER,
        artefact = artefacts.UNRAND_DISPATER,
        slot = "weapon",
    },
    {
        monster = monsters.MONS_ASMODEUS,
        artefact = artefacts.UNRAND_ASMODEUS,
        slot = "weapon",
    },
    {
        monster = monsters.MONS_THE_ENCHANTRESS,
        artefact = artefacts.UNRAND_FAERIE,
        slot = "body",
    },
    {
        monster = monsters.MONS_TIAMAT,
        artefact = artefacts.UNRAND_DRAGONSKIN,
        slot = "body",
    },
}

-- Use real ECS components with a deterministic open floor. The wrapper only
-- supplies world geometry and RNG normally owned by the Go level runtime.
local function world_context(ctx)
    local world = setmetatable({}, { __index = ctx })
    local player = ctx:create()

    ctx:add(player, component.PLAYER_UNIQUE_HISTORY, {
        status = {},
        monsters = {},
        pan_states = {},
        choices = {},
        boris_killed = false,
    })

    -- Route unique history to the same run owner used by the factory.
    function world:player()
        return player
    end

    -- Keep all source draws deterministic and reject an invalid bound.
    function world:random(_, bound)
        harness.truthy(bound > 0, "monster gear RNG bound")

        return 0
    end

    -- This fixture isolates gear from terrain restrictions.
    function world:walkable()
        return true
    end

    -- The blocked branch proves placement rejects before unique history.
    function world:actor_at()
        return self.blocked and 1 or nil
    end

    -- Every trial cell is normal floor for these five land monsters.
    function world:cell()
        return terrain.DNGN_FLOOR
    end

    -- Mirror the real level's placement into the ECS position component.
    function world:place_actor(entity, level_id, x, y)
        ctx:add(entity, component.POSITION, {
            level_id = level_id,
            x = x,
            y = y,
        })
    end

    return world, player
end

-- Query the actual carrier edge so a cosmetic gear row cannot satisfy the
-- test without creating a lootable item entity.
local function signature_item(ctx, monster, artefact_id)
    for _, entity in ipairs(ctx:query({
        component.ITEM,
        component.CARRIED_BY,
        component.ITEM_ARTEFACT,
    })) do
        local carrier = ctx:get(entity, component.CARRIED_BY)
        local artefact = ctx:get(entity, component.ITEM_ARTEFACT)

        if carrier.holder == monster and
            artefact.unique_id == artefact_id then
            return entity
        end
    end

    return nil
end

-- Invalid placement is checked before gear claims the named artefact.
local function blocked_spawn_does_not_claim(ctx, world, player)
    world.blocked = true

    local spawned = pcall(factory.spawn, world,
        monsters.MONS_CEREBOV, 1, 10, 10)

    world.blocked = false

    harness.falsy(spawned, "blocked boss placement was accepted")
    harness.falsy(ctx:get(player,
        component.PLAYER_UNIQUE_HISTORY).status[artefacts.UNRAND_CEREBOV],
        "blocked placement claimed Cerebov's sword")
end

-- Every source-guaranteed signature has the correct live equipment slot,
-- unique history claim, and ordinary death drop identity.
local function bosses_carry_signatures(ctx, world, player)
    for index, signature in ipairs(signatures) do
        local boss = factory.spawn(world, signature.monster,
            1, 10 + index, 10)
        local item = signature_item(ctx, boss, signature.artefact)

        harness.truthy(item,
            signature.monster .. " lacks its signature artefact")
        harness.equal(ctx:get(item, component.EQUIPPED).slot,
            signature.slot, "signature artefact equipment slot")
        harness.truthy(ctx:get(player,
            component.PLAYER_UNIQUE_HISTORY).status[signature.artefact],
            "signature artefact has no saved unique claim")

        if signature.monster == monsters.MONS_TIAMAT then
            harness.truthy(equipment.monster_body(world, boss),
                "Tiamat's cloak is worn as her source body armour")
        end

        if signature.slot == "body" then
            harness.truthy(equipment.monster_melee(world, boss),
                signature.monster .. " lost its ordinary weapon")
        end

        save_inventory.validate(world)

        local position = ctx:get(boss, component.POSITION)

        death.drop_inventory(world, boss, position)

        harness.falsy(ctx:has(item, component.CARRIED_BY),
            "dead boss still carries its signature item")
        harness.truthy(ctx:has(item, component.POSITION),
            "signature artefact did not become floor loot")
    end
end

-- The named staff cannot enter random unique selection. A second explicit
-- source request uses the ordinary duplicate fallback and leaves the
-- first staff's saved unique claim intact.
local function repeated_signature_uses_fallback(ctx, world, player)
    local definition = catalog.get("artefacts",
        artefacts.UNRAND_DISPATER)

    harness.falsy(unique.eligible(definition),
        "signature staff entered random unique selection")

    local rolled = generation.roll(world, {
        kind_id = definition.kind_id,
        unique_id = definition.id,
        depth = 7,
        quality = quality.ORDINARY,
        allow_uniques = false,
        purpose = purpose.VAULT,
        site = "repeated signature gear test",
    })

    harness.equal(rolled.components[component.ITEM_ARTEFACT].kind,
        "random", "repeated signature uses an artefact fallback")
    harness.truthy(ctx:get(player,
        component.PLAYER_UNIQUE_HISTORY).status[definition.id],
        "fallback preserved the first signature claim")
end

-- The full factory path is the contract: gear handlers only select IDs,
-- while item generation and death own physical identity and disposition.
function test.run(ctx)
    local world, player = world_context(ctx)

    blocked_spawn_does_not_claim(ctx, world, player)
    bosses_carry_signatures(ctx, world, player)
    repeated_signature_uses_fallback(ctx, world, player)
end

return test
