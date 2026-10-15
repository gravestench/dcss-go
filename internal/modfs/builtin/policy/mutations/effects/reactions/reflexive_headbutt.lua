-- Source: melee-attack.cc:attack and do_minotaur_retaliation. A missed
-- adjacent monster attack gives a horned Minotaur one retaliation chance.
local auxiliary = require("policy.combat.auxiliary")
local melee = require("policy.combat.melee")
local monster_defense = require("policy.combat.monster_defense")
local monster_health = require("policy.combat.monster_health")
local mutations = require("ids.mutations")
local reactions = require("policy.combat.player_reactions")

local headbutt = {
    id = mutations.MUT_REFLEXIVE_HEADBUTT,
    order = 15,
}

function headbutt.after_miss(ctx, player, monster, definition)
    if not reactions.adjacent(ctx, player, monster) then
        return
    end

    local input = auxiliary.input(ctx, monster, definition)
    input.defender_ev = monster_defense.evasion(ctx, monster, definition)
    input.defender_ac = monster_defense.armour(ctx, monster, definition)

    local outcome = melee.reflexive_headbutt(ctx, input)

    if not outcome.attempted then
        return
    end

    local health, dealt = monster_health.damage(ctx, monster,
        outcome.damage, player)

    if dealt > 0 and health.current == 0 then
        ctx:signal("player_kill", monster)
    end

    ctx:emit("combat", "You furiously retaliate!")

    local message = "You headbutt the " .. definition.name .. "."

    if outcome.damage == 0 then
        message = "You headbutt the " .. definition.name ..
            ", but do no damage."
    end

    ctx:emit("combat", message)
end

reactions.register(headbutt)

return headbutt
