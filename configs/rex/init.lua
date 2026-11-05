-- Rex configuration.
--
-- Rex reads this file from ~/.config/rex/init.lua.
-- Validate changes with:
--   rex config check
-- Reload a valid configuration with:
--   rex config reload
--
-- Add bindings, modes, actions, or host declarations here as needed.
-- See https://www.superlogical.com/rex/docs/customize/config.md

-- Custom shortcuts migrated from Rex.app's settings layer.
rex.bind("shift+cmd+r", "session.rename")
rex.bind("shift+cmd+h", "pane.focus.left")
rex.bind("shift+cmd+l", "pane.focus.right")
rex.bind("shift+cmd+k", "pane.focus.up")
rex.bind("shift+cmd+j", "pane.focus.down")

-- Select a window by position within the action's current session.
rex.action{
  name = "session_tab_goto",
  title = "Go to Session Tab",
  description = "Select a numbered tab within the current session.",
  args = { index = "integer" },
  run = function(ctx, args)
    local view, err = rex.session.view{}
    if err ~= nil then error(err, 0) end
    if view == nil or view.windows == nil then
      error("Could not inspect the current session's tabs", 0)
    end

    local window = view.windows[args.index]
    if window == nil then
      error("No tab " .. args.index .. " in the current session", 0)
    end

    local _, focus_err = rex.session.focus_window{
      window_id = window.window_id,
    }
    if focus_err ~= nil then error(focus_err, 0) end

    if ctx ~= nil and ctx.client_id ~= nil then
      rex.client.queue("session.select", {
        session_id = ctx.session_id,
        window_id = window.window_id,
      })
    end

    return { window_id = window.window_id }
  end,
}

-- Jump to a numbered tab in the currently selected session.
for index = 1, 9 do
  rex.bind("cmd+[Digit" .. index .. "]", "session_tab_goto", { index = index })
end

rex.action{
  name = "project_session_picker",
  title = "Open Project Session",
  description = "Choose a project and open Helix, an agent, and a shell.",
  run = function()
    local layer, err = rex.session.new_layer{
      bounds = { 0.1, 0.1, 0.8, 0.8 },
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        options = {
          shell = "none",
          command = {
            "zsh",
            "-f",
            "-c",
            'exec "$HOME/.config/rex/scripts/project-session-bootstrap"',
          },
        },
      },
    }
    if err ~= nil then error(err, 0) end
    if layer == nil then error("Could not create the project picker layer", 0) end

    return {
      layer_id = layer.layer_id,
      block_id = layer.block_ids and layer.block_ids[1],
    }
  end,
}

rex.bind("ctrl+shift+[KeyP]", "project_session_picker")

-- Remove the default arrow-key focus shortcuts.
rex.unbind("alt+cmd+left")
rex.unbind("alt+cmd+right")
rex.unbind("alt+cmd+up")
rex.unbind("alt+cmd+down")
