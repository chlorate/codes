# Inject at:
# - WXRE: 0x80049d4c
#
# This patches a stage loading routine (called by both the retry stage code and
# the Retry option in the pause menu in Time Attack) to always reset the
# refights in Wily 4.
#
# When the retry checkpoint code is used, it sets the refight state in a way
# such that kills will persist after respawning. This also causes the Retry
# pause menu option to also do this which is not what it does normally. This
# patch ensures the refights are reset properly when using the Retry option.

# WRXE addresses:
.set currentRefightKills, 0x80510661

lis r4, currentRefightKills@h       # \ Reset refights
stb r0, currentRefightKills@l (r4)  # / (r0 is 0x0000)
li r4, 0x0900                       # > Injected instruction
