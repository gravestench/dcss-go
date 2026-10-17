local component = require("constants.component")
local forms = require("policy.magic.effects.forms.player")
local harness = require("tests.harness")
local items = require("ids.items")
local potions = require("policy.potions")
local resistance = require("policy.combat.player_resistance")
local cloud_ids = require("ids.clouds")

local test = {}

function test.run(ctx)
    local player = ctx:create()
    local effect = potions.get(items.POT_LIGNIFY)

    harness.truthy(effect, "lignification potion is registered")
    harness.equal(forms.profile(items.POT_LIGNIFY).id, "tree",
        "potion uses the shared player form owner")

    ctx:add(player, component.PLAYER_FORM, {
        form_id = "tree",
        remaining_aut = 300,
        uncancellable = true,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 1,
    })

    harness.equal(forms.scale_hp(ctx, player, 100), 150,
        "tree form grants its source HP multiplier")
    harness.falsy(forms.slot_usable(ctx, player, "body"),
        "tree form melds body armour")
    harness.truthy(forms.slot_usable(ctx, player, "weapon"),
        "tree form keeps wielded weapons")
    harness.equal(forms.modifiers(ctx, player).flight, "forbid",
        "tree form forbids flight")
    harness.equal(forms.modifiers(ctx, player).ac_x100, 2050,
        "tree form adds half an AC point at XL 1")
    harness.truthy(forms.stasis(ctx, player),
        "tree form blocks involuntary teleportation")
    harness.truthy(forms.torment_immune(ctx, player),
        "tree form carries source torment immunity")
    harness.truthy(resistance.torment(ctx, player),
        "torment reads live tree form immunity")

    local cloud = ctx:create()

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 2,
        y = 3,
    })
    ctx:add(cloud, component.WORLD_CLOUD, {
        kind_id = cloud_ids.CLOUD_FIRE,
        level_id = 1,
        x = 2,
        y = 3,
        decay_aut = 100,
    })

    local clocked = setmetatable({}, { __index = ctx })

    function clocked.aut()
        return 0
    end

    harness.truthy(effect.cloud_confirmation(clocked, player),
        "known tree potion confirms a damaging cloud")
end

return test
