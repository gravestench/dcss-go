local confusion = require("policy.magic.effects.statuses.confusing_touch")
local component = require("constants.component")
local monster_stats = require("policy.combat.monster_stats")
local catalog = require("policy.catalog")
local roll = require("policy.combat.roll")
local flags = require("constants.monster_flags")
local form_ids = require("constants.form_ids")
local holiness = require("constants.monster_holiness")
local player_status = require("policy.magic.effects.statuses.player")

local brand = {}

-- Spores cannot affect bodies that do not breathe; source holiness, rather
-- than a name list, keeps this true for every newly registered monster.
local function unbreathing(definition)
    for _, kind in ipairs(definition.holiness or {}) do
        if kind == holiness.UNDEAD or kind == holiness.NONLIVING or
            kind == holiness.PLANT then
            return true
        end
    end

    return false
end

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

    local form = ctx:get(hit.attacker, component.PLAYER_FORM)

    if form and form.remaining_aut > 0 and
        form.form_id == form_ids.FUNGUS then
        -- An active Confusing Touch overrides the form's innate brand. Its
        -- separate contact hook owns the spell's power and consumption.
        if player_status.confusing_touch_active(ctx, hit.attacker) or
            unbreathing(hit.definition) then
            return
        end

        local hd = monster_stats.hit_dice(ctx, hit.defender,
            hit.definition)
        local skipped = math.max(0,
            math.floor(80 * (24 - hd) / 24))

        -- Source attack.cc only applies the enchantment when the HD-scaled
        -- chance fails. Higher-HD monsters are therefore more susceptible.
        local triggers = roll.melee(ctx, 100) >= skipped

        if triggers and not has_clarity(hit.definition) then
            confusion.apply_innate(ctx, hit.defender, hit.definition)
        end

        return
    end

    -- A player's ordinary confusing effect still checks target will before
    -- using the beam power-to-duration rule.
    confusion.apply(ctx, hit.defender, hit.definition,
        math.max(1, hit.damage_done))
end

return brand
