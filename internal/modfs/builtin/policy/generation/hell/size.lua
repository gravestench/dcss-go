-- The source halves the builder extent only for the four Hell subbranches
-- above their last depth. Their endings and the Vestibule retain 80x70.
-- Reading catalog parentage avoids a second hardcoded branch-ID list.
local branches = require("ids.branches")
local dimensions = require("constants.level_dimensions")

local size = {}

-- Hell subbranches are rootless children of the Vestibule, which itself
-- does not meet this predicate. Branch metadata remains the source of truth.
function size.is_subbranch(branch)
    return branch.parent_id == branches.BRANCH_VESTIBULE
end

-- Return both extents for a fresh builder; callers keep them on that
-- builder instead of changing a module global during map construction.
function size.for_branch(branch, local_depth)
    if size.is_subbranch(branch) and
        local_depth < branch.depth then
        return dimensions.HELL_WIDTH, dimensions.HELL_HEIGHT
    end

    return dimensions.FULL_WIDTH, dimensions.FULL_HEIGHT
end

return size
