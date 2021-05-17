.set version, 'E'

.set pressedState, 0x81000000
.set pressedBit,   0b00010000
.set buttonCombo,  0b0001000000010000  # Select + A

.set changerState, 0x81000002
.set changerBits,  0b0000000000000000  # Gameplay states only
.set newGameState, 0x0008

.if version == 'E'
  .set input, 0x804534ea
.endif

  lis r9, pressedState@h         # \ Read pressed state
  lbz r10, pressedState@l (r9)   # /

  lis r3, input@h                # \ Read Classic Controller input
  lhz r3, input@l (r3)           # /
  cmplwi r3, buttonCombo         # \ Clear pressed bit if button combo is
  beq pressed                    # | not pressed
  andi. r10, r10, ~pressedBit@l  # |
  b writePressed                 # /

pressed:
  andi. r0, r10, pressedBit      # > Check if already pressed
  bgt end
  lis r5, changerBits            # \ Write payload for game state changer code
  ori r5, r5, newGameState       # |
  lis r3, changerState@h         # |
  stw r5, changerState@l (r3)    # /
  ori r10, r10, pressedBit       # > Set pressed bit

writePressed:
  stb r10, pressedState@l (r9)   # > Write new pressed state

end:
  blr
