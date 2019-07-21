# Inject at: 0x80089e40 (same for both WR9E and WR9P)
#
# This fixes music playing over Proto Man's whistle when using the retry and
# Proto Man Time Attack codes. Normally, any music that plays before entering
# a stage with Proto Man does not loop and is silent by the time the whistle
# plays.

# WR9E addresses:
.set stopMusic, 0x800d432c

# WR9P addresses:
.set stopMusic, 0x800d4398

lis r3, stopMusic@h      # \ Call function that stops music
ori r3, r3, stopMusic@l  # |
mtctr r3                 # |
bctrl                    # /
li r0, 0x0000            # > Injected instruction
