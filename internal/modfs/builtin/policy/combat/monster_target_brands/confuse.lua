local confusion = require("policy.magic.effects.statuses.confusing_touch")
local component = require("constants.component")
local monster_stats = require("policy.combat.monster_stats")
local catalog = require("policy.catalog")
local roll = require("policy.combat.roll")
local flags = require("constants.monster_flags")

local brand = {}

-- Monster::confuse checks clarity before sending a Chaos outcome through
-- the beam enchantment handler; direct mod calls must keep that immunity.
local function has_clarity(definition)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.CLARITY then
            return true
        end
    end

    return false
end

-- Example: brand.apply(ctx, hit) with susceptible defender -> attempts confusion after contact
-- A landed confusing hit checks the target's susceptibility before storing the debuff.
function brand.apply(ctx, hit)
    -- Source: attack.cc:SPWPN_CONFUSE. A monster's Chaos result acts like
    -- AF_CONFUSE: only one in three contacts reaches the enchantment. The
    -- 1..3+HD value is beam strength, which the shared status policy then
    -- converts to duration; it is not a literal number of turns.
    if not ctx:has(hit.attacker, component.PLAYER) then
        if roll.melee(ctx, 3) ~= 0 or
            has_clarity(hit.definition) then
            return
        end

        local actor = ctx:get(hit.attacker, component.ACTOR)
        local definition = catalog.get("monsters", actor.kind_id)
        local hd = monster_stats.hit_dice(ctx, hit.attacker, definition)
        local power = 1 + roll.melee(ctx, 3 + hd)

        confusion.apply_unresisted(ctx, hit.defender,
            hit.definition, power)
        return
    end

    -- A player's confusing effect still checks the target's will before
    -- using the beam power-to-duration rule.
    confusion.apply(ctx, hit.defender, hit.definition,
        math.max(1, hit.damage_done))
end

return brand
