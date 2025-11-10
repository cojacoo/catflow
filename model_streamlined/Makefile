#===============================================================================
# Makefile for CATFLOW Streamlined
#
# PURPOSE:
#   Compile all modules and link the CATFLOW executable
#
# USAGE:
#   make           - Build everything
#   make clean     - Remove object files and modules
#   make cleanall  - Remove everything including executable
#   make modules   - Build only modules
#   make physics   - Build only physics modules
#   make main      - Build only main program
#
# DEPENDENCIES:
#   Fortran 90/95 compiler (gfortran, ifort, etc.)
#
# AUTHOR: CATFLOW Streamlined
# DATE: 2025-11-10
#===============================================================================

# Compiler and flags
FC = gfortran
FFLAGS = -O2 -Wall -fcheck=bounds -fbacktrace -ffree-form -ffree-line-length-none
LDFLAGS =

# Directories
SRCDIR = .
PHYSDIR = physics
OBJDIR = obj
MODDIR = mod
BINDIR = bin

# Executable name
EXEC = $(BINDIR)/catflow

# Create directories if they don't exist
$(shell mkdir -p $(OBJDIR) $(MODDIR) $(BINDIR))

#===============================================================================
# MODULE FILES (in dependency order)
#===============================================================================

# Level 1: No dependencies
MOD_L1 = constants_module.f90

# Level 2: Depend on constants
MOD_L2 = state_data_module.f90 \
         state_variables_module.f90 \
         mesh_geometry_module.f90 \
         soil_properties_module.f90 \
         boundary_conditions_module.f90 \
         time_module.f90 \
         additional_modules.f90

# Level 3: Physics modules (depend on L1 and L2)
PHYS_MODS = $(PHYSDIR)/kinnen.f90 \
            $(PHYSDIR)/ksenken.f90 \
            $(PHYSDIR)/koeffrb.f90 \
            $(PHYSDIR)/dcg.f90 \
            $(PHYSDIR)/hg_opera.f90 \
            $(PHYSDIR)/addsteps.f90 \
            $(PHYSDIR)/steps.f90 \
            $(PHYSDIR)/bodtab.f90 \
            $(PHYSDIR)/balanc.f90 \
            $(PHYSDIR)/tcalw.f90 \
            $(PHYSDIR)/rd_wr.f90 \
            $(PHYSDIR)/hg.f90

# Main program
MAIN = catflow_main.f90

# All source files
ALL_MODS = $(MOD_L1) $(MOD_L2) $(PHYS_MODS)
ALL_SRCS = $(ALL_MODS) $(MAIN)

# Object files
OBJS_L1 = $(patsubst %.f90,$(OBJDIR)/%.o,$(notdir $(MOD_L1)))
OBJS_L2 = $(patsubst %.f90,$(OBJDIR)/%.o,$(notdir $(MOD_L2)))
OBJS_PHYS = $(patsubst $(PHYSDIR)/%.f90,$(OBJDIR)/%.o,$(PHYS_MODS))
OBJ_MAIN = $(OBJDIR)/catflow_main.o

ALL_OBJS = $(OBJS_L1) $(OBJS_L2) $(OBJS_PHYS) $(OBJ_MAIN)

#===============================================================================
# TARGETS
#===============================================================================

.PHONY: all clean cleanall modules physics main help

# Default target
all: $(EXEC)

# Link executable
$(EXEC): $(ALL_OBJS)
	@echo "Linking executable: $@"
	$(FC) $(FFLAGS) -J$(MODDIR) -o $@ $(ALL_OBJS) $(LDFLAGS)
	@echo "Build complete: $@"
	@echo ""

# Build modules only
modules: $(OBJS_L1) $(OBJS_L2)
	@echo "Modules built successfully"

# Build physics only
physics: modules $(OBJS_PHYS)
	@echo "Physics modules built successfully"

# Build main only
main: modules physics $(OBJ_MAIN)
	@echo "Main program compiled"

#===============================================================================
# COMPILATION RULES
#===============================================================================

