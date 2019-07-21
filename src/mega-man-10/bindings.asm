.set bindings, 0x802e7754
.set downIndex, 0x0006
.set yIndex, 0x0012
.set bIndex, 0x0016
.set rIndex, 0x0026
.set lIndex, 0x002a

.set a, 0x0010
.set x, 0x0008
.set l, 0x2000
.set r, 0x0200
.set zl, 0x0080
.set zr, 0x0004

# Bind Weapon Swap L to X
lis r3, bindings@h
lhz r0, bindings@l+lIndex (r3)     # \
andi. r0, r0, ~l@l                 # | Unbind from L
ori r0, r0, x                      # | Bind to X
sth r0, bindings@l+lIndex (r3)     # /
lhz r0, bindings@l+bIndex (r3)     # \
andi. r0, r0, ~x@l                 # | Unbind X mirroring B
sth r0, bindings@l+bIndex (r3)     # /
blr

# Bind Weapon Swap L to A
lis r3, bindings@h
lhz r0, bindings@l+lIndex (r3)     # \
andi. r0, r0, ~l@l                 # | Unbind from L
ori r0, r0, a                      # | Bind to A
sth r0, bindings@l+lIndex (r3)     # /
lhz r0, bindings@l+yIndex (r3)     # \
andi. r0, r0, ~a@l                 # | Unbind A mirroring Y
sth r0, bindings@l+yIndex (r3)     # /
blr

# Bind Weapon Swap L to ZL
lis r3, bindings@h
lhz r0, bindings@l+lIndex (r3)     # \
andi. r0, r0, ~l@l                 # | Unbind from L
ori r0, r0, zl                     # | Bind to ZL
sth r0, bindings@l+lIndex (r3)     # /
blr

# Bind Weapon Swap R to X
lis r3, bindings@h
lhz r0, bindings@l+rIndex (r3)     # \
andi. r0, r0, ~r@l                 # | Unbind from R
ori r0, r0, x                      # | Bind to X
sth r0, bindings@l+rIndex (r3)     # /
lhz r0, bindings@l+bIndex (r3)     # \
andi. r0, r0, ~x@l                 # | Unbind X mirroring B
sth r0, bindings@l+bIndex (r3)     # /
blr

# Bind Weapon Swap R to A
lis r3, bindings@h
lhz r0, bindings@l+rIndex (r3)     # \
andi. r0, r0, ~r@l                 # | Unbind from R
ori r0, r0, a                      # | Bind to A
sth r0, bindings@l+rIndex (r3)     # /
lhz r0, bindings@l+yIndex (r3)     # \
andi. r0, r0, ~a@l                 # | Unbind A mirroring Y
sth r0, bindings@l+yIndex (r3)     # /
blr

# Bind Weapon Swap R to ZR
lis r3, bindings@h
lhz r0, bindings@l+rIndex (r3)     # \
andi. r0, r0, ~r@l                 # | Unbind from R
ori r0, r0, zr                     # | Bind to ZR
sth r0, bindings@l+rIndex (r3)     # /
blr

# Bind slide/dash to L
lis r3, bindings@h
lhz r0, bindings@l+lIndex (r3)     # \
andi. r0, r0, ~l@l                 # | Unbind weapon swap from L
sth r0, bindings@l+lIndex (r3)     # /
lhz r0, bindings@l+downIndex (r3)  # \
ori r0, r0, l                      # | Bind down to L
sth r0, bindings@l+downIndex (r3)  # /
lhz r0, bindings@l+bIndex (r3)     # \
ori r0, r0, l                      # | Bind B to L
sth r0, bindings@l+bIndex (r3)     # /
blr

# Bind slide/dash to R
lis r3, bindings@h
lhz r0, bindings@l+rIndex (r3)     # \
andi. r0, r0, ~r@l                 # | Unbind weapon swap from R
sth r0, bindings@l+rIndex (r3)     # /
lhz r0, bindings@l+downIndex (r3)  # \
ori r0, r0, r                      # | Bind down to R
sth r0, bindings@l+downIndex (r3)  # /
lhz r0, bindings@l+bIndex (r3)     # \
ori r0, r0, r                      # | Bind B to R
sth r0, bindings@l+bIndex (r3)     # /
blr

# Bind slide/dash to ZL
lis r3, bindings@h
lhz r0, bindings@l+downIndex (r3)  # \
ori r0, r0, zl                     # | Bind down to ZL
sth r0, bindings@l+downIndex (r3)  # /
lhz r0, bindings@l+bIndex (r3)     # \
ori r0, r0, zl                     # | Bind B to ZL
sth r0, bindings@l+bIndex (r3)     # /
blr

# Bind slide/dash to ZR
lis r3, bindings@h
lhz r0, bindings@l+downIndex (r3)  # \
ori r0, r0, zr                     # | Bind down to ZR
sth r0, bindings@l+downIndex (r3)  # /
lhz r0, bindings@l+bIndex (r3)     # \
ori r0, r0, zr                     # | Bind B to ZR
sth r0, bindings@l+bIndex (r3)     # /
blr
