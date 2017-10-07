----------------------------------------------------------------------------
--- Library for getting xrdb data.
--
-- @author Yauhen Kirylau &lt;yawghen@gmail.com&gt;
-- @copyright 2015 Yauhen Kirylau
-- @module beautiful.xresources
----------------------------------------------------------------------------

-- Grab environment
local awesome = awesome
local screen = screen
local round = require("gears.math").round
local gears_debug = require("gears.debug")

local xresources = {}

local fallback = {
  --black
  color0 = '#000000',
  color8 = '#465457',
  --red
  color1 = '#cb1578',
  color9 = '#dc5e86',
  --green
  color2 = '#8ecb15',
  color10 = '#9edc60',
  --yellow
  color3 = '#cb9a15',
  color11 = '#dcb65e',
  --blue
  color4 = '#6f15cb',
  color12 = '#7e5edc',
  --purple
  color5 = '#cb15c9',
  color13 = '#b75edc',
  --cyan
  color6 = '#15b4cb',
  color14 = '#5edcb4',
  --white
  color7 = '#888a85',
  color15 = '#ffffff',
  --
  background  = '#0e0021',
  foreground  = '#bcbcbc',
}

--- Get current base colorscheme from xrdb.
-- @treturn table Color table with keys 'background', 'foreground' and 'color0'..'color15'
function xresources.get_current_theme()
    local keys = { 'background', 'foreground' }
    for i=0,15 do table.insert(keys, "color"..i) end
    local colors = {}
    for _, key in ipairs(keys) do
        colors[key] = awesome.xrdb_get_value("", key)
        if not colors[key] then
            gears_debug.print_warning("beautiful: can't get colorscheme from xrdb (using fallback).")
            return fallback
        end
        if colors[key]:find("rgb:") then
            colors[key] = "#"..colors[key]:gsub("[a]?rgb:", ""):gsub("/", "")
        end
    end
    return colors
end


--- Store the cached or user-set per-screen DPI
-- Values are tables with key dpi (the dpi) and set_from (user, auto, xrdb)
-- The same is done for xresources.dpi
local dpi_per_screen = {}

local dpi_scale_rounding = nil

local function get_screen(s)
    return s and screen[s]
end

local function rounded_dpi(dpi)
    if dpi_scale_rounding then
        local rounded = 96*dpi_scale_rounding(dpi/96)
        return rounded
    else
        return dpi
    end
end

--- Compute the global DPI from the core protocol information
local function set_global_dpi()
    xresources.dpi = nil
    -- Might not be present when run under unit tests
    if awesome and awesome.xrdb_get_value then
        local xft_dpi = tonumber(awesome.xrdb_get_value("", "Xft.dpi"))
        if xft_dpi then
            xresources.dpi = {
                dpi = xft_dpi,
                set_from = 'xrdb'
            }
        end
    end
    -- Following Keith Packard's whitepaper on Xft,
    -- https://keithp.com/~keithp/talks/xtc2001/paper/xft.html#sec-editing
    -- the proper fallback for Xft.dpi is the vertical DPI reported by
    -- the X server. This will generally be 96 on Xorg, unless the user
    -- has configured it differently
    if not xresources.dpi then
        if root then
            local mm_to_inch = 25.4
            local _, h = root.size()
            local _, hmm = root.size_mm()
            if hmm ~= 0 then
                xresources.dpi = {
                    dpi = rounded_dpi(h*mm_to_inch/hmm),
                    set_from = 'auto'
                }
            end
        end
    end
    -- ultimate fallback
    if not xresources.dpi then
        xresources.dpi = { dpi = 96, set_from = 'auto' }
    end
end


--- Recompute autodetected DPI values
--
-- This function should be invoked whenever automatically-compued DPI might have
-- changed (e.g. RANDR signal, or DPI-rounding function changes)
local function recalc_auto_dpi()
    if xresources.dpi and xresources.dpi.set_from == 'auto' then
        set_global_dpi()
    end
    for s, dpi in pairs(dpi_per_screen) do
        if dpi.set_from == 'auto' then
            dpi_per_screen[s] = {
                dpi = rounded_dpi(s.dpi),
                set_from = 'auto'
            }
        end
    end
end

screen.connect_signal("property::geometry", recalc_auto_dpi)
screen.connect_signal("property::outputs", recalc_auto_dpi)


--- Get global or per-screen DPI value falling back to xrdb.
-- @tparam[opt] integer|screen s The screen.
-- @treturn number DPI value.
function xresources.get_dpi(s)
    s = get_screen(s)
    if s then
        if not dpi_per_screen[s] then
            dpi_per_screen[s] = {
                dpi = rounded_dpi(s.dpi),
                set_from = 'auto'
            }
        end
        return dpi_per_screen[s].dpi
    end
    if not xresources.dpi then
        set_global_dpi()
    end
    return xresources.dpi.dpi
end


--- Set DPI for a given screen (defaults to global).
-- @tparam number dpi DPI value.
-- @tparam[opt] integer s Screen.
function xresources.set_dpi(dpi, s)
    s = get_screen(s)
    local dpi_spec = { dpi = dpi, set_from = 'user' }
    if not s then
        xresources.dpi = dpi_spec
    else
        dpi_per_screen[s] = dpi_spec
    end
end

--- Set a rounding mode for autodetected DPIs
--
-- If set, beautiful will round the screen DPI to a multiple of the reference
-- 96 DPI, according to the function used
-- @tparam function a function to be applied to the DPI scaling factor
function xresources.set_dpi_rounding(func)
    dpi_scale_rounding = func
    recalc_auto_dpi()
end


--- Compute resulting size applying current DPI value (optionally per screen).
-- @tparam number size Size
-- @tparam[opt] integer|screen s The screen.
-- @treturn integer Resulting size (rounded to integer).
function xresources.apply_dpi(size, s)
    if not size then return size end
    local scale = xresources.get_dpi(s)/96
    return round(size * scale)
end

return xresources

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
