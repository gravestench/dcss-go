local ranged = require("policy.combat.ranged")
local monster_stats = require("policy.combat.monster_stats")
local missile_egos = require("policy.combat.monster_missile_egos")
local brands = require("constants.missile_egos")

local dart = {}
dart.show_damage = false
dart.reflectable = true

-- Source dart coatings choose an effect after the same contact-only roll.
function dart.validate(item, kind_id)
    missile_egos.validate(kind_id, item)
end

-- Resolve contact first; the returned poison dose applies only if the poisoned dart hits.
function dart.resolve(ctx, attacker, definition, defense, _, item)
    local hd = monster_stats.hit_dice(ctx, attacker, definition)
    local poisoned = item and item.ego == brands.POISONED
    local outcome, poison = ranged.poison_dart(ctx, hd, defense, poisoned)

    local name = poisoned and "poisoned dart" or "dart"

    return outcome, poison, name
end

return dart
