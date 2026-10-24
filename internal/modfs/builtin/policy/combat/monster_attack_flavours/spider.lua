-- AF_SPIDER is Broodmother's wound birth. The bite chooses exactly one
-- child after contact; the ordinary summon owner stores and ages it.
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local roll = require("policy.combat.roll")
local spiders = require("policy.combat.monster_summons.spiders")
local summons = require("policy.magic.effects.summons.common")

local spider = {}

-- A damage-free contact cannot leave a wound. The source's one-in-three
-- chance precedes species selection and placement, so failed chances
-- consume no summon randomness or ECS entities.
function spider.apply(ctx, hit)
    local physical = hit.physical_damage or hit.damage_done or 0

    if physical <= 0 or roll.melee(ctx, 3) ~= 0 then
        return false
    end

    local attacker = ctx:get(hit.attacker, component.ACTOR)
    local anchor = ctx:get(hit.defender, component.POSITION)
    local power = hit.hit_dice * 12
    local kind_id = spiders.pick(ctx, power)
    local child = summons.spawn(ctx, hit.attacker, attacker.kind_id,
        kind_id, 3, nil, {
            anchor = anchor,
            source_category = categories.MONSTERS,
            silent_failure = true,
        })

    if not child then
        return false
    end

    ctx:emit(channels.COMBAT,
        "A spider bursts forth from the wound!")

    return true
end

return spider
