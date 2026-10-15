local formulas = require("policy.character.formulas")
local roll = require("policy.combat.roll")
local player_health = require("policy.combat.player_health")
local player_drain = require("policy.combat.player_drain")

local draining = {}

local function recover(ctx, actor, xp)
    local state = ctx:get(actor, "status.drain")

    if not state or state.amount <= 0 then
        return
    end

    local training = ctx:get(actor, "core.skill_training")
    local health = ctx:get(actor, "core.health")

    if not training or not health then
        error("drained player lacks training or health")
    end

    -- player.cc:2404-2428: XP removes temporary HP drain using the
    -- skill cost level before this kill's training step.
    local cost = formulas.skill_point_cost(training.cost_level)
    local amount = roll.random_divide(ctx, xp, 4 * cost)
    amount = math.floor(amount * (1 + state.amount / 25))
    amount = math.min(state.amount, amount)

    if amount == 0 then
        return
    end

    state.amount = state.amount - amount
    health.max = health.max + amount
    ctx:set(actor, "core.health", health)

    if state.amount == 0 then
        ctx:remove(actor, "status.drain")
        ctx:emit("recovery", "Your life force feels restored.")
    else
        ctx:set(actor, "status.drain", state)
    end
end

draining.recover = recover

function draining.apply(ctx, hit)
    local extra = math.floor((1 + roll.melee(ctx, hit.damage_done)) / 2)
    hit.health = player_health.damage(ctx, hit.defender, extra,
        false, hit.attacker)

    -- ouch.cc:378-413: drain_player(1 + damage_done) lowers temporary
    -- max HP by at least one, capped so the real player retains one HP.
    hit.health = player_drain.apply(ctx, hit.defender,
        1 + hit.damage_done)
end

return draining
