#!/bin/sh
# Apply SPE fixes to clib4 for e500v2 (A1222 Plus).
#
# clib4 upstream doesn't fully support SPE: the e500v2 has no classic
# FPU registers, no altivec, and no lswx/stswx string instructions.
# This script patches the downloaded clib4 source to handle these
# limitations.
set -e

CLIB4_DIR="$1"
if [ -z "$CLIB4_DIR" ] || [ ! -f "$CLIB4_DIR/GNUmakefile.os4" ]; then
    echo "Usage: $0 <clib4-directory>" >&2
    exit 1
fi

echo "Patching clib4 for SPE (e500v2)..."

cd "$CLIB4_DIR"

# 1. Add -D_SOFT_FLOAT to SPE CFLAGS and AFLAGS so .S files skip FPU
#    register saves/restores via #ifndef _SOFT_FLOAT guards
sed -i 's/-D__SPE__ -msoft-float -mspe/-D__SPE__ -D_SOFT_FLOAT -msoft-float -mspe/' GNUmakefile.os4
sed -i 's/AFLAGS := $(AFLAGS) -mvrsave -D__SPE__ -mspe/AFLAGS := $(AFLAGS) -mvrsave -D__SPE__ -D_SOFT_FLOAT -mspe/' GNUmakefile.os4

# 2. Make COMPILE_ASM pass $(AFLAGS) so assembly files get SPE/SOFT_FLOAT flags
sed -i '/^define COMPILE_ASM/,/^endef/ s/\$(VERBOSE)\$(CC) -o/\$(VERBOSE)\$(CC) \$(AFLAGS) -o/' GNUmakefile.os4

# 3. Fix libc.gmk: filter out incompatible CPU objects for SPE and
#    replace altivec setjmp with SPE variants instead of appending
cat > /tmp/clib4_spe_libc.py << 'PYEOF'
import sys
content = open(sys.argv[1]).read()

# Replace the SPE block in libc.gmk
old = """ifdef SPE
    $(info Adding SPE objects)
    C_STRING := $(C_STRING) \\"""

new = """ifdef SPE
    $(info Adding SPE objects)
    # Remove 4xx, altivec, and bcopy asm (incompatible ISA on e500v2)
    C_STRING := $(filter-out cpu/4xx/% cpu/altivec/% cpu/generic/bcopy.o,$(C_STRING)) \\"""

content = content.replace(old, new)

old2 = """    C_SETJMP := $(C_SETJMP) \\"""
new2 = """    # Remove altivec setjmp, add SPE (e500) variants
    C_SETJMP := $(filter-out cpu/altivec/%,$(C_SETJMP)) \\"""

content = content.replace(old2, new2)

open(sys.argv[1], 'w').write(content)
PYEOF
python3 /tmp/clib4_spe_libc.py libc.gmk

# 4. Guard altivec/4xx CPU dispatcher in clib4.c with #ifndef __SPE__
#    so incompatible symbols aren't referenced
cat > /tmp/clib4_spe_dispatch.py << 'PYEOF'
import sys
content = open(sys.argv[1]).read()

# Wrap the 4xx and altivec cases with #ifndef __SPE__
old = """            case CPUFAMILY_4XX:"""
new = """#ifndef __SPE__
            case CPUFAMILY_4XX:"""
content = content.replace(old, new, 1)

# Find the closing of the default/altivec block and add #else/#endif
old2 = """                } else {
                    D(bug("(libOpen) Using default family functions\\n"));
                }
        }"""
new2 = """                } else {
                    D(bug("(libOpen) Using default family functions\\n"));
                }
#else
            default:
                D(bug("(libOpen) Using default family functions\\n"));
#endif
        }"""
content = content.replace(old2, new2, 1)

open(sys.argv[1], 'w').write(content)
PYEOF
python3 /tmp/clib4_spe_dispatch.py library/shared_library/clib4.c

# 5. res_msend_rc.c fallthrough fix is now applied for all GCC 7 builds
#    in the main makefile, so we don't need to do it here.

echo "clib4 SPE patches applied."
