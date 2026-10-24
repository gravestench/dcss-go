-- Source: melee-attack.cc:mons_do_eyeball_confusion. The gaze runs after
-- the attack if the player and surviving monster remain adjacent.
local component = require("constants.component")
local mutations = require("ids.mutations")
local reactions = require("policy.combat.player_reactions")
local roll = require("policy.combat.roll")
local will = require("policy.magic.effects.zaps.will")

local eyeballs = {
    id = mutations.MUT_EYEBALLS,
    order = 40,
}

-- Check surviving adjacency and will resistance before applying confusion after the attack.
-- Example: Eye contact can confuse an adjacent surviving attacker after its attack resolves.
function eyeballs.after_attack(ctx, player, monster, definition, level)
    if not reactions.adjacent(ctx, player, monster) or
        roll.melee(ctx, 20) >= level or
        will.resists(ctx, definition, level * 30,
            monster, nil, player) then
        return
    end

    local duration = 30 + roll.melee(ctx, 100)
    local current = ctx:get(monster, component.MONSTER_CONFUSION)
    local next_state = {
        remaining_aut = math.max(current and current.remaining_aut or 0,
            duration),
    }

    ctx:emit("combat", "The eyeballs on your body gaze at the " ..
        definition.name .. ".")

    if current then
        ctx:set(monster, component.MONSTER_CONFUSION, next_state)
    else
        ctx:add(monster, component.MONSTER_CONFUSION, next_state)
    end
end

reactions.register(eyeballs)

return eyeballs
