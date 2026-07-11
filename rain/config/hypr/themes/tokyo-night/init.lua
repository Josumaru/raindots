-- Tokyo Night: snappy, responsive
hl.curve("tokyoNightAccel", {
  type = "bezier",
  points = {{0.3, 0}, {0.8, 0.15}}
})
hl.animation({
  leaf = "windowsMove",
  enabled = true,
  speed = 5,
  bezier = "tokyoNightAccel",
  style = "slide"
})
