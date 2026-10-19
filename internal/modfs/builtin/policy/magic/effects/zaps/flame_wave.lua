local component = require("constants.component")
local spells = require("ids.spells")
local channel = require("policy.magic.channel")
local catalog = require("policy.catalog")
local explosion = require("policy.combat.explosion")
local explosive = require("policy.magic.effects.zaps.explosive")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")

local flame_wave = {}

-- spl-damage.cc:cast_flame_wave/handle_flame_wave. Each wave includes every
-- reachable cell within its radius, except the caster's own cell.
local spec = {
    name = "flame wave",
    cap = 100,
    element = "MR_RES_FIRE",
    damage = {
        count = 2,
        base = 9,
        numerator = 1,
        denominator = 3,
    },
}

-- Hit each eligible cell at this radius before the next channeled wave is scheduled.
local function wave(ctx, player, power, radius)
    local origin = ctx:get(player, component.POSITION)

    for _, cell in ipairs(explosion.cells(ctx, origin.level_id,
        origin.x, origin.y, radius)) do
        if cell.x ~= origin.x or cell.y ~= origin.y then
            local target = ctx:actor_at(origin.level_id, cell.x, cell.y)

            if target then
                explosive.hurt(ctx, player, target, spec, power)
            end
        end
    end

    ctx:emit("spell", "A wave of flame ripples out!")
end

-- Deal the first radius immediately, then save the channel state for later wave ticks.
function flame_wave.resolve(ctx, player, _, _, power)
    wave(ctx, player, power, 1)

    channel.begin(ctx, player, {
        spell_id = spells.SPELL_FLAME_WAVE,
        power = power,
        stage = 0,
        aimed_at_spot = true,
        target_x = 0,
        target_y = 0,
    })
end

-- Example: The initial radius-one wave hits now; continuation expands the saved channel radius.
-- Derive each radius from saved channel stage so interrupted casts cannot advance an unsaved wave.
function flame_wave.continue(ctx, player, state)
    local radius = state.stage + 1
    local spell = catalog.get("spells", spells.SPELL_FLAME_WAVE)

    wave(ctx, player, state.power, radius)

    return true, radius < range.for_spell(ctx, player, spell)
end

registry.add(spells.SPELL_FLAME_WAVE, flame_wave)

return flame_wave
