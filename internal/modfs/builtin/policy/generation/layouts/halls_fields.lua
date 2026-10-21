-- Theory of operation: hall fields compose pure primitive functions before a
-- source-ordered render pass samples them. Factories retain the pinned dlua
-- formulas; only noise and builder services enter through local dependencies.
local noise = require("policy.generation.layouts.halls_noise")
local fields = {}

-- Bind primitive factories to this map's RNG and dimensions, avoiding globals.
function fields.new(env)
    local crawl = env.crawl
    local util = env.util
    local dgn = env.dgn
    local procedural = {}
    local primitive = {}
    local complex = {}
    -- Sum scalar fields so independent carving layers can reinforce each other.
    function procedural.add(...)
        local vars = { ... }
        -- Sample the fixed procedural.add composition without further construction draws.
        return procedural.aggregate(vars, function(t, v)
            return t + v
        end)
    end

    -- Subtract later fields from the first, preserving source operand order.
    function procedural.sub(...)
        local vars = { ... }
        -- Sample the fixed procedural.sub composition without further construction draws.
        return procedural.aggregate(vars, function(t, v)
            return t - v
        end)
    end

    -- Multiply fields and constants to control source widths and distortion strengths.
    function procedural.mul(...)
        local vars = { ... }
        -- Sample the fixed procedural.mul composition without further construction draws.
        return procedural.aggregate(vars, function(t, v)
            return t * v
        end)
    end

    -- Divide the first field by later values to normalize source distances.
    function procedural.div(...)
        local vars = { ... }
        -- Sample the fixed procedural.div composition without further construction draws.
        return procedural.aggregate(vars, function(t, v)
            return t / v
        end)
    end

    -- Union low-valued carving fields by selecting their pointwise minimum.
    function procedural.min(...)
        local vars = { ... }
        -- Sample the fixed procedural.min composition without further construction draws.
        return procedural.aggregate(vars, function(t, v)
            return math.min(t, v)
        end)
    end

    -- Intersect low-valued carving fields by selecting their pointwise maximum.
    function procedural.max(...)
        local vars = { ... }
        -- Sample the fixed procedural.max composition without further construction draws.
        return procedural.aggregate(vars, function(t, v)
            return math.max(t, v)
        end)
    end

    -- Evaluate mixed constants and functions in source argument order before folding them.
    function procedural.aggregate(list, op)
        -- Sample the fixed procedural.aggregate composition without further construction draws.
        return function(x, y)
            local val = 0
            local r
            for i, f in ipairs(list) do
                if type(f) == "function" then
                    r = f(x, y)
                else
                    r = f
                end
                if i == 1 then
                    val = r
                else
                    val = op(val, r)
                end
            end
            return val
        end
    end

    -- Turn a signed distance field into a two-sided distance from its zero contour.
    function procedural.abs(func)
        -- Sample the fixed procedural.abs composition without further construction draws.
        return function(x, y)
            return math.abs(func(x, y))
        end
    end

    -- Invert a signed field when constructing the source triangular primitive.
    function procedural.neg(func)
        -- Sample the fixed procedural.neg composition without further construction draws.
        return function(x, y)
            return -func(x, y)
        end
    end

    -- Repeat an angular field and offset it to form source rays and partition holes.
    function procedural.phase(func, rep, offset)
        -- Sample the fixed procedural.phase composition without further construction draws.
        return function(x, y)
            local v = func(x, y)
            v = (v * rep + offset) % 1
            return v
        end
    end

    -- Fade the source border inward over padding + 1 cells, respecting its margin.
    function procedural.border(params)
        local x1, y1 = 0, 0
        local x2, y2 = dgn.builder_bounds()
        x2 = x2 - 1
        y2 = y2 - 1
        if params.x1 ~= nil then
            x1 = params.x1
        end
        if params.x2 ~= nil then
            x2 = params.x2
        end
        if params.y1 ~= nil then
            y1 = params.y1
        end
        if params.y2 ~= nil then
            y2 = params.y2
        end
        local padding = params.padding == nil and 10 or params.padding
        if params.margin ~= nil then
            x1 = x1 + params.margin
            x2 = x2 - params.margin
            y1 = y1 + params.margin
            y2 = y2 - params.margin
        end
        if params.additive then
            -- Sample the fixed procedural.border composition without further construction draws.
            return function(x, y)
                local nearx = math.min(x - x1, x2 - x)
                local neary = math.min(y - y1, y2 - y)
                return math.min(
                    1,
                    2
                        - procedural.minmax_map(nearx, 0, padding + 1)
                        - procedural.minmax_map(neary, 0, padding + 1)
                )
            end
        else
            -- Sample the fixed procedural.border composition without further construction draws.
            return function(x, y)
                local near = math.min(x - x1, y - y1, x2 - x, y2 - y)
                return 1 - procedural.minmax_map(near, 0, padding + 1)
            end
        end
    end

    -- Measure normalized distance from the map center toward its nearest rectangle edge.
    function procedural.box(params)
        local x1, y1 = 0, 0
        local x2, y2 = dgn.builder_bounds()
        x2 = x2 - 1
        y2 = y2 - 1
        if params.x1 ~= nil then
            x1 = params.x1
        end
        if params.x2 ~= nil then
            x2 = params.x2
        end
        if params.y1 ~= nil then
            y1 = params.y1
        end
        if params.y2 ~= nil then
            y2 = params.y2
        end

        -- TODO: Mathematically speaking this is correct but in reality
        -- we might have to adjust this a little for the grid
        local minhalf = math.min((x2 - x1) / 2, (y2 - y1) / 2)

        -- Sample the fixed procedural.box composition without further construction draws.
        return function(x, y)
            local near = math.min(x - x1, y - y1, x2 - x, y2 - y)
            return 1 - near / minhalf
        end
    end

    -- Measure source clockwise angular phase around a configurable origin.
    function procedural.radial(params)
        local xo, yo = 0, 0
        if params.origin ~= nil then
            xo, yo = params.origin.x, params.origin.y
        end

        -- Sample the fixed procedural.radial composition without further construction draws.
        return function(x, y)
            local xd, yd = xo - x, yo - y
            local r
            if yd == 0 then
                r = (xd > 0) and 270 or 90
            else
                r = math.atan(xd / yd) / math.pi * 180
                if yd > 0 then
                    r = r + 180
                end
            end
            if params.phase ~= nil then
                r = (r + params.phase * 360)
            end
            return (r % 360) / 360
        end
    end

    -- Offset the source domain by independent x/y fields before sampling its geometry.
    function procedural.distort(params)
        local source = params.source
        -- Sample the fixed procedural.distort composition without further construction draws.
        local offsetx = params.offsetx or function(x, y)
            return 0
        end
        -- Sample the fixed procedural.distort composition without further construction draws.
        local offsety = params.offsety or function(x, y)
            return 0
        end
        local scale = params.scale or 1
        -- Sample the fixed procedural.distort composition without further construction draws.
        return function(x, y)
            return source(x + offsetx(x, y) * scale, y + offsety(x, y) * scale)
        end
    end

    -- Move source geometry by subtracting its origin from each sampled coordinate.
    function procedural.translate(func, xo, yo)
        if xo == nil then
            xo, yo = 0, 0
        elseif type(xo) == "table" then
            xo, yo = xo.x, xo.y
        elseif yo == nil then
            yo = xo
        end

        -- Sample the fixed procedural.translate composition without further construction draws.
        return function(x, y)
            return func(x - xo, y - yo)
        end
    end

    -- Resize source geometry by dividing the incoming domain independently on each axis.
    function procedural.scale(func, xs, ys)
        if xs == nil then
            xs, ys = 1, 1
        elseif type(xs) == "table" then
            xs, ys = xs.x, xs.y
        elseif ys == nil then
            ys = xs
        end

        -- Sample the fixed procedural.scale composition without further construction draws.
        return function(x, y)
            return func(x / xs, y / ys)
        end
    end

    -- Reflect the source triangle across the horizontal axis without changing its shape.
    function procedural.flip_y(func)
        -- Sample the fixed procedural.flip_y composition without further construction draws.
        return function(x, y)
            return func(x, -y)
        end
    end

    -- Apply the first matching source interval, leaving unmatched values unchanged.
    function procedural.map(func, map, b, c, d)
        if type(map) ~= "table" then
            map = {
                {
                    nil,
                    map,
                    c,
                },
                {
                    map,
                    b,
                    c,
                    d,
                },
                {
                    b,
                    nil,
                    d,
                },
            }
        end
        -- Sample the fixed procedural.map composition without further construction draws.
        return function(x, y)
            local v = func(x, y)
            for i, m in ipairs(map) do
                -- Outer limits
                if m[1] == nil then
                    if v <= m[2] then
                        return m[3]
                    end
                elseif m[2] == nil then
                    if v >= m[1] then
                        return m[3]
                    end
                elseif m[1] <= v and v <= m[2] then
                    return m[3] + (v - m[1]) / (m[2] - m[1]) * (m[4] - m[3])
                end
            end
            -- If the map hasn't given us a value, don't alter it
            return v
        end
    end

    -- Clamp and normalize a value to the source border interpolation interval.
    function procedural.minmax_map(val, min, max)
        if val < min then
            return 0
        elseif val > max then
            return 1
        else
            return (val - min) / (max - min)
        end
    end

    -- Sample the complete source builder interior in x/y order, retaining a rock rim.
    function procedural.render_map(e, fval, fresult)
        local gxm, gym = dgn.builder_bounds()
        e.extend_map({
            width = gxm,
            height = gym,
            fill = "x",
        })
        for x = 1, gxm - 2, 1 do
            for y = 1, gym - 2, 1 do
                local val = fval(x, y)
                local r = fresult(val, x, y)
                if r ~= nil then
                    e.mapgrd[x][y] = r
                end
            end
        end
    end

    -- Expose the horizontal coordinate for cross and diagonal distance composition.
    function primitive.linear_x(x, y)
        return x
    end

    -- Expose the vertical coordinate for cross and triangular distance composition.
    function primitive.linear_y(x, y)
        return y
    end

    -- Measure one diagonal projection used by the source diamond and diagonal cross.
    function primitive.linear_xy(x, y)
        return x + y
    end

    -- Measure the opposing diagonal projection for symmetric primitive composition.
    function primitive.linear_yx(x, y)
        return x - y
    end

    -- Use the maximum absolute coordinate as the source square distance field.
    function primitive.box(x, y)
        return math.max(math.abs(x), math.abs(y))
    end

    -- Returns distance from the origin, useful for circles and ellipses
    -- Use Euclidean distance for round rings, radial connectors, and source spirals.
    function primitive.distance(x, y)
        return math.sqrt(math.pow(x, 2) + math.pow(y, 2))
    end

    -- Gives the radial value from a point, i.e. the arctangent of the line
    -- from the origin to the point
    -- Retain the primitive angular convention, which differs from procedural.radial.
    function primitive.radial(x, y)
        local r
        if y == 0 then
            r = (x > 0) and 270 or 90
        else
            r = math.atan(x / y) / math.pi * 180
            if y > 0 then
                r = r + 180
            end
        end
        return (r % 360) / 360
    end

    ------------------------------------------------------------------------------
    -- Slightly more complex functions
    --
    -- But still primitive enough to count

    -- Union the two absolute coordinate fields to create a full-map axial cross.
    function primitive.cross()
        return procedural.min(procedural.abs(primitive.linear_x), procedural.abs(primitive.linear_y))
    end

    -- Measure distance from a Euclidean radius to produce a constant-width circular hall.
    function primitive.ring(radius)
        return procedural.abs(procedural.sub(primitive.distance, radius))
    end

    -- Measure distance from any primitive contour to produce its source-shaped ring.
    function primitive.ringify(func, radius)
        return procedural.abs(procedural.sub(func, radius))
    end

    -- A large X-shape
    -- Union the two absolute diagonal projections into the source large X shape.
    function primitive.ex()
        return procedural.min(procedural.abs(primitive.linear_xy), procedural.abs(primitive.linear_yx))
    end

    -- Intersect the two diagonal projections into the source Manhattan distance shape.
    function primitive.diamond()
        return procedural.max(procedural.abs(primitive.linear_xy), procedural.abs(primitive.linear_yx))
    end

    -- Clip a box with an inset diamond to obtain the source octagon distance field.
    function primitive.octagon(edge)
        return procedural.max(primitive.box, procedural.sub(primitive.diamond(), edge))
    end

    -- Warp the octagon domain vertically into the source six-sided primitive.
    function primitive.hexagon(edge)
        -- Use a domain transform to warp an octagon into a hexagon
        -- There must be a less hackish way to do this but I can't think of it today...
        local foct = primitive.octagon(edge)
        -- Sample the fixed primitive.hexagon composition without further construction draws.
        return function(x, y)
            return foct(x, math.abs(y) + edge)
        end
    end

    -- Compose the three source half planes and optionally reflect their orientation.
    function primitive.triangle()
        -- This isn't a very good primitive because it's a hacked-together triangle.
        -- Should just come up with a proper algorithm at some point.
        local tri =
            procedural.max(primitive.linear_y, procedural.neg(primitive.linear_xy), primitive.linear_yx)
        if crawl.coinflip() then
            return procedural.flip_y(tri)
        end
        return tri
    end

    -- Alternate angular tooth gaps around an inner radius while retaining the outer contour.
    function complex.cog(teeth, inner, gap, offset)
        local fr = procedural.phase(primitive.radial, teeth, offset)
        -- Sample the fixed complex.cog composition without further construction draws.
        return function(x, y)
            local dp = primitive.distance(x, y)
            local d = dp / inner
            local r = fr(x, y)
            if d < 1 or dp > 1 then
                return d
            end
            if r < gap then
                return 0.99
            end
            return d
        end
    end

    -- Creates a number of rays around the origin. Offset is 0..1 to denote
    -- rotation. If converge is non-nil then the rays will be even-sized
    -- all the way along instead of diverging in size; they will converge
    -- at the radius given by converge.
    -- Scale angular phase by radius so source connectors retain their convergence width.
    function complex.rays(num, offset, converge, diverge)
        local frad = procedural.phase(primitive.radial, num, offset)
        if diverge == nil then
            diverge = 0
        end
        -- Sample the fixed complex.rays composition without further construction draws.
        return function(x, y)
            local a = frad(x, y)
            local r = primitive.distance(x, y)
            -- TODO: Work out divergence. It means (r/converge) has to tend
            -- more towards 1 for higher values of r.
            return a * r / converge
        end
    end

    procedural.transform = {}
    -- Wrap x around a cylinder and extrude y through the same 3D Worley field.
    function procedural.transform.wrapped_cylinder(source, period, radius, zscale, zoff)
        if zscale == nil then
            zscale = 1
        end
        if zoff == nil then
            zoff = 0
        end

        -- Sample the fixed procedural.transform.wrapped_cylinder composition without further construction draws.
        return function(x, y)
            -- Convert x to rads
            local a = x * 2 * math.pi / period
            -- Extrude a circle along the y axis of the original function
            return source(math.sin(a) * radius, y, math.cos(a) * radius * zscale + x * zoff)
        end
    end

    -- Transforms a cartesian domain into a polar one. In other words, it takes
    -- a rectangular shape and transforms it into a circular one, where y becomes
    -- the radius, and x becomes the angle about the origin.
    -- Map angle to x and radial distance to y for the source spiderweb geometry.
    function procedural.transform.polar(source, radius, sx, sy)
        local frad = procedural.radial({})
        if sx == nil then
            sx = 1
        end
        if sy == nil then
            sy = 1
        end

        -- Sample the fixed procedural.transform.polar composition without further construction draws.
        return function(x, y)
            local a = frad(x, y)
            local r = math.sqrt(x ^ 2 + y ^ 2) / radius
            return source(a * sx, r * sy)
        end
    end

    -- Inverse of the polar transform
    -- Invert the source polar domain using its original sine/cosine convention.
    function procedural.transform.polar_inverse(source, radius, sx, sy)
        local frad = procedural.radial({})
        if sx == nil then
            sx = 1
        end
        if sy == nil then
            sy = 1
        end

        -- Sample the fixed procedural.transform.polar_inverse composition without further construction draws.
        return function(x, y)
            local a = x / sx
            local r = radius * y / sy

            -- TODO: Check that this is properly the inverse of polar; it might have
            -- been flipped or rotated; although this doesn't matter slightly for current layouts
            return source(math.sin(a * 2 * math.pi) * r, math.cos(a * 2 * math.pi) * r)
        end
    end

    -- Distorts a function by an amount depending on another function - in this case its
    -- proximity to the map border
    -- Attenuate two simplex offsets near map edges to bend source Snake geometry.
    function procedural.transform.damped_distortion(source, options)
        -- Apply distortion
        local fdsx = procedural.simplex3d({
            scale = util.random_range_real(0.1, 1),
            unit = false,
        })
        local fdsy = procedural.simplex3d({
            scale = util.random_range_real(0.1, 1),
            unit = false,
        })
        -- Distort more at the edge of the map
        -- TODO: Could look even better with a less linear easing function
        local fbox = procedural.box({})
        -- Sample the fixed procedural.transform.damped_distortion composition without further construction draws.
        local fedge = function(x, y)
            return math.max(0, 1 - fbox(x, y))
        end
        local fdx = procedural.mul(fdsx, fedge)
        local fdy = procedural.mul(fdsy, fedge)

        return procedural.distort({
            source = source,
            scale = crawl.random_range(4, 8),
            offsetx = fdx,
            offsety = fdy,
        })
    end

    -- Construct source simplex fields with the pinned permutation and source RNG offsets.
    -- Construct one source-scaled simplex field and retain its random offsets.
    function procedural.simplex3d(params)
        local field = noise.simplex(env.builder, params.scale, params.unit ~= false)

        -- Hall simplex fields use the source's zero z slice.
        -- Sample the fixed procedural.simplex3d composition without further construction draws.
        return function(x, y)
            return noise.simplex_at(field, x, y)
        end
    end

    -- Cylinder wrapping needs all three coordinates of the same cellular field.
    -- Construct one cellular field while retaining the optional wrapped z coordinate.
    function procedural.worley_diff(params)
        local field = noise.worley(env.builder, params.scale)

        -- Preserve the optional wrapped z coordinate instead of flattening the cylinder.
        -- Sample the fixed procedural.worley_diff composition without further construction draws.
        return function(x, y, z)
            return noise.worley_at(field, x, y, z)
        end
    end

    return procedural, primitive, complex
end

return fields
