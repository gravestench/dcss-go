-- Mutate and Chaotic natural contacts reuse the mutation and chaos owners
-- already shared with beams, spells, and weapon brands. This file only
-- decides the contact chance and which source flavour runs next.
local catalog = require("policy.catalog")
local choice = require("policy.combat.chaos_choice")
local component = require("constants.component")
local flavours = require("constants.attack_flavours")
local malmutation = require("policy.monsters.malmutation")
local monster_effects = require(
    "policy.combat.monster_target_brands.chaos_effects")
local player_effects = require(
    "policy.combat.monster_missile_egos.chaos")
local player_malmutation = require("policy.mutations.malmutate")
local roll = require("policy.combat.roll")
local streams = require("constants.rng_streams")
local brands = require("constants.weapon_brands")

local alteration = {}

local selected_flavour = {
    [brands.FLAMING] = flavours.FIRE,
    [brands.FREEZING] = flavours.COLD,
    [brands.ELECTROCUTION] = flavours.ELECTRICITY,
    [brands.VENOM] = flavours.POISON,
    [brands.DRAINING] = flavours.DRAIN,
    [brands.VAMPIRISM] = flavours.VAMPIRIC,
    [brands.HOLY_WRATH] = flavours.HOLY,
    [brands.ANTIMAGIC] = flavours.ANTIMAGIC,
    [brands.CONFUSE] = flavours.CONFUSE,
    [brands.DISTORTION] = flavours.DISTORT,
}

-- A natural hit must pierce armour before either alteration flavour rolls.
-- Spirit Shield and other later HP absorption do not cancel source contact.
local function reached_body(hit)
    return (hit.physical_damage or 0) > 0
end

-- Player mutation resistance and undead decomposition belong to the
-- existing character transition. Monsters use their projected live body.
function alteration.mutate(ctx, hit)
    if not reached_body(hit) or roll.melee(ctx, 4) ~= 0 then
        return false
    end

    if ctx:has(hit.defender, component.PLAYER) then
        local reason = (hit.attacker_name or "monster") ..
            " mutagenic touch"
        local result = player_malmutation.apply(ctx, hit.defender,
            reason)

        return result and (result.kind == "granted" or
            result.kind == "decomposed") or false
    end

    local actor = ctx:get(hit.defender, component.ACTOR)
    local definition = hit.defender_definition or
        catalog.get("monsters", actor.kind_id)

    -- The contact gate belongs to melee, while trait and duration draws
    -- belong to mutation so combat order cannot perturb later mutations.
    return malmutation.apply(ctx, hit.defender,
        definition, streams.MUTATION)
end

-- The inner Chaos band is spell-like rather than an ordinary element or
-- brand. Reuse each actor type's existing chaos effect table directly.
local function inner_chaos(ctx, hit)
    if ctx:has(hit.defender, component.PLAYER) then
        player_effects.apply(ctx, hit.attacker, nil, nil,
            hit.physical_damage)

        return true
    end

    monster_effects.apply(ctx, {
        attacker = hit.attacker,
        defender = hit.defender,
        definition = hit.defender_definition,
        damage_done = hit.physical_damage,
    }, streams.MELEE)

    return true
end

-- Source attack.cc selects an eligible brand ID as a token, then the
-- natural-attack path dispatches its corresponding flavour formula. The
-- lazy import avoids a module cycle with the central flavour dispatcher.
function alteration.chaotic(ctx, hit)
    if not reached_body(hit) then
        return false
    end

    local selected = choice.choose(ctx, {
        defender = hit.defender,
        definition = hit.defender_definition,
    })

    if selected == brands.CHAOS then
        return inner_chaos(ctx, hit)
    end

    local flavour_id = selected_flavour[selected]

    if not flavour_id then
        error("chaos chose an unmapped natural attack flavour")
    end

    local chosen_hit = {}

    for key, value in pairs(hit) do
        chosen_hit[key] = value
    end

    chosen_hit.damage_done = hit.physical_damage

    return require("policy.combat.monster_attack_flavours")
        .apply(ctx, flavour_id, chosen_hit)
end

return alteration
