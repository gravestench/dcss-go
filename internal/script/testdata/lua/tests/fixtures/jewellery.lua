-- Jewellery tests start with a human Fighter whose selected items are known;
-- carry() creates an item-holder relation without wearing the item.

local component = require("constants.component")
local item_ids = require("ids.items")
local jobs = require("ids.jobs")
local species = require("ids.species")

local fixture = {}

-- Give jewellery tests a minimal player with the same ECS components as equipment policy reads.
function fixture.player(ctx, species_id)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species_id or species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Jewellery test",
        starting_weapon_id = item_ids.WPN_UNARMED,
    })
    ctx:add(player, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.COMBAT, { shield_blocks = 0 })
    ctx:add(player, component.ITEM_KNOWLEDGE, {
        known_types = {
            [item_ids.RING_PROTECTION] = true,
            [item_ids.RING_MAGICAL_POWER] = true,
            [item_ids.AMU_REFLECTION] = true,
            [item_ids.AMU_REGENERATION] = true,
            [item_ids.AMU_MANA_REGENERATION] = true,
        },
        appearance_seeds = {},
    })

    local proxy = setmetatable({}, { __index = ctx })

    -- Keep the fixture's player identity available through the production context API.
    function proxy.player()
        return player
    end

    return proxy, player
end

-- Create a carried item without equipping it so each test can choose the active slot.
function fixture.carry(ctx, player, kind_id, plus)
    local entity = ctx:create()

    ctx:add(entity, component.ITEM, {
        kind_id = kind_id,
        quantity = 1,
        plus = plus or 0,
        charges = 0,
        ego = "",
    })
    ctx:add(entity, component.CARRIED_BY, { holder = player })

    return entity
end

return fixture
