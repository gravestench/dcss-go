local ranged = require("policy.combat.ranged")

local dart = {}
dart.show_damage = false

function dart.validate(item)
    if item.ego ~= "poisoned" then
        error("unsupported monster dart ego " .. item.ego)
    end
end

function dart.resolve(ctx, definition, defense)
    local outcome, poison = ranged.poison_dart(ctx, definition.hd, defense)

    return outcome, poison, "poisoned dart"
end

return dart
