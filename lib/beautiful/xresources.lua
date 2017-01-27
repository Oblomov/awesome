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
local util = require("awful.util")
local a_screen = require("awful.screen")
local round = util.round
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


local function get_screen(s)
    return s and screen[s]
end

--- Get global or per-screen DPI value falling back to xrdb.
-- @tparam[opt] integer|screen s The screen.
-- @treturn number DPI value.
function xresources.get_dpi(s)
    if s then
        util.deprecate("Use s.dpi instead of beautiful.xresources.get_dpi")
    else
        util.deprecate("Use awful.screen.get_fallback_dpi instead of beautiful.xresources.get_dpi")
    end
    s = get_screen(s)
    if s then
        return s.dpi
    else
        return a_screen.get_fallback_dpi()
    end
end


--- Set DPI for a given screen (defaults to global).
-- @tparam number dpi DPI value.
-- @tparam[opt] integer s Screen.
function xresources.set_dpi(dpi, s)
    if s then
        util.deprecate("Use s.dpi= instead of beautiful.xresources.set_dpi")
    else
        util.deprecate("Use awful.screen.set_fallback_dpi instead of beautiful.xresources.set_dpi")
    end
    s = get_screen(s)
    if not s then
        a_screen.set_fallback_dpi(dpi)
    else
        s.dpi = dpi
    end
end


--- Compute resulting size applying current DPI value (optionally per screen).
-- @tparam number size Size
-- @tparam[opt] integer|screen s The screen.
-- @treturn integer Resulting size (rounded to integer).
function xresources.apply_dpi(size, s)
    if s then
        util.deprecate("Use s.apply_scaling instead of beautiful.xresources.apply_dpi_dpi")
        return s:apply_scaling(size)
    else
        util.deprecate("Use awful.screen.apply_fallback_scaling instead of beautiful.xresources.set_dpi")
        return a_screen.apply_fallback_scaling(size)
    end
end

return xresources

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
