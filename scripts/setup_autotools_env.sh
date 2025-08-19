#!/bin/bash
#
# FreeSWITCH AutoTools Environment Setup Script
# This script sets up the necessary autotools environment for building FreeSWITCH
#

# Exit on error
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}FreeSWITCH AutoTools Environment Setup${NC}"
echo -e "${BLUE}==========================================${NC}"

# Verify we're in the right directory
if [ ! -f "$PROJECT_ROOT/bootstrap.sh" ]; then
    echo -e "${RED}Error: This script must be run from the FreeSWITCH project directory${NC}"
    exit 1
fi

# Create m4 directory if it doesn't exist
echo -e "${YELLOW}Setting up m4 directory...${NC}"
if [ ! -d "$PROJECT_ROOT/m4" ]; then
    mkdir -p "$PROJECT_ROOT/m4"
    echo -e "${GREEN}Created m4 directory${NC}"
else
    echo -e "${GREEN}m4 directory already exists${NC}"
fi

# Find libtool macros from the system
echo -e "${YELLOW}Checking for libtool macros...${NC}"
ACLOCAL_DIR=$(aclocal --print-ac-dir)
if [ -z "$ACLOCAL_DIR" ]; then
    echo -e "${RED}Error: Could not determine aclocal directory${NC}"
    exit 1
fi
echo -e "${GREEN}Found aclocal directory: $ACLOCAL_DIR${NC}"

# Copy libtool macros to the m4 directory
echo -e "${YELLOW}Copying libtool macros to m4 directory...${NC}"
LIBTOOL_MACROS=(
    "libtool.m4"
    "ltargz.m4"
    "ltdl.m4"
    "ltoptions.m4"
    "ltsugar.m4"
    "ltversion.m4"
    "lt~obsolete.m4"
)

for macro in "${LIBTOOL_MACROS[@]}"; do
    if [ -f "$ACLOCAL_DIR/$macro" ]; then
        cp -f "$ACLOCAL_DIR/$macro" "$PROJECT_ROOT/m4/"
        echo -e "${GREEN}Copied $macro${NC}"
    else
        echo -e "${YELLOW}Warning: $macro not found in $ACLOCAL_DIR${NC}"
    fi
done

# Add AC_CONFIG_MACRO_DIRS to configure.ac if not already there
echo -e "${YELLOW}Checking configure.ac for macro directory configuration...${NC}"
if ! grep -q "AC_CONFIG_MACRO_DIRS" "$PROJECT_ROOT/configure.ac"; then
    # Add after AC_CONFIG_AUX_DIR line
    sed -i '/AC_CONFIG_AUX_DIR/a AC_CONFIG_MACRO_DIRS([m4])' "$PROJECT_ROOT/configure.ac"
    echo -e "${GREEN}Added AC_CONFIG_MACRO_DIRS([m4]) to configure.ac${NC}"
else
    echo -e "${GREEN}AC_CONFIG_MACRO_DIRS already configured${NC}"
fi

# Add ACLOCAL_AMFLAGS to Makefile.am if not already there
echo -e "${YELLOW}Checking Makefile.am for aclocal flags...${NC}"
if ! grep -q "ACLOCAL_AMFLAGS" "$PROJECT_ROOT/Makefile.am"; then
    # Add at the beginning of the file
    sed -i '1s/^/ACLOCAL_AMFLAGS = -I m4\n\n/' "$PROJECT_ROOT/Makefile.am"
    echo -e "${GREEN}Added ACLOCAL_AMFLAGS = -I m4 to Makefile.am${NC}"
else
    echo -e "${GREEN}ACLOCAL_AMFLAGS already configured${NC}"
fi

# Ensure build/config directory exists and check for required macro files
echo -e "${YELLOW}Checking build/config directory...${NC}"
if [ ! -d "$PROJECT_ROOT/build/config" ]; then
    mkdir -p "$PROJECT_ROOT/build/config"
    echo -e "${GREEN}Created build/config directory${NC}"
else
    echo -e "${GREEN}build/config directory already exists${NC}"
fi

# Check for required macros in acinclude.m4
echo -e "${YELLOW}Checking for macros referenced in acinclude.m4...${NC}"
MISSING_MACROS=0
while IFS= read -r line; do
    if [[ $line =~ m4_include\(\[([^]]+)\]\) ]]; then
        FILE="${BASH_REMATCH[1]}"
        if [ ! -f "$PROJECT_ROOT/$FILE" ]; then
            echo -e "${RED}Missing file: $FILE${NC}"
            MISSING_MACROS=1
        else
            echo -e "${GREEN}Found: $FILE${NC}"
        fi
    fi
done < <(grep "m4_include" "$PROJECT_ROOT/acinclude.m4")

if [ $MISSING_MACROS -eq 1 ]; then
    echo -e "${YELLOW}Warning: Some macro files referenced in acinclude.m4 are missing${NC}"
    echo -e "${YELLOW}You may need to provide these files manually or adjust acinclude.m4${NC}"
fi

echo -e "${BLUE}==========================================${NC}"
echo -e "${GREEN}Environment setup complete!${NC}"
echo -e "${BLUE}==========================================${NC}"
echo
echo -e "Next steps:"
echo -e "1. Run ${YELLOW}./bootstrap.sh -j -v${NC}"
echo -e "2. Run ${YELLOW}./configure${NC} with your desired options"
echo -e "3. Run ${YELLOW}make${NC} to build FreeSWITCH"
echo

exit 0