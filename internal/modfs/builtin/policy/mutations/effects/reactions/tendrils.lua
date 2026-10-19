-- Source: melee-attack.cc:mons_do_tendril_disarm and monster.cc:disarm.
local component = require("constants.component")
local mutations = require("ids.mutations")
local reactions = require("policy.combat.player_reactions")
local equipment = require("policy.combat.equipment")
local roll = require("policy.combat.roll")
local vision = require("policy.character.vision")

local tendrils = {
    id = mutations.MUT_TENDRILS,
    order = 50,
}

-- A disarm reaction requires line of sight at the attack's current positions;
-- use the player's effective vision radius so darkness and species rules apply.
local function visible(ctx, player, monster)
    local origin = ctx:get(player, component.POSITION)
    local target = ctx:get(monster, component.POSITION)

    return ctx:visible(origin.level_id, origin.x, origin.y,
        vision.radius(ctx, player), target.x, target.y)
end

-- Remove equipment links before dropping the disarmed weapon, keeping monster inventory consistent.
-- Example: successful Tendrils disarmament removes carried and equipped links before dropping the weapon.
function tendrils.after_attack(ctx, player, monster, definition)
    if roll.melee(ctx, 5) ~= 0 or
        roll.melee(ctx, 35) < definition.hd then
        return
    end

    local equipped = equipment.worn(ctx, monster, { weapon = true })
    local weapon = equipped.weapon

    if not weapon or not reactions.adjacent(ctx, player, monster) or
        not visible(ctx, player, monster) then
        return
    end

    local position = ctx:get(player, component.POSITION)

    if not ctx:walkable(position.level_id, position.x, position.y) then
        return
    end

    ctx:remove(weapon.entity, component.EQUIPPED)
    ctx:remove(weapon.entity, component.CARRIED_BY)
    ctx:add(weapon.entity, component.POSITION, {
        level_id = position.level_id,
        x = position.x,
        y = position.y,
    })

    ctx:emit("combat", "Your tendrils lash around the " ..
        definition.name .. "'s " .. weapon.definition.name ..
        " and pull it to the ground!")
end

reactions.register(tendrils)

return tendrils
