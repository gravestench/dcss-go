-- Source: attack.cc,1335. Chaos rolls another melee brand first.
local brands = require("constants.weapon_brands")
local choice = require("policy.combat.chaos_choice")
local conduct = require("policy.religion.conduct")
local identification = require("policy.items.identification")
local kinds = require("constants.religion_conduct")
local streams = require("constants.rng_streams")

local chaos = {
    after_death = true,
}

-- Example: chaos.choose(ctx, hit) with defender with eligible effects -> returns one weighted brand ID
-- Build the valid weighted effect pool from this defender before consuming the chaos draw.
function chaos.choose(ctx, hit)
    return choice.choose(ctx, hit)
end

-- A self-selected Chaos result uses monster effects; other results reuse ordinary brand code.
function chaos.apply(ctx, hit, target_brands)
    -- Source attack.cc judges the chosen chaos weapon brand, even when its
    -- random effect is harmless. Identification before the proc decides
    -- whether a good god forgives this particular swing.
    if hit.attacker == ctx:player() then
        local known = hit.weapon_entity and
            identification.known(ctx, hit.attacker,
                hit.weapon_entity).properties or false

        conduct.record(ctx, {
            id = kinds.CHAOS,
            level = 2 + ctx:random(streams.RELIGION, 3),
            known = known,
        })
    end

    local selected = chaos.choose(ctx, hit)

    if selected == brands.CHAOS then
        -- The self-selection enters the chaos effect table only while the
        -- defender is still alive; other choices reuse their brand module.
        if hit.health.current <= 0 then
            return
        end

        require("policy.combat.monster_target_brands.chaos_effects").apply(ctx, hit)
        return
    end

    target_brands.apply(ctx, selected, hit)
end

return chaos
