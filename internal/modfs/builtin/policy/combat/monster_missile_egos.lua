-- A thrown monster missile keeps its saved ego while each landed contact
-- resolves a separate effect. Validate before AI spends the shot, so an
-- unknown modded ego cannot cause a half-executed turn.
local egos = require("constants.missile_egos")
local items = require("ids.items")
local chaos = require("policy.combat.chaos_missile")
local elemental = require(
    "policy.combat.monster_missile_egos.elemental")
local poison = require("policy.combat.monster_missile_egos.poison")
local silver = require("policy.combat.monster_missile_egos.silver")
local mind = require("policy.combat.monster_missile_egos.mind")
local dispersal = require(
    "policy.combat.monster_missile_egos.dispersal")
local chaos_inner = require("policy.combat.monster_missile_egos.chaos")

local missile_egos = {}

-- Source-generated darts have coatings; ordinary thrown stacks can carry
-- the catalog brands and explicit DES egos. Stones are only plain or Chaos.
local known = {
    [egos.BLINDING] = true,
    [egos.CHAOS] = true,
    [egos.CURARE] = true,
    [egos.DISPERSAL] = true,
    [egos.EXPLODING] = true,
    [egos.FLAME] = true,
    [egos.FRENZY] = true,
    [egos.FROST] = true,
    [egos.POISONED] = true,
    [egos.SILVER] = true,
}

local coatings = {
    [egos.BLINDING] = true,
    [egos.CURARE] = true,
    [egos.FRENZY] = true,
    [egos.POISONED] = true,
}

-- The owner receives the projectile kind because several source missile
-- kinds share one contact resolver but have different legal brand pools.
function missile_egos.validate(kind_id, item)
    local ego = item.ego or ""

    if ego == "" then
        if kind_id == items.MI_DART then
            error("an uncoated dart cannot use monster dart contact")
        end

        return
    end

    if not known[ego] or
        kind_id == items.MI_DART and not coatings[ego] or
        kind_id == items.MI_STONE and ego ~= egos.CHAOS then
        error("unsupported monster missile ego " .. tostring(ego))
    end
end

-- Chaos chooses a temporary ego for this contact. The item component keeps
-- its saved Chaos value, and a selected direct effect follows the same path
-- as an ordinary branded stack.
local player_effects = {
    [egos.FLAME] = elemental.flame,
    [egos.FROST] = elemental.frost,
    [egos.POISONED] = poison.poisoned,
    [egos.CURARE] = poison.curare,
    [egos.SILVER] = silver.apply,
    [egos.BLINDING] = mind.blinding,
    [egos.FRENZY] = mind.frenzy,
    [egos.DISPERSAL] = dispersal.apply,
    [egos.CHAOS] = chaos_inner.apply,
}

-- Only a landed hit on a surviving player enters this function. Contact,
-- reflection, and base HP damage remain with the ranged action owner.
function missile_egos.apply_player(ctx, attacker, definition, kind,
    ego, damage)
    local selected = ego

    if selected == egos.CHAOS then
        selected = chaos.choose(ctx, ctx:player())
    end

    local apply = player_effects[selected]

    if not apply then
        error("unsupported landed monster missile ego " ..
            tostring(selected))
    end

    apply(ctx, attacker, definition, kind, damage)

    return selected
end

return missile_egos
