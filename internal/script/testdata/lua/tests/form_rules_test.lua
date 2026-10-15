local component = require("constants.component")
local forms = require("policy.magic.effects.forms.player")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local player = ctx:create()

    harness.equal(forms.scale_hp(ctx, player, 100), 100,
        "no form should leave maximum HP unchanged")

    ctx:add(player, component.PLAYER_FORM, {
        form_id = "ice_beast",
        remaining_aut = 30,
        power = 40,
    })
    harness.equal(forms.scale_hp(ctx, player, 100), 120,
        "Ice Form should apply its source HP multiplier")
    harness.falsy(forms.can_bleed(ctx, player),
        "Ice Form should be bloodless")

    ctx:set(player, component.PLAYER_FORM, {
        form_id = "appendage",
        remaining_aut = 30,
        power = 40,
        appendage_mask = 4,
    })
    harness.equal(forms.mutation_level(ctx, player, "MUT_TALONS"), 2,
        "Beastly Appendage should grant temporary talons")
    harness.equal(forms.scale_hp(ctx, player, 100), 100,
        "Beastly Appendage should not change maximum HP")
end

return test
