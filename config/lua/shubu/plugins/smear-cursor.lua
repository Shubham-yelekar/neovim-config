-- Animated cursor trail. Draws the smear with ordinary text characters, so it
-- works in any terminal - no graphics protocol needed.
return {
  "sphamba/smear-cursor.nvim",
  opts = {

    smear_between_buffers = true,
    smear_between_neighbor_lines = true,
    scroll_buffer_space = true,

    -- The smear is shaded with block characters from the Legacy Computing
    -- block (U+1FB00). JetBrainsMono Nerd Font doesn't patch those in, so this
    -- stays false - turning it on would render the trail as missing glyphs.
    legacy_computing_symbols_support = false,

    -- Without legacy symbols the plugin fakes the shading by painting cells in
    -- the background colour. It reads that colour from the Normal highlight,
    -- which catppuccin leaves unset because transparent_background = true - so
    -- the trail would smear black boxes over the transparent window. This is
    -- mocha's base, the colour the background would have been.
    transparent_bg_fallback_color = "#1e1e2e",

    -- Defaults are 0.6 / 0.45. Lower and equal makes the tail lag further
    -- behind the cursor and settle more slowly - a longer, lazier smear.
    stiffness = 0.5,
    trailing_stiffness = 0.5,

    matrix_pixel_threshold = 0.5,
  },
}
