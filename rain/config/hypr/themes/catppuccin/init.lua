-- Catppuccin: soft curves
hl.curve("catppuccinSpatial", {
  type = "bezier",
  points = {{0.38, 1.21}, {0.22, 1.00}}
})
hl.animation({
  leaf = "windowsMove",
  enabled = true,
  speed = 4,
  bezier = "catppuccinSpatial"
})
