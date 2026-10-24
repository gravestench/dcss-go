-- A chaotic launcher uses the same source weapon Chaos brand table as a
-- melee weapon. It runs after the base ranged hit so polymorph, statuses,
-- and bonus damage see the real surviving defender and saved HP.
local target_brands = require("policy.combat.monster_target_brands")
local weapon_brands = require("constants.weapon_brands")

local brand = {}

-- Ordinary elemental launchers return bonus damage to their caller;
-- Chaos delegates its many possible effects to the monster target owner.
function brand.apply(ctx, _, defender, damage, target, attacker,
    health, weapon_entity)
    if not target or not attacker or not health then
        error("chaos launcher requires a resolved defender")
    end

    target_brands.apply(ctx, weapon_brands.CHAOS, {
        attacker = attacker,
        attacker_name = "you",
        defender = target,
        definition = defender,
        damage_done = damage,
        health = health,
        weapon_entity = weapon_entity,
        player_credit = true,
    })

    return 0
end

return brand
