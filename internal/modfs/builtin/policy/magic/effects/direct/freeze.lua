local damage = require("policy.magic.damage")
local registry = require("policy.magic.effects.registry")
local target = require("policy.magic.effects.direct.target")

-- Source: spl-damage.cc:freeze_damage and cast_freeze. Empty and submerged
-- targets still consume the cast to prevent probing for unseen monsters.
local function resolve(ctx, player, intent, _, power)
    local monster = target.at_aim(ctx, player, intent)

    if not monster then
        ctx:emit("spell", "There is nothing close enough to freeze.")
        return
    end

    local definition = damage.monster(ctx, monster)

    if not definition then
        ctx:emit("spell", "There is nothing close enough to freeze.")
        return
    end

    local sides = 3 + math.floor(math.min(power, 25) / 3)
    local rolled = 1 + ctx:random("spell", sides)
    local dealt = damage.monster_elemental(ctx, monster, rolled,
        "MR_RES_COLD")

    damage.apply(ctx, monster, dealt)

    if dealt == 0 then
        ctx:emit("spell", "You freeze the " .. definition.name ..
            " but do no damage.")
    else
        ctx:emit("spell", "You freeze the " .. definition.name .. ".")
    end
end

local spells = require("ids.spells")
local effect = {}

-- Example: A hostile next to the player makes Freeze targetable; a monster two cells away does not.
-- Freeze has adjacent reach, so a distant visible foe cannot make the spell targetable.
function effect.can_target(ctx, player)
    return target.visible_hostile(ctx, player, 1, false)
end

effect.resolve = resolve

registry.add(spells.SPELL_FREEZE, effect)

return effect
