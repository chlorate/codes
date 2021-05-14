# Inject at:
# - WXRE: 0x80042114
#
# This fixes Proto Man's whistle overlapping when spamming the retry codes.

# WRXE addresses:
.set stopAudio, 0x8001f3cc

lis r3, stopAudio@h      # \ Call function that stops music and sounds
ori r3, r3, stopAudio@l  # |
mtctr r3                 # |
bctrl                    # /
lis r3, 0x8051           # > Injected instruction
