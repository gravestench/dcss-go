-- One monster melee action has an ordered source attack sequence. The
-- actor's saved head count may repeat the first catalog slot before the
-- remaining slots; the catalog alone cannot identify that live count.
local catalog = require("policy.catalog")
local component = require("constants.component")
local attack_types = require("constants.monster_attack_types")
local flavours = require("constants.attack_flavours")
local monsters = require("ids.monsters")
local roll = require("policy.combat.roll")

local sequence = {}

local derived_species = {
    [monsters.MONS_ZOMBIE] = true,
    [monsters.MONS_SKELETON] = true,
    [monsters.MONS_SIMULACRUM] = true,
    [monsters.MONS_SPECTRAL_THING] = true,
    [monsters.MONS_BOUND_SOUL] = true,
}

local blunt_undead_attacks = {
    [attack_types.STING] = true,
    [attack_types.SPORE] = true,
    [attack_types.TOUCH] = true,
    [attack_types.ENGULF] = true,
}

local preserved_undead_flavours = {
    [flavours.REACH] = true,
    [flavours.CRUSH] = true,
    [flavours.TRAMPLE] = true,
}

-- Only derived undead use an authored base as their living attack source.
-- Other DES base tags do not change the actor's melee body.
local function attack_base(ctx, actor, definition)
    if not derived_species[definition.species_id] then
        return definition
    end

    local overrides = ctx:get(actor, component.VAULT_ACTOR_OVERRIDES)

    if not overrides or overrides.base_id == "" then
        return definition
    end

    return catalog.get("monsters", overrides.base_id)
end

-- Source zombies keep eighty percent of base attack damage and only the
-- reach, crush, or trample flavour. Spectral and icy bodies replace the
-- others with their own draining or cold contact.
local function undead_attack(definition, attack)
    local flavour = attack.flavour_id

    if not preserved_undead_flavours[flavour] then
        if definition.species_id == monsters.MONS_SIMULACRUM then
            flavour = flavours.COLD
        elseif definition.species_id ==
            monsters.MONS_SPECTRAL_THING then
            flavour = flavours.DRAIN
        else
            flavour = flavours.PLAIN
        end
    end

    return {
        type_id = blunt_undead_attacks[attack.type_id] and
            attack_types.HIT or attack.type_id,
        flavour_id = flavour,
        damage = math.max(1, math.floor(attack.damage * 4 / 5)),
    }
end

-- Derived hydras inherit their base species' head attacks. Other undead
-- retain their ordinary four slots, and serpent variants share three heads.
local function head_kind(base)
    if base.genus_id == monsters.MONS_HYDRA then
        return base.id == monsters.MONS_LERNAEAN_HYDRA and 27 or 4
    end

    if base.species_id == monsters.MONS_SERPENT_OF_HELL then
        return 3
    end

    return nil
end

-- Source `mons_attack_spec` maps the first N head attempts back to slot
-- one, then visits slots two through four. Empty slots consume no contact.
function sequence.for_actor(ctx, actor, definition)
    local base = attack_base(ctx, actor, definition)
    local attacks = base.attacks or {}
    local heads = ctx:get(actor, component.MONSTER_HYDRA_HEADS)
    local count = head_kind(base)
    local first_count = count and
        (heads and heads.count > 0 and heads.count or count) or 1
    local ordered = {}

    for index, attack in ipairs(attacks) do
        if attack.type_id ~= attack_types.NONE then
            local current = base ~= definition and
                undead_attack(definition, attack) or attack
            local repeats = index == 1 and first_count or 1

            for _ = 1, repeats do
                ordered[#ordered + 1] = {
                    slot = index,
                    attack = current,
                }
            end
        end
    end

    return ordered
end

-- DCSS chooses these authored attack shapes on every contact, rather than
-- once at spawn or catalog load. A Cherub can therefore use its weapon on
-- one second-slot contact and make a natural strike on the next round.
function sequence.contact_type(ctx, attack)
    if attack.type_id == attack_types.RANDOM then
        local choices = {
            attack_types.HIT,
            attack_types.GORE,
        }

        return choices[roll.melee(ctx, #choices) + 1]
    end

    if attack.type_id == attack_types.CHERUB then
        local choices = {
            attack_types.HIT,
            attack_types.BITE,
            attack_types.PECK,
            attack_types.GORE,
        }

        return choices[roll.melee(ctx, #choices) + 1]
    end

    return attack.type_id
end

-- Living hydras and Serpent variants can turn remaining heads toward an
-- adjacent enemy. A zombie of a hydra has heads but cannot retarget.
function sequence.can_retarget(definition)
    return definition.genus_id == monsters.MONS_HYDRA or
        definition.species_id == monsters.MONS_SERPENT_OF_HELL
end

return sequence
