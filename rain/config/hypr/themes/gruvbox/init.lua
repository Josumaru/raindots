-- Gruvbox: relaxed, warm motion
hl.curve("gruvboxDecel", {
  type = "bezier",
  points = {{0.05, 0.7}, {0.1, 1.0}}
})
hl.animation({
  leaf = "windowsIn",
  enabled = true,
  speed = 3,
  bezier = "gruvboxDecel",
  style = "popin 80%"
})
