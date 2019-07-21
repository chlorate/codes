# Inject at: 0x80072248
#
# Bind a button directly to Bass' dash. This differs from Down + B in that Bass
# doesn't jump when it is pressed during a dash (X and Zero style) and it
# doesn't prevent you from grabbing ladder or jumping while it is held.

.set pressed, 0x804534ee

# Pick one:
.set button, 0x2000  # L
.set button, 0x0200  # R
.set button, 0x0080  # ZL
.set button, 0x0004  # ZR

  lis r4, pressed@h       # \ if dash button is not pressed:
  lhz r0, pressed@l (r4)  # |   Continue to original code (checking Down + B)
  andi. r0, r0, button    # |
  beq end                 # /
  li r3, 0x0001           # \ Return 1 to trigger dash
  blr                     # /
end:
  lhz r0, 0x0194 (r3)     # > Injected instruction
