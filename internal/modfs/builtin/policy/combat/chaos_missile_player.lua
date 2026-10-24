-- Monster-thrown Chaos ammunition resolves after the normal ranged hit.
-- Its effects reuse player damage and status owners, so the projectile
-- adds no Xom-only state to the character or monster.
local chaos = require("policy.combat.chaos_missile")
local flavours = require("constants.beam_flavours")
local missile_egos = require("constants.missile_egos")
local weapon_brands = require("constants.weapon_brands")
local streams = require("constants.rng_streams")

local effect = {}

local inner = {
    { flavour = flavours.BEAM_POLYMORPH, weight = 2 },
    { flavour = flavours.BEAM_BERSERK, weight = 5 },
    { flavour = flavours.BEAM_HASTE, weight = 10 },
    { flavour = flavours.BEAM_MIGHT, weight = 10 },
    { flavour = flavours.BEAM_AGILITY, weight = 10 },
    { flavour = flavours.BEAM_INVISIBILITY, weight = 10 },
    { flavour = flavours.BEAM_SLOW, weight = 10 },
    { flavour = flavours.BEAM_PARALYSIS, weight = 5 },
    { flavour = flavours.BEAM_PETRIFY, weight = 5 },
}

-- The self-selected Chaos band enters attack.cc's chaos effect table.
-- Player-inapplicable clone and shifter entries are absent from this pool.
function effect.inner_effect(ctx, attacker, player, damage)
    local draw = ctx:random(streams.MELEE, 67)
    local selected

    for _, choice in ipairs(inner) do
        draw = draw - choice.weight

        if draw < 0 then
            selected = choice.flavour
            break
        end
    end

    local boons = require("policy.combat.monster_area.chaos_boons")

    if boons.handles(selected) then
        boons.apply(ctx, attacker, player, selected, damage)
        return
    end

    local hexes = require("policy.combat.monster_area.chaos_hexes")

    hexes.apply(ctx, attacker, player, selected, damage)
end

-- Ordinary flaming and freezing brands already own the bonus damage and
-- player resistance calculations. Their hit envelope carries attribution.
local function elemental(ctx, attacker, definition, damage, brand)
    local brands = require("policy.combat.brands")
    local player = ctx:player()
    local health = ctx:get(player, "core.health")

    brands.apply(ctx, brand, damage, definition.id,
        definition.name, health, attacker)
end

-- Curare adds poison, asphyxiation, and slow after the ordinary stone hit.
local function curare(ctx, attacker, definition)
    local brands = require("policy.combat.brands")
    local health = require("policy.combat.player_health")
    local slow = require("policy.character.slow")
    local player = ctx:player()
    local extra = 2 + ctx:random(streams.MELEE, 6) +
        ctx:random(streams.MELEE, 6)

    brands.poison(ctx, 2, definition.id)
    local remaining = health.damage(ctx, player, extra, false, attacker)

    if remaining.current > 0 then
        slow.apply(ctx, player, 10)
    end
end

-- Dispersal samples two legal spaces and chooses the one farther from
-- the shooter; a failed landing leaves the player at the impact cell.
local function disperse(ctx, attacker)
    local dispersal = require("policy.combat.dispersal")
    local player = ctx:player()
    local position = ctx:get(player, "core.position")
    local source = ctx:get(attacker, "core.position")
    local first = dispersal.nearby_space(ctx, position)
    local second = dispersal.nearby_space(ctx, position)

    if not first or not second then
        return
    end

    local first_distance = math.max(math.abs(first.x - source.x),
        math.abs(first.y - source.y))
    local second_distance = math.max(math.abs(second.x - source.x),
        math.abs(second.y - source.y))
    local destination = second_distance > first_distance and second or first

    ctx:move_actor(player, position.level_id,
        destination.x, destination.y)
end

-- One ranged brand acts on the surviving player. Every branch delegates
-- the saved effect to the same owner as spells, poison, or melee brands.
function effect.apply(ctx, attacker, definition, _, damage)
    local player = ctx:player()
    local selected = chaos.choose(ctx, player)

    if selected == missile_egos.FLAME then
        elemental(ctx, attacker, definition,
            damage, weapon_brands.FLAMING)
    elseif selected == missile_egos.FROST then
        elemental(ctx, attacker, definition,
            damage, weapon_brands.FREEZING)
    elseif selected == missile_egos.POISONED then
        if ctx:random(streams.MELEE, 4) ~= 0 then
            local brands = require("policy.combat.brands")
            local amount = 6 + ctx:random(streams.MELEE, 8) +
                ctx:random(streams.MELEE,
                    math.max(1, math.floor(damage * 3 / 2)))

            brands.poison(ctx, amount, definition.id)
        end
    elseif selected == missile_egos.CHAOS then
        effect.inner_effect(ctx, attacker, player, damage)
    elseif selected == missile_egos.BLINDING then
        local confusion = require("policy.magic.player_confusion")

        confusion.extend(ctx, player, math.floor(damage / 3))
    elseif selected == missile_egos.FRENZY then
        local rage = require("policy.character.rage")

        rage.begin(ctx, player, streams.MELEE)
    elseif selected == missile_egos.CURARE then
        curare(ctx, attacker, definition)
    elseif selected == missile_egos.DISPERSAL then
        disperse(ctx, attacker)
    end

    return selected
end

return effect
