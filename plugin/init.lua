--[[

This Plugin does the following:
 1. Makes the titlebar (this is where the tabs are located) to be transparent
 2. Randomize the appearance of the left and right ends of the tabs
 3. Provide a function to suggest the tab's name/label
 4. Provide a handler for the format-tab-title event. Essentially, it changes the
    tab's shape, shows the process icon on its left and autoname the tab, and changes
    the tabs color when in the active, inactive and hover states.
 5. Provide a event handler to add the option to rename current tab in the
    command palette.
 6. Allow the use of the LEADER t keys to rename the active tab.
 7. Allow the use of CTRL+SHIFT+ 1, 2, 3, 4, 5, 6, 7, 8 or 9 to goto the 1st to 9th tab.
 8. Allow the use of ALT+SHIFT+{ and ALT+SHIFT+} to reposition the current tab to the left and right.
 9. Show the date and time on the left end of the tab bar (i.e. titlebar)

Written by: sunbearc22
Tested on: Ubuntu 24.04.3, wezterm 20251025-070338-b6e75fd7
--]]
local M = {}

local wezterm = require("wezterm")
local act = wezterm.action

function M.apply_to_config(config, opts)
  local rename_tab_key = opts.rename_tab_key or "t"
  local rename_tab_mods = opts.rename_tab_mods or "LEADER"
  local activate_left_key = opts.activate_left_key or "["
  local activate_right_key = opts.activate_right_key or "]"
  local activate_mods = opts.activate_mods or "ALT"
  local move_left_key = opts.move_left_key or "{"
  local move_right_key = opts.move_right_key or "}"
  local move_mods = opts.move_mods or "ALT|SHIFT"
  local snums = opts.snums or { "!", "@", "#", "$", "%", "^", "&", "*", "(" }

  -- Make the titlebar (when active and inactive) transparent
  -- This is where the wezterm tabs, left and right status are located.
  config.window_frame = {
    inactive_titlebar_bg = "none",
    active_titlebar_bg = "none",
  }

  -- Randomize the shape of the tab's left and right ends
  math.randomseed(os.time())
  local left_tab_end = {
    "", -- nf-ple-left_half_circle_thick
    "", -- nf-pl-right_hard_divider
    "", -- nf-ple-lower_right_triangle
    "", -- nf-ple-upper_right_triangle
    "", -- nf-ple-pixelated_squares_big_mirrored
    "", -- nf-ple-left_hard_divider_inverse
    "󰉣", -- nf-md-format_align_right
  }
  local right_tab_end = {
    "", -- nf-ple-right_half_circle_thick
    "", -- nf-pl-left_hard_divider
    "", -- nf-ple-lower_left_triangle
    "", -- nf-ple-upper_left_triangle
    "", -- nf-ple-pixelated_squares_big
    "", -- nf-ple-right_hard_divider_inverse
    "󰉢", -- nf-md-format_align_left
  }
  local lte = math.random(1, 7)
  local rte = math.random(1, 7)
  local LEFT_TAB_END = left_tab_end[lte]
  local RIGHT_TAB_END = right_tab_end[rte]

  -- This function returns the suggested title for a tab.
  -- It prefers the title that was set via `tab:set_title()`
  -- or `wezterm cli set-tab-title`, but falls back to the
  -- title of the active pane in that tab.
  local function tab_title(tab_info)
    local title = tab_info.tab_title
    wezterm.info("[TABS] 1 type(title)=" .. type(title))
    if title == nil then
      return "Untitled"
    end
    -- Ensure it's a string (in case it's some other type)
    if type(title) ~= "string" then
      return tostring(title)
    end
    -- if the tab title is explicitly set, take that
    if title then
      -- Handle empty titles
      if title == "" then
        return "Untitled"
      end
      return title
    end
    -- -- Otherwise, use the title from the active pane in that tab
    -- title = tab_info.active_pane.title
    -- if not title or #title == 0 then
    --   title = tab_info.active_pane.current_working_dir
    -- end
    -- wezterm.info("[TABS] 2 title=" .. title .. " type(title)=" .. type(title))
    -- return title
  end

  wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    -- Color when the tab is inactive
    local edge_background = "none"                     -- The area behind the tab (make transparent)
    local background = wezterm.GLOBAL.system.shades[4] -- The tab's area
    local foreground = wezterm.GLOBAL.system.shades[9] -- The tab's font

    if tab.is_active then
      -- Color of the tab when it is active
      background = wezterm.GLOBAL.system.color
      foreground = wezterm.GLOBAL.system.tints[7]
    elseif hover then
      -- Color of the tab when the mouse cursor hovers over the tab
      background = wezterm.GLOBAL.system.analogous[2]
      foreground = wezterm.GLOBAL.system.shades[7]
    end

    -- Color of the left and right ends of the tab to be the same color as the tab
    local edge_foreground = background

    -- Create the tab's title
    local title = tab_title(tab)

    -- Ensure that the titles fit in the available space,
    -- and that we have room for the edges.
    wezterm.info("[TABS] max_width=" .. max_width)
    title = wezterm.truncate_right(title, max_width - 2)

    -- Get the logo of the process named in title.
    local process_icons = {
      wezterm = "$W", -- WezTerm terminal
      wez = "$W", -- WezTerm terminal (short form)
      nvim = "", -- nf-linux-neovim
      yazi = "󰇥", -- nf-md-duck
      bash = "", -- nf-mdi-console
      ssh = "󰣀", -- nf-linux-ssh
      dns = "󰇖", -- nf-linux-dns
      python = "", -- nf-fa-python
      lua = "󰢱", -- nf-md-language_lua
      ollama = "🦙", -- https://emojipedia.org/llama
      gimp = "", -- nf-mdi-image-filter-vintage
      inkscape = "", -- nf-mdi-vector-rectangle
      krita = "", -- nf-mdi-palette
      freecad = "", -- nf-mdi-cube-outline
      kdenlive = "", -- nf-mdi-video
      libreoffice = "", -- nf-linux-libreoffice
      libreofficebase = "", -- nf-linux-libreoffice-base
      libreofficecalc = "", -- nf-linux-libreoffice-calc
      libreofficeimpress = "", -- nf-linux-libreoffice-impress
      libreofficemath = "", -- nf-linux-libreoffice-mathwezterm.truncate_right
      libreofficewriter = "", -- nf-linux-libreoffice-writer
      steam = "", -- nf-linux-steam
      thunderbird = "", -- nf-linux-thunderbird
    }
    local lower_title = string.lower(title)
    local logo = ""
    for pattern, icon in pairs(process_icons) do
      if lower_title:find(pattern) then
        logo = icon
        break -- Found match, no need to check further
      end
    end

    -- Create a new LEFT-TAB_END with the logo
    local LOGO_LEFT_TAB_END = logo .. " " .. LEFT_TAB_END

    -- Return the tab's new configuration
    return {
      { Background = { Color = edge_background } }, -- tab's left end
      { Foreground = { Color = edge_foreground } }, --      "
      { Text = LOGO_LEFT_TAB_END },                 --      "
      { Background = { Color = background } },      -- tab's middle region
      { Foreground = { Color = foreground } },      --      "
      { Text = title },                             --      "
      { Background = { Color = edge_background } }, -- tab's right end
      { Foreground = { Color = edge_foreground } }, --      "
      { Text = RIGHT_TAB_END },                     --      "
    }
  end)

  -- Event handler to add an option in the command palette to rename current tab.
  wezterm.on("augment-command-palette", function(window, pane)
    return {
      {
        brief = "Rename Tab",
        icon = "md_rename_box",
        action = act.PromptInputLine({
          description = "Enter new name for tab",
          initial_value = "",
          action = wezterm.action_callback(function(window, pane, line)
            if line then
              window:active_tab():set_title(line)
            end
          end),
        }),
      },
    }
  end)

  -- Load keys into config.keys
  if not config.keys then
    config.keys = {}
  end

  for i, snum in ipairs(snums) do
    -- Insert ActivateTab keys - absolute activation of tab
    table.insert(config.keys,
      { key = tostring(i), mods = activate_mods, action = act.ActivateTab(i - 1) }
    )
    -- Insert MoveTab keys - absolute moving of tab
    table.insert(config.keys,
      { key = snum, mods = move_mods, action = act.MoveTab(i - 1) }
    )
  end
  -- Other keys
  local keys = {
    -- activate tab on the left and right.
    { key = activate_left_key,  mods = activate_mods, action = act.ActivateTabRelativeNoWrap(-1) },
    { key = activate_right_key, mods = activate_mods, action = act.ActivateTabRelativeNoWrap(1) },
    -- move tab to the left and right.
    { key = move_left_key,      mods = move_mods,     action = act.MoveTabRelative(-1) },
    { key = move_right_key,     mods = move_mods,     action = act.MoveTabRelative(1) },
    -- Rename active tab keys
    {
      key = rename_tab_key,
      mods = rename_tab_mods,
      action = act.PromptInputLine(
        {
          description = "Enter new name for tab",
          initial_value = "",
          action = wezterm.action_callback(function(window, pane, line)
            if line then
              window:active_tab():set_title(line)
            end
          end)
        }
      )
    },
  }
  for _, key in ipairs(keys) do
    table.insert(config.keys, key)
  end

  -- Show date & time on the left of all tabs
  wezterm.on("update-status", function(window, pane)
    local date = wezterm.strftime("%a %b %e  %I:%M:%S %p")

    -- Make it italic and underlined
    window:set_left_status(wezterm.format({
      { Attribute = { Underline = "Curly" } },
      { Attribute = { Italic = true } },
      { Attribute = { Intensity = "Half" } },
      { Foreground = { Color = wezterm.GLOBAL.system.triadic[3] } },
      { Background = { Color = "none" } },
      { Text = date .. " " },
    }))
  end)
end

return M
