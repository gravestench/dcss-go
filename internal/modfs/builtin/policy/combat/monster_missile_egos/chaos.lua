-- A Chaos missile chooses a temporary ordinary ego on every hit. When
-- Chaos chooses its own inner band, attack.cc selects a spell-like boon or
-- hex; this module owns that narrower choice without changing item state.
local flavours = require("constants.beam_flavours")
local streams = require("constants.rng_streams")

local chaos = {}

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

-- Player-inapplicable clone and shifter results are absent from this
-- source weight table. The selected flavour uses its existing effect owner.
function chaos.apply(ctx, attacker, _, _, damage)
    local draw = ctx:random(streams.MELEE, 67)
    local selected

    for _, choice in ipairs(inner) do
        draw = draw - choice.weight

        if draw < 0 then
            selected = choice.flavour
            break
        end
    end

    local player = ctx:player()
    local boons = require("policy.combat.monster_area.chaos_boons")

    if boons.handles(selected) then
        boons.apply(ctx, attacker, player, selected, damage)

        return
    end

    local hexes = require("policy.combat.monster_area.chaos_hexes")

    hexes.apply(ctx, attacker, player, selected, damage)
end

return chaos
