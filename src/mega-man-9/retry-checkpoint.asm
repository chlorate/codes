.set state,        0x81000000
.set pressedBit,   0b00000001
.set activatedBit, 0b00000010
.set buttonCombo,  0b0001000000010000  # Select + A

# WR9E addresses:
.set input,               0x80319e0a
.set mode,                0x803140c0
.set currentRefightKills, 0x803051d9
.set initialRefightKills, 0x80316305
.set objectSpawns,        0x8043cf7c

# WR9P addresses:
.set input,               0x80319e4a
.set mode,                0x80314100
.set currentRefightKills, 0x80305219
.set initialRefightKills, 0x80316345
.set objectSpawns,        0x8043cfbc

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
# - Respawning during normal gameplay crashes in the Wily 1 beam rooms.
# - Respawning during boss intros causes a crash after the stage is beaten and
#   can load the wrong set of enemy data.
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
  lis r0, 0x0000                           # | \ Set all stage object spawn bits
  not r0, r0                               # | | (in particular, to respawn energy pickups)
  lis r3, objectSpawns@h                   # | |
  ori r3, r3, objectSpawns@l               # | |
  li r5, 0x007c                            # | |
loopRespawnObjects:                        # | |
  stwx r0, r3, r5                          # | |
  subic. r5, r5, 0x0004                    # | |
  bge loopRespawnObjects                   # | /
  lis r3, currentRefightKills@h            # | \ Save current boss refight kill state
  lbz r3, currentRefightKills@l (r3)       # | |
  stb r3, initialRefightKills@l (r11)      # | / (optimization: r11 uses same high halfword)
  li r12, 0x0008                           # | > Set mode to respawn at beginning of stage
                                           # /   (+ fall through to deactivate)
deactivate:                                # \ Deactivate:
  andi. r10, r10, ~activatedBit@l          # |   Clear activated bit
                                           # /   (+ fall through to write mode)
writeMode:                                 # \ Write mode:
  sth r12, mode@l (r11)                    # /   Write new mode

end:
  stb r10, state@l (r9)                    # > Write new code state
  blr
