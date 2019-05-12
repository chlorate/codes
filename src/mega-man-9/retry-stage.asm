.set state,        0x81000000
.set pressedBit,   0b00000100
.set activatedBit, 0b00001000
.set buttonCombo,  0b0001000000001000  # Select + X

# WR9E addresses:
.set input,               0x80319e0a
.set mode,                0x803140c0
.set initialRefightKills, 0x80316305

# WR9P addresses:
.set input,               0x80319e4a
.set mode,                0x80314100
.set initialRefightKills, 0x80316345

# Registers:
# - r9: retryState address (high halfword)
# - r10: retryState value
# - r11: mode address (high halfword)
# - r12: mode value

  lis r9, state@h                          # \ Read code state
  lbz r10, state@l (r9)                    # /
  lis r11, mode@h                          # \ Read game mode
  lhz r12, mode@l (r11)                    # /
  lis r3, input@h+0x10000                  # \ Read Classic Controller input
  lhz r3, input@l-0x10000 (r3)             # / (optimization: one less instruction)

# Input check: Activate when the button combo is pressed and then don't activate
# again until the button combo is released. This avoids rapidly activating when
# the button combo is held.

  cmplwi r3, buttonCombo                   # \ if Select + A is not pressed:
  beq pressed                              # |   Clear pressed bit
  andi. r10, r10, ~pressedBit@l            # |
  b activation                             # /
pressed:                                   # \ else if pressed bit is cleared:
  andi. r0, r10, pressedBit                # |   Set pressed and activated bits
  bgt activation                           # |
  ori r10, r10, pressedBit | activatedBit  # /

# Activation: When the activated bit is set, a respawn will be triggered when it
# is safe to do so.
#
# The game allows respawning any time after starting a new game (e.g., during
# stage select or boss intros). Most of the time it works, but there are some
# edge cases that cause issues:
#
# - Respawning during boss intros causes a crash after the stage.
# - Respawning crashes if no stage has been played yet.
#
# To avoid these issues, the code only respawns when the challenge or pause
# menus are open. During normal gameplay, the pause menu is forced open before
# respawning.

activation:
  andi. r0, r10, activatedBit              # \ if activated bit is cleared:
  beq end                                  # /   Do nothing
  cmplwi r12, 0x0009                       # \ else if mode == first stage fade-in frame:
  beq deactivate                           # /   Deactivate, write mode (unchanged)
  cmplwi r12, 0x000a                       # \ else if mode == normal gameplay:
  beq openPauseMenu                        # /   Open pause menu, write mode
  cmplwi r12, 0x0100                       # \ else if mode == first pause menu fade-in frame:
  beq respawn                              # /   Respawn, deactivate, write mode
  cmplwi r12, 0x0101                       # \ else if mode == pause menu:
  beq respawn                              # /   Respawn, deactivate, write mode
  cmplwi r12, 0x0a01                       # \ else if mode == challenge menu:
  beq respawn                              # /   Respawn, deactivate, write mode
  b end                                    # > else: Do nothing
openPauseMenu:                             # \ Open pause menu:
  li r12, 0x000b                           # |   Set mode to fade to pause menu
  b writeMode                              # /   (+ write mode)
respawn:                                   # \ Respawn:
  li r3, 0x0000                            # | \ Clear boss refight kill state
  stb r3, initialRefightKills@l (r11)      # | / (optimization: r11 has same high halfword)
  li r12, 0x0007                           # | > Set mode to respawn at beginning of stage
                                           # /   (+ fall through to deactivate)
deactivate:                                # \ Deactivate:
  andi. r10, r10, ~activatedBit@l          # |   Clear activated bit
                                           # /   (+ fall through to write mode)
writeMode:                                 # \ Write mode:
  sth r12, mode@l (r11)                    # /   Write new mode

end:
  stb r10, state@l (r9)                    # > Write new code state
  blr
