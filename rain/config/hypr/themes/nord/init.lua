-- Nord: even, smooth motion
hl.curve("nordSpatial", {
  type = "bezier",
  points = {{0.42, 1.67}, {0.21, 0.90}}
})
hl.animation({
  leaf = "windowsMove",
  enabled = true,
  speed = 3.5,
  bezier = "nordSpatial"
})