# Level 1 modules (no dependencies)
$(OBJDIR)/constants_module.o: constants_module.f90
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

# Level 2 modules (depend on constants)
$(OBJDIR)/state_data_module.o: state_data_module.f90 $(OBJDIR)/constants_module.o
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/state_variables_module.o: state_variables_module.f90
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/mesh_geometry_module.o: mesh_geometry_module.f90
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/soil_properties_module.o: soil_properties_module.f90 $(OBJDIR)/constants_module.o
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/boundary_conditions_module.o: boundary_conditions_module.f90
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/time_module.o: time_module.f90 $(OBJDIR)/constants_module.o
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/additional_modules.o: additional_modules.f90 $(OBJDIR)/constants_module.o
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

# Physics modules (compile in dependency order)
$(OBJDIR)/dcg.o: $(PHYSDIR)/dcg.f90 $(OBJS_L1) $(OBJS_L2)
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/hg_opera.o: $(PHYSDIR)/hg_opera.f90 $(OBJS_L1) $(OBJS_L2)
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/bodtab.o: $(PHYSDIR)/bodtab.f90 $(OBJS_L1) $(OBJS_L2)
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/tcalw.o: $(PHYSDIR)/tcalw.f90 $(OBJS_L1) $(OBJS_L2)
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/rd_wr.o: $(PHYSDIR)/rd_wr.f90 $(OBJS_L1) $(OBJS_L2)
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/balanc.o: $(PHYSDIR)/balanc.f90 $(OBJS_L1) $(OBJS_L2)
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/kinnen.o: $(PHYSDIR)/kinnen.f90 $(OBJS_L1) $(OBJS_L2)
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/ksenken.o: $(PHYSDIR)/ksenken.f90 $(OBJS_L1) $(OBJS_L2)
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/koeffrb.o: $(PHYSDIR)/koeffrb.f90 $(OBJS_L1) $(OBJS_L2)
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/addsteps.o: $(PHYSDIR)/addsteps.f90 $(OBJS_L1) $(OBJS_L2)
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/steps.o: $(PHYSDIR)/steps.f90 $(OBJS_L1) $(OBJS_L2) $(OBJDIR)/addsteps.o $(OBJDIR)/dcg.o
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

$(OBJDIR)/hg.o: $(PHYSDIR)/hg.f90 $(OBJS_L1) $(OBJS_L2) $(OBJDIR)/steps.o
	@echo "Compiling $<"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

# Main program (depends on everything)
$(OBJDIR)/catflow_main.o: catflow_main.f90 $(OBJS_L1) $(OBJS_L2) $(OBJS_PHYS)
	@echo "Compiling main program"
	$(FC) $(FFLAGS) -J$(MODDIR) -c $< -o $@

#===============================================================================
# UTILITY TARGETS
#===============================================================================

# Clean object files and modules
clean:
	@echo "Cleaning object files and modules..."
	rm -rf $(OBJDIR)/*.o $(MODDIR)/*.mod
	@echo "Clean complete"

# Clean everything including executable
cleanall: clean
	@echo "Removing executable..."
	rm -f $(EXEC)
	@echo "Clean all complete"

# Help
help:
	@echo "CATFLOW Streamlined Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  make           - Build everything"
	@echo "  make modules   - Build only foundational modules"
	@echo "  make physics   - Build only physics modules"
	@echo "  make main      - Build only main program"
	@echo "  make clean     - Remove object files and modules"
	@echo "  make cleanall  - Remove everything including executable"
	@echo "  make help      - Show this help message"
	@echo ""
	@echo "Compiler: $(FC)"
	@echo "Flags: $(FFLAGS)"
	@echo ""

# Show what would be built
list:
	@echo "Level 1 modules: $(MOD_L1)"
	@echo "Level 2 modules: $(MOD_L2)"
	@echo "Physics modules: $(PHYS_MODS)"
	@echo "Main program: $(MAIN)"
	@echo ""
	@echo "Object files: $(ALL_OBJS)"
	@echo ""
