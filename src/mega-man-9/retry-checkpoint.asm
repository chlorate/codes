.set state,        0x81000000
.set pressedBit,   0b00000001
.set activatedBit, 0b00000010
.set buttonCombo,  0b0001000000010000  # Select + A

# WR9E addresses:
.set input, 0x80319e0a
.set mode,  0x803140c0

# WR9P addresses:
.set input, 0x80319e4a
.set mode,  0x80314100

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
# edge cases that cause a crash:
#
# - Respawning during normal gameplay crashes in the Wily 1 beam rooms.
# - Respawning during boss intros causes a crash after the stage is beaten.
#
# To avoid these crashes, the code only respawns when the challenge or pause
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
  li r12, 0x0008                           # |   Set mode to respawn at last checkpoint
                                           # /   (+ fall through to deactivate)
deactivate:                                # \ Deactivate:
  andi. r10, r10, ~activatedBit@l          # |   Clear activated bit
                                           # /   (+ fall through to write mode)
writeMode:                                 # \ Write mode:
  sth r12, mode@l (r11)                    # /   Write new mode

end:
  stb r10, state@l (r9)                    # > Write new code state
  blr
