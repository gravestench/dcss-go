local component = require("constants.component")
local spells = require("ids.spells")
local damage = require("policy.magic.damage")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")
local will = require("policy.magic.effects.zaps.will")

local mindburst = {}

local function roll_damage(ctx, power)
    -- zap-data.h:ZAP_MINDBURST uses calcdice<3,15,3,4>.
    local maximum = 15 + math.floor(math.min(power, 100) * 3 / 4)
    local sides = math.floor(maximum / 3)
    local remainder = maximum % 3

    if remainder > 0 and ctx:random("spell", 3) < remainder then
        sides = sides + 1
    end

    local amount = 0

    for _ = 1, 3 do
        amount = amount + 1 + ctx:random("spell", sides)
    end

    return amount
end

function mindburst.resolve(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.trace(ctx, origin.level_id, origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))

    if #ray.contacts == 0 then
        ctx:emit("spell", "Mindburst finds no target.")
        return
    end

    -- ZAP_MINDBURST is a piercing enchantment. Each thinking monster
    -- on the ray makes its own willpower check before damage is rolled.
    for _, contact in ipairs(ray.contacts) do
        local target = contact.actor
        local definition, health = damage.monster(ctx, target)

        if not definition then
            error("Mindburst struck an actor without health")
        end

        if health.current > 0 then
            if definition.intelligence_id == "I_BRAINLESS" then
                ctx:emit("spell", "The " .. definition.name .. " is unaffected.")
            else
                local enchant_power = math.floor(math.min(power, 100) * 5 / 2)

                if will.resists(ctx, definition, enchant_power) then
                    ctx:emit("spell", "The " .. definition.name .. " resists Mindburst.")
                else
                    damage.apply(ctx, target, roll_damage(ctx, power))
                    ctx:emit("spell", "The " .. definition.name .. "'s mind is blasted.")
                end
            end
        end
    end
end

registry.add(spells.SPELL_MINDBURST, mindburst)

return mindburst
