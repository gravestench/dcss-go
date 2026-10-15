-- Source: melee-attack.cc:do_passive_freeze. A landed adjacent hit
-- triggers cold retaliation even when the hit dealt no damage.
local mutations = require("ids.mutations")
local reactions = require("policy.combat.player_reactions")
local damage = require("policy.magic.damage")
local resistances = require("constants.resistance_ids")
local roll = require("policy.combat.roll")

local freeze = {
    id = mutations.MUT_PASSIVE_FREEZE,
    order = 20,
}

function freeze.after_hit(ctx, player, monster, definition)
    if not reactions.adjacent(ctx, player, monster) then
        return
    end

    local raw = roll.melee(ctx, 11)
    local hurt = damage.monster_elemental(ctx, monster, raw,
        resistances.COLD)

    if hurt <= 0 then
        return
    end

    ctx:emit("combat", "The " .. definition.name .. " is very cold.")
    damage.apply(ctx, monster, hurt)
end

reactions.register(freeze)

return freeze
