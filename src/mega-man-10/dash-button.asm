# Bind a button directly to Bass' dash. This differs from Down + B in that Bass
# doesn't jump when it is pressed during a dash (X and Zero style) and it
# doesn't prevent you from grabbing ladders or jumping while it is held.

.set state,      0x81000001
.set pressedBit, 0b00000010
.set heldBit,    0b00000100

.set input, 0x804534ea

# Pick one:
.set button, 0x2000  # L
.set button, 0x0200  # R
.set button, 0x0080  # ZL
.set button, 0x0004  # ZR

# Inject at: 0x800765fc
  lis r4, input@h                   # \ Read Classic Controller input
  lhz r0, input@l (r4)              # /
  lis r4, state@h                   # \ Read code state
  lbz r5, state@l (r4)              # /
  andi. r5, r5, ~pressedBit@l       # > Clear pressed bit
  andi. r0, r0, button              # \ if dash button is not held:
  bne held                          # |   Clear held bit
  andi. r5, r5, ~heldBit@l          # |
  b end                             # /
held:                               # \ else if held bit is not set:
  andi. r0, r5, heldBit             # |   Set pressed and held bits
  bne end                           # |
  ori r5, r5, pressedBit | heldBit  # /
end:
  stb r5, state@l (r4)              # > Write code state
  blr                               # > Injected instruction

# Inject at: 0x80072248
  lis r4, state@h                   # \ Read code state
  lbz r0, state@l (r4)              # /
  andi. r0, r0, pressedBit          # \ if pressed bit is set:
  beq end                           # |   Return 1 to trigger dash
  li r3, 0x0001                     # |
  blr                               # /
end:                                # \ else:
  lhz r0, 0x0194 (r3)               # /   Injected instruction: continue to original code
