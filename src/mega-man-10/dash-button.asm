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

# Inject at: 0x800765e0
#
# Patches a function that runs only during normal gameplay and updates virtual
# inputs. Has to be here so that dash buffers out of menus and cutscenes the same
# way as Down + B.
#
# r4 contains the current virtual inputs with bit 0x8000 meaning controls are
# currently locked due to, e.g., boss cutscene or death.

  lis r5, input@h                   # \ Read Classic Controller input
  lhz r0, input@l (r5)              # /
  lis r5, state@h                   # \ Read code state
  lbz r8, state@l (r5)              # /
  andi. r8, r8, ~pressedBit@l       # > Clear pressed bit
  andi. r0, r0, button              # \ if dash button is not held:
  beq clearHeld                     # /   Go to clear held bit
  andi. r0, r4, 0x8000              # \ else if controls are locked:
  bne clearHeld                     # /   Go to clear held bit
  andi. r0, r8, heldBit             # \ else if held bit is set:
  bne end                           # /   Go to write code state
  ori r8, r8, pressedBit | heldBit  # \ else:
  b end                             # |   Set pressed and held bits
                                    # /   Go to write code state
clearHeld:                          # \ Clear held bit
  andi. r8, r8, ~heldBit@l          # /
end:                                # \ Write code state
  stb r8, state@l (r5)              # /
  rlwinm r0, r7, 0, 16, 31          # > Injected instruction

# Inject at: 0x80072248
#
# Patches a function that checks inputs and returns if a slide should be
# triggered (1) or not (0). Some code before this patch return 0 in case
# a slide is already in progress.

  lis r4, state@h                   # \ Read code state
  lbz r0, state@l (r4)              # /
  andi. r0, r0, pressedBit          # \ if pressed bit is set:
  beq end                           # |   Return 1 to trigger dash
  li r3, 0x0001                     # |
  blr                               # /
end:                                # \ else:
  lhz r0, 0x0194 (r3)               # /   Injected instruction: continue to original code
