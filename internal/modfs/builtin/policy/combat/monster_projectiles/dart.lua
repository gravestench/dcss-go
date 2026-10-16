local ranged = require("policy.combat.ranged")
local monster_stats = require("policy.combat.monster_stats")

local dart = {}
dart.show_damage = false
dart.reflectable = true

function dart.validate(item)
    if item.ego ~= "poisoned" then
        error("unsupported monster dart ego " .. item.ego)
    end
end

function dart.resolve(ctx, attacker, definition, defense)
    local hd = monster_stats.hit_dice(ctx, attacker, definition)
    local outcome, poison = ranged.poison_dart(ctx, hd, defense)

    return outcome, poison, "poisoned dart"
end

return dart
