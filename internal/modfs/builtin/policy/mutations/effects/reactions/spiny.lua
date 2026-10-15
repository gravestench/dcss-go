-- Source: melee-attack.cc:do_spines. This happens after shield contact,
-- before the monster's hit lands, and may kill the attacker.
local component = require("constants.component")
local mutations = require("ids.mutations")
local reactions = require("policy.combat.player_reactions")
local monster_defense = require("policy.combat.monster_defense")
local damage = require("policy.magic.damage")
local roll = require("policy.combat.roll")

local spiny = {
    id = mutations.MUT_SPINY,
    order = 10,
}

function spiny.before_contact(ctx, player, monster, definition, level)
    if not reactions.adjacent(ctx, player, monster) or
        roll.melee(ctx, 2) ~= 0 then
        return
    end

    local progress = ctx:get(player, component.PROGRESSION)
    local upper = roll.random_divide(ctx, progress.level * 2, 3) +
        level * 3
    local raw = level + roll.melee(ctx, upper - level + 1)
    local armour = monster_defense.armour(ctx, monster, definition)
    local hurt = math.max(0, raw - roll.armour(ctx, armour))

    if hurt <= 0 then
        return
    end

    ctx:emit("combat", "The " .. definition.name ..
        " is struck by your spines.")
    damage.apply(ctx, monster, hurt)
end

reactions.register(spiny)

return spiny
