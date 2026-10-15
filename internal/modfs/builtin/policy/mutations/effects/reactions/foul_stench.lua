-- Source: melee-attack.cc:emit_foul_stench. Only a damaging adjacent
-- hit may leave a short miasma cloud at the attacker's square.
local component = require("constants.component")
local mutations = require("ids.mutations")
local reactions = require("policy.combat.player_reactions")
local miasma = require("policy.magic.effects.statuses.miasma_cloud")
local roll = require("policy.combat.roll")
local time = require("constants.time")

local stench = {
    id = mutations.MUT_FOUL_STENCH,
    order = 30,
}

function stench.after_hit(ctx, player, monster, _, level, damage_done)
    if damage_done <= 0 or
        not reactions.adjacent(ctx, player, monster) or
        roll.melee(ctx, 20) >= level * 3 - 1 then
        return
    end

    local position = ctx:get(monster, component.POSITION)

    if not miasma.available(ctx, position.level_id, position.x,
        position.y) then
        return
    end

    local duration = (5 + roll.melee(ctx, 6)) * time.AUT_PER_TURN

    if miasma.place(ctx, position.level_id, position.x,
        position.y, duration) then
        ctx:emit("combat", "You emit a cloud of foul miasma!")
    end
end

reactions.register(stench)

return stench
