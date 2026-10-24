-- Vehumet punishes a deserter with a level-scaled conjuration selected
-- from the source pool. The temporary god caster fires the ordinary Lua
-- spell effect; a lingering cloud or summon retains its god attribution.
local avatar = require("policy.religion.wrath.avatar")
local component = require("constants.component")
local gods = require("constants.gods")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local vehumet = {}

-- The source switch has nine severity bands. One file owns the selection,
-- while individual spell modules own contact, resistance, and aftermath.
local conjurations = {
    {
        spells.SPELL_MAGIC_DART,
        spells.SPELL_STING,
        spells.SPELL_SHOCK,
        spells.SPELL_FLAME_TONGUE,
    },
    {
        spells.SPELL_THROW_FLAME,
        spells.SPELL_THROW_FROST,
    },
    {
        spells.SPELL_MEPHITIC_CLOUD,
        spells.SPELL_STONE_ARROW,
    },
    {
        spells.SPELL_STICKY_FLAME,
        spells.SPELL_THROW_ICICLE,
        spells.SPELL_ENERGY_BOLT,
    },
    {
        spells.SPELL_FIREBALL,
        spells.SPELL_LIGHTNING_BOLT,
        spells.SPELL_BOLT_OF_MAGMA,
        spells.SPELL_VENOM_BOLT,
        spells.SPELL_BOLT_OF_DRAINING,
        spells.SPELL_QUICKSILVER_BOLT,
        spells.SPELL_METAL_SPLINTERS,
    },
    {
        spells.SPELL_BOLT_OF_FIRE,
        spells.SPELL_BOLT_OF_COLD,
        spells.SPELL_CORROSIVE_BOLT,
        spells.SPELL_FREEZING_CLOUD,
        spells.SPELL_POISONOUS_CLOUD,
        spells.SPELL_POISON_ARROW,
        spells.SPELL_IRON_SHOT,
        spells.SPELL_CONJURE_BALL_LIGHTNING,
    },
    {
        spells.SPELL_ORB_OF_ELECTRICITY,
        spells.SPELL_FLASH_FREEZE,
    },
    {
        spells.SPELL_LEHUDIBS_CRYSTAL_SPEAR,
    },
    {
        spells.SPELL_FIRE_STORM,
    },
}

-- Source random_range is inclusive and clamps the upper outcome to nine.
-- A one-choice range consumes no branch RNG before spell selection.
local function severity(ctx, level)
    local minimum = 1 + math.floor(level / 5)
    local maximum = 1 + math.floor(level / 3)
    local result = minimum

    if maximum > minimum then
        result = result + ctx:random(streams.CARDS,
            maximum - minimum + 1)
    end

    return math.min(result, #conjurations)
end

-- An occupied player cell prevents get_avatar before any severity draws.
-- The selected spell then casts at the player's feet in the source order.
function vehumet.apply(ctx, player)
    if not avatar.available(ctx, player, gods.VEHUMET) then
        return false
    end

    local level = ctx:get(player, component.PROGRESSION).level
    local choices = conjurations[severity(ctx, level)]
    local index = 1

    if #choices > 1 then
        index = ctx:random(streams.CARDS, #choices) + 1
    end

    return avatar.cast(ctx, player, gods.VEHUMET, choices[index])
end

return vehumet
