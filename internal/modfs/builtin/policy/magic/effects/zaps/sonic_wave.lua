local component = require("constants.component")
local spells = require("ids.spells")
local defense = require("policy.combat.monster_defense")
local damage = require("policy.magic.damage")
local registry = require("policy.magic.effects.registry")
local player_contact = require("policy.combat.player_contact")

local sonic_wave = {}

-- Round the two-die side count from capped power before rolling the sonic hit.
local function roll_damage(ctx, power)
    -- zap-data.h:ZAP_SONIC_WAVE uses calcdice<2,5,1,5>.
    local maximum = 5 + math.floor(math.min(power, 200) / 5)
    local sides = math.floor(maximum / 2)

    if maximum % 2 > 0 and ctx:random("spell", 2) == 0 then
        sides = sides + 1
    end

    return 2 + ctx:random("spell", sides) +
        ctx:random("spell", sides)
end

-- Example: Sonic Wave damages visible nearby monsters after rolling armour for each target.
-- Apply LOS attack damage separately to each nearby survivor; this zap has no hit roll.
function sonic_wave.resolve(ctx, player, _, _, power)
    local origin = ctx:get(player, component.POSITION)

    ctx:emit("spell", "You send a blast of sound all around you.")

    -- spl-damage.cc:_cast_los_attack_spell applies this to every other
    -- actor in LOS_NO_TRANS, then rolls AC; the zap's to-hit is unused.
    for _, target in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if target ~= player then
            local location = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)
            local distance = math.max(math.abs(location.x - origin.x),
                math.abs(location.y - origin.y))

            if health.current > 0 and distance <= 7 and
                location.level_id == origin.level_id and
                ctx:visible(origin.level_id, origin.x, origin.y, 7,
                    location.x, location.y) then
                local definition = damage.monster(ctx, target)
                player_contact.report(ctx, target, definition)
                local ac = defense.armour(ctx, target, definition)
                local raw = roll_damage(ctx, power)
                local amount = math.max(0, raw - ctx:random("spell", ac + 1))

                damage.apply(ctx, target, amount)
                ctx:emit("spell", "The sonic wave hits the " .. definition.name .. ".")
            end
        end
    end
end

registry.add(spells.SPELL_SONIC_WAVE, sonic_wave)

return sonic_wave
