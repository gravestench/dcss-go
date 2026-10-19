-- Source: melee-attack.cc:apply_black_mark_effects.
local capabilities = require("constants.mutation_capabilities")
local component = require("constants.component")
local mutations = require("ids.mutations")
local catalog = require("policy.catalog")
local drain = require("policy.combat.monster_drain")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local effects = require("policy.mutations.effects.registry")

local black_mark = {}

-- Scale antimagic duration from actual melee damage, so a glancing hit does
-- not impose the same spell suppression as a heavy blow.
local function antimagic(ctx, player, target, definition, damage)
    enfeeble.apply_antimagic(ctx, target, definition, damage * 8)
end

-- Route the fixed weakness duration through the shared status owner, which
-- handles immunities and duration stacking for this monster.
local function weakness(ctx, player, target, definition)
    enfeeble.apply_weak(ctx, target, definition, 6)
end

-- Use the ordinary drain effect with the player as source so kill credit and
-- monster resistance remain consistent with other draining attacks.
local function draining(ctx, player, target, definition)
    drain.apply(ctx, target, definition, player)
end

-- Trigger only from damaging hits, then choose a status compatible with the defender's live state.
-- Example: a damaging melee hit can choose antimagic, weakness, or draining if the target supports them.
function black_mark.after_melee(_, ctx, player, hit)
    if hit.damage <= 0 or ctx:random("mutation", 5) ~= 0 then
        return
    end

    local health = ctx:get(hit.target, component.HEALTH)
    local actor = ctx:get(hit.target, component.ACTOR)

    if not health or health.current <= 0 or not actor then
        return
    end

    local definition = catalog.get("monsters", actor.kind_id)
    local choices = {}

    if enfeeble.antimagic_susceptible(definition) then
        choices[#choices + 1] = antimagic
    end

    if enfeeble.has_attacks(definition) then
        choices[#choices + 1] = weakness
    end

    if drain.resistance(ctx, hit.target, definition) < 3 then
        choices[#choices + 1] = draining
    end

    if #choices == 0 then
        return
    end

    local selected = ctx:random("mutation", #choices) + 1

    choices[selected](ctx, player, hit.target, definition, hit.damage)
end

effects.add(mutations.MUT_BLACK_MARK, {
    [capabilities.AFTER_MELEE_HIT] = black_mark.after_melee,
})

return black_mark
