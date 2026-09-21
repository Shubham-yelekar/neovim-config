// Effect: Cursor Flame Trail
// Creates a fire / ember-like trail behind the cursor.
//
// Based on:
// https://gist.github.com/chardskarth/95874c54e29da6b5a36ab7b50ae2d088

...

// Based on Inigo Quilez's article on 2D Signed Distance Functions:
// https://iquilezles.org/articles/distfunctions2d/
//
// Potentially optimized by removing branches and loops
// to improve performance.

...

// ------------------------------------------------------------
// Adjustable Parameters
// ------------------------------------------------------------

// Trail color
const vec4 TRAIL_COLOR = vec4(1.0, 1.0, 1.0, 1.0);

// Current cursor color
const vec4 CURRENT_CURSOR_COLOR = TRAIL_COLOR;

// Previous cursor color
const vec4 PREVIOUS_CURSOR_COLOR = TRAIL_COLOR;

// Highlight / Accent color used for the trail
const vec4 TRAIL_COLOR_ACCENT = vec4(1.0, 1.0, 1.0, 1.0);

// Animation duration (seconds)
//
// Larger value
//   → Trail lasts longer
//
// Smaller value
//   → Trail fades more quickly
const float DURATION = .5;

// Overall trail opacity
//
// Larger value
//   → More visible
//
// Smaller value
//   → More subtle
const float OPACITY = .2;

// Minimum movement distance before drawing a trail.
//
// Measured as:
//
//     DRAW_THRESHOLD × cursor size
//
// This prevents tiny cursor movements while typing
// from constantly generating trails.
const float DRAW_THRESHOLD = 1.5;

// Hide trails when the cursor moves only within
// the same line.
//
// Same-line cursor movement usually happens during typing,
// where trails may feel distracting.
//
// false
//     Always draw trails.
//
// true
//     Only draw trails when changing lines.
const bool HIDE_TRAILS_ON_THE_SAME_LINE = false;

...

// Normalize fragment coordinates
// into the range [-1, 1].

...

// Normalize cursor position and size.
//
// xy = cursor position
// zw = cursor width and height

...

// When drawing the trail, a parallelogram is created
// between the previous and current cursor positions.
//
// This determines whether the shape starts from
// the top-left or top-right corner.

...

// Define the four vertices
// of the trail parallelogram.

...

// Animation progress.

...

// Cursor distance determines
// the total trail length.

...

// Only draw a trail if:
//
// • Cursor moved far enough.
// • (Optionally) Cursor changed lines.

...

// Distance from current fragment
// to the end of the trail.

...

// Clamp alpha to avoid values > 1.

...

// Signed Distance Function
// for the current cursor.

...

// Signed Distance Function
// for the trail.

...

// Blend:
//
// 1. Accent color
// 2. Main trail color
// 3. Fade according to animation progress
// 4. Keep the current cursor sharp
