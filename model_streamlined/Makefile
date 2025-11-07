# Makefile for CATFLOW Streamlined
#
# Usage:
#   make          # Build everything
#   make test     # Build and run test
#   make clean    # Remove compiled files
#
# Requirements:
#   - gfortran (or ifort - change FC variable below)

FC = gfortran
FFLAGS = -O2 -I modules/ -J modules/
DEBUGFLAGS = -g -fcheck=all -Wall -fbounds-check

# Module objects (order matters - dependencies!)
MODULES = modules/constants_module.o \
          modules/state_data_module.o \
          modules/mesh_geometry_module.o \
          modules/soil_hydraulics_module.o \
          modules/boundary_conditions_module.o \
          modules/time_module.o

# Module files (for cleanup)
MODFILES = modules/*.mod *.mod

# Executables
TESTS = test_modules test_mesh_module test_soil_module

.PHONY: all test clean debug help

all: $(TESTS)

# Default target: build all tests
test: $(TESTS)
	@echo "========================================"
	@echo "Running tests..."
	@echo "========================================"
	./test_modules
	@echo "========================================"
	@echo "All tests passed!"
	@echo "========================================"

# Debug build
debug: FFLAGS = $(DEBUGFLAGS) -I modules/ -J modules/
debug: clean all

# Module compilation rules
modules/constants_module.o: modules/constants_module.f90
	@echo "Compiling constants_module..."
	$(FC) $(FFLAGS) -c $< -o $@

modules/state_data_module.o: modules/state_data_module.f90 modules/constants_module.o
	@echo "Compiling state_data_module..."
	$(FC) $(FFLAGS) -c $< -o $@

modules/mesh_geometry_module.o: modules/mesh_geometry_module.f90 modules/constants_module.o
	@echo "Compiling mesh_geometry_module..."
	$(FC) $(FFLAGS) -c $< -o $@

modules/soil_hydraulics_module.o: modules/soil_hydraulics_module.f90 modules/constants_module.o
	@echo "Compiling soil_hydraulics_module..."
	$(FC) $(FFLAGS) -c $< -o $@

modules/boundary_conditions_module.o: modules/boundary_conditions_module.f90 modules/constants_module.o
	@echo "Compiling boundary_conditions_module..."
	$(FC) $(FFLAGS) -c $< -o $@

modules/time_module.o: modules/time_module.f90 modules/constants_module.o
	@echo "Compiling time_module..."
	$(FC) $(FFLAGS) -c $< -o $@

# Test programs
test_modules: test_modules.f90 $(MODULES)
	@echo "Linking test_modules..."
	$(FC) $(FFLAGS) -o $@ $< $(MODULES)

test_mesh_module: test_mesh_module.f90 $(MODULES)
	@echo "Linking test_mesh_module..."
	$(FC) $(FFLAGS) -o $@ $< $(MODULES)

test_soil_module: test_soil_module.f90 $(MODULES)
	@echo "Linking test_soil_module..."
	$(FC) $(FFLAGS) -o $@ $< $(MODULES)

# Cleanup
clean:
	@echo "Cleaning up..."
	rm -f *.o modules/*.o $(MODFILES) $(TESTS)
	@echo "Clean complete."

# Help
help:
	@echo "CATFLOW Streamlined - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make          - Build all executables"
	@echo "  make test     - Build and run tests"
	@echo "  make debug    - Build with debugging flags"
	@echo "  make clean    - Remove all compiled files"
	@echo "  make help     - Show this message"
	@echo ""
	@echo "Modules (in dependency order):"
	@echo "  1. constants_module"
	@echo "  2. state_data_module"
	@echo "  3. mesh_geometry_module"
	@echo "  4. soil_hydraulics_module"
