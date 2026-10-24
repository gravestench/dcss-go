-- A restored Duel must bind one player visit to the authored Arena floor,
-- its still-live barrier or opened victory path, and marked opponents.
local branches = require("ids.branches")
local component = require("constants.component")
local levels = require("policy.generation.branch_levels")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.vaults.catalog")

local saved = {}

-- Reject an orphan mark or forged return coordinate before the next turn
-- can move a monster across levels or unlock a nonexistent barrier.
function saved.validate(ctx, player)
    local visit = ctx:get(player, component.PLAYER_ARENA_VISIT)
    local player_site = ctx:get(player, component.POSITION)
    local current = 0

    for _, monster in ipairs(ctx:query({
        component.MONSTER_ARENA_DUEL,
        component.POSITION,
    })) do
        local mark = ctx:get(monster, component.MONSTER_ARENA_DUEL)
        local site = ctx:get(monster, component.POSITION)

        if mark.current then
            current = current + 1

            if not visit or mark.abandoned or
                mark.root_id ~= visit.target_id or
                site.level_id ~= visit.level_id then
                error("invalid current Arena challenger")
            end
        elseif not mark.abandoned or mark.root_id == "" then
            error("invalid abandoned Arena challenger")
        end
    end

    if not visit then
        if ctx:level_branch(levels.id(branches.BRANCH_ARENA, 1)) ==
            branches.BRANCH_ARENA then
            error("saved Arena floor has no player visit")
        end

        return
    end

    local definition = vaults.get(visit.vault_id)
    local expected_barrier = visit.victory and terrain.DNGN_FLOOR or
        terrain.DNGN_CLEAR_PERMAROCK_WALL

    if not player_site or
        player_site.level_id ~= visit.level_id or
        visit.level_id ~= levels.id(branches.BRANCH_ARENA, 1) or
        visit.origin_level_id <= 0 or
        visit.origin_level_id == visit.level_id or
        not ctx:walkable(visit.origin_level_id,
            visit.origin_x, visit.origin_y) or
        definition.family ~= "arena" or
        visit.target_id == "" or
        (visit.victory and
            (visit.return_aut < 0 or visit.return_aut > 250)) or
        (not visit.victory and visit.return_aut ~= 0) or
        ctx:cell(visit.level_id,
            visit.target_x, visit.target_y) ~= expected_barrier or
        ctx:cell(visit.level_id,
            visit.exit_x, visit.exit_y) ~= terrain.DNGN_EXIT_ARENA or
        (visit.victory and current > 0) or
        (not visit.victory and current == 0) then
        error("invalid saved Arena visit")
    end
end

return saved
