local damage = require("policy.magic.damage")
local registry = require("policy.magic.effects.registry")
local target = require("policy.magic.effects.direct.target")

-- Source: spl-goditem.cc:cast_smiting. Empty and submerged targets still
-- consume a cast so the spell cannot reveal unseen monsters for free.
local function resolve(ctx, player, intent, _, power)
    local monster = target.at_aim(ctx, player, intent)

    if not monster then
        ctx:emit("spell", "There is nothing there to smite.")
        return
    end

    local definition = damage.monster(ctx, monster)

    if not definition then
        ctx:emit("spell", "There is nothing there to smite.")
        return
    end

    local sides = math.floor(power / 8)

    if ctx:random("spell", 8) < power % 8 then
        sides = sides + 1
    end

    local dealt = 6

    if sides > 0 then
        dealt = dealt + 3 + ctx:random("spell", sides) +
            ctx:random("spell", sides) + ctx:random("spell", sides)
    end

    damage.apply(ctx, monster, dealt)
    ctx:emit("spell", "You smite the " .. definition.name .. ".")
end

local spells = require("ids.spells")
local effect = {}

function effect.can_target(ctx, player)
    return target.visible_hostile(ctx, player, 7, false)
end

effect.resolve = resolve

registry.add(spells.SPELL_SMITING, effect)

return effect
