local component = require("constants.component")
local constructs = require("constants.monster_construct_components")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local intent = require("constants.intent")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = require("policy.combat.monster_spells").effect(
    spells.SPELL_MALIGN_GATEWAY)
local gateway = require("systems.magic_summon_gateway")
local portal = require("policy.combat.monster_summons.portal")
local player_gateway = require("policy.magic.effects.summons.malign_gateway")
local tentacle = require("policy.magic.effects.summons.tentacle")

local test = {}

-- Create a real gateway marker and head with the production policies. The
-- sparse grid fixture only replaces the Go level, not ECS component schemas.
local function opened_gateway(ctx, game, x, y)
    local caster = fixture.actor(ctx, monsters.MONS_ORC, x, y)
    local plan = effect.plan(game, caster, game:player())

    harness.truthy(plan, "gateway needs a placement cell")
    effect.resolve(game, caster, game:player(), nil, plan)

    local marker = ctx:query({ component.SUMMON_GATEWAY })[1]
    local state = ctx:get(marker, component.SUMMON_GATEWAY)

    state.expires_aut = 0
    ctx:set(marker, component.SUMMON_GATEWAY, state)
    gateway.update(game, game:player())

    local emerged = ctx:get(marker, component.SUMMON_GATEWAY)

    return marker, ctx:entity(emerged.tentacle_id), plan
end

-- Source mon-tentacle.cc advances BASE_POSITION once per severed head action.
-- The saved anchor moves, while the portal marker keeps the original cell.
local function severed_anchor_drifts(ctx, game)
    local marker, head, plan = opened_gateway(ctx, game, 42, 42)
    local portal_state = ctx:get(head, constructs.PORTAL)

    harness.truthy(player_gateway.prepare(game, game:player()),
        "a monster gateway blocks the player's global gateway slot")

    harness.equal(portal_state.anchor_x, plan.x,
        "new tentacle anchor starts at the portal")
    harness.equal(portal_state.anchor_y, plan.y,
        "new tentacle anchor starts at the portal")

    game:move_actor(head, plan.level_id, plan.x + 3, plan.y)

    -- Leave one adjacent habitable square. This also makes the expected
    -- drift independent of the source fair-adjacent iteration order.
    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                if dx ~= 1 or dy ~= 0 then
                    game.walls[(plan.x + dx) .. ":" .. (plan.y + dy)] = true
                end
            end
        end
    end

    portal_state.remaining_aut = 1
    ctx:set(head, constructs.PORTAL, portal_state)
    portal.tick(game, head, 10)

    local action = tentacle.act(game, head,
        ctx:get(head, component.POSITION))
    local drifted = ctx:get(head, constructs.PORTAL)
    local fixed = ctx:get(marker, component.SUMMON_GATEWAY)

    harness.truthy(drifted.severed, "portal timer severs the tentacle")
    harness.equal(drifted.anchor_x, plan.x + 1,
        "severed anchor follows the only open adjacent square")
    harness.equal(drifted.anchor_y, plan.y,
        "anchor drift remains on the portal level")
    harness.equal(fixed.x, plan.x, "portal marker does not drift")
    harness.equal(action.kind, intent.MONSTER_MOVE,
        "the head retracts toward the drifting anchor")
    harness.equal(action.dx, -1, "the head follows the new connection")

    tentacle.refresh(game, head)
    local segments = ctx:query({ component.SUMMON_SEGMENT })

    harness.truthy(#segments > 0, "drifted anchor rebuilds its connector")
    harness.equal(ctx:get(segments[1], component.POSITION).x, plan.x + 2,
        "connector spans the new anchor and head")
    harness.equal(ctx:get(segments[1], component.SUMMON_SEGMENT).gateway,
        head, "connector links to its self-anchored head")

    gateway.update(game, game:player())

    harness.falsy(ctx:has(marker, component.SUMMON_GATEWAY),
        "the portal marker ends once its living head leaves the gateway cell")
    harness.truthy(ctx:has(head, constructs.PORTAL),
        "a vacated marker does not kill the still-living severed head")

    tentacle.clean_orphans(game)
    harness.truthy(#ctx:query({ component.SUMMON_SEGMENT }) > 0,
        "a living head keeps its connector after marker cleanup")

    local continued = tentacle.act(game, head,
        ctx:get(head, component.POSITION))

    harness.equal(continued.kind, intent.MONSTER_MOVE,
        "the head keeps its saved anchor after the marker is removed")
    harness.truthy(ctx:has(head, component.HEALTH),
        "a moving head still has health after marker removal")

    ctx:destroy(head)
end

-- A head can see a foe around a wall that hides it from the gateway. Source
-- mon-tentacle.cc requires both head sight and base LOS before pursuit.
local function anchor_blocks_hidden_foe(ctx, game)
    local marker, head, plan = opened_gateway(ctx, game, 100, 100)

    game:move_actor(head, plan.level_id, plan.x + 2, plan.y)
    game:move_actor(game:player(), plan.level_id, plan.x + 4, plan.y)
    game.visible_no_trans = function(_, _, x, y, _, tx, ty)
        return x ~= plan.x or y ~= plan.y or
            tx ~= plan.x + 4 or ty ~= plan.y
    end

    local action = tentacle.act(game, head,
        ctx:get(head, component.POSITION))

    harness.equal(action.kind, intent.MONSTER_WAIT,
        "a gateway head does not pursue a foe hidden from its anchor")
    harness.equal(ctx:get(marker, component.SUMMON_GATEWAY).tentacle_id,
        ctx:id(head), "LOS rejection keeps its persistent gateway link")

    -- Even if a head is displaced directly, its source five-cell tether
    -- cannot make a six-cell connection. Failed reconnection kills the head.
    game:move_actor(head, plan.level_id, plan.x + 6, plan.y)
    tentacle.act(game, head, ctx:get(head, component.POSITION))
    harness.truthy(not ctx:has(head, component.SUMMON),
        "an impossible six-cell gateway connection expires its head")
end

-- These focused cases use separate sparse regions so one marker never
-- affects another test's placement or target selection.
function test.run(ctx)
    local game = fixture.observed_context(ctx)

    game.random = function()
        return 0
    end
    game.set_cell = function(self, _, x, y, feature)
        self.cells[x .. ":" .. y] = feature
    end

    severed_anchor_drifts(ctx, game)

    -- The second case is independent of the first portal's closed marker.
    for _, marker in ipairs(ctx:query({ component.SUMMON_GATEWAY })) do
        local state = ctx:get(marker, component.SUMMON_GATEWAY)
        ctx:destroy(ctx:entity(state.tentacle_id))
        ctx:destroy(marker)
    end

    anchor_blocks_hidden_foe(ctx, game)
end

return test
