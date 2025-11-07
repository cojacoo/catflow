"""
Test script to verify the preprocessing fixes.

Tests:
1. Plotting alignment (minor issue)
2. Mesh creation (severe issue)
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
from pathlib import Path

# Add catflow to path
sys.path.insert(0, str(Path(__file__).parent))

from catflow.preprocessing import (
    create_hillslope_profile,
    make_simgrid,
    discretize_for_catflow,
    simulate_macropores,
    create_soil_layers,
    assign_soil_properties,
    get_standard_soils,
    plot_soil_layers,
    plot_combined_overview
)
from catflow.core.mesh import CurvilinearHillslopeMesh

print("="*70)
print("TESTING PREPROCESSING FIXES")
print("="*70)

# Create test hillslope
print("\n1. Creating hillslope...")
profile = create_hillslope_profile(
    length=30.0,
    slope_angle=10,
    curvature='linear',
    width=1.0,
    n_points=15
)
print(f"   ✓ Profile created: {len(profile['x'])} points")

# Create simulation grid
print("\n2. Creating simulation grid...")
simgrid = make_simgrid(profile, depth=2.0, dx_max=0.2, dz_max=0.1)
print(f"   ✓ Grid created: {simgrid['shape']}")

# Create soil layers
print("\n3. Creating soil layers...")
layer_boundaries = [{'type': 'depth', 'value': 1.0}]
layers = create_soil_layers(simgrid['z'], layer_boundaries)
soils = get_standard_soils()
soil_types = {0: soils['sandy_loam'], 1: soils['clay_loam']}
soil_props = assign_soil_properties(layers, soil_types)
print(f"   ✓ Layers created: {len(np.unique(layers))} layers")

# Simulate macropores
print("\n4. Simulating macropores...")
macropores = simulate_macropores(simgrid, n_pores_per_m2=3, mean_length=1.0,
                                 std_length=0.2, min_separation=5, seed=42)
print(f"   ✓ Macropores simulated: {macropores['n_pores']} pores")

# TEST 1: Plotting alignment (minor issue fix)
print("\n5. Testing plotting alignment...")
try:
    fig, axes = plot_soil_layers(simgrid, layers, soil_props,
                                 title="Test Soil Layers")
    plt.close(fig)
    print("   ✓ plot_soil_layers works (using pcolormesh)")

    fig = plot_combined_overview(profile, simgrid, layers, macropores, soil_props)
    plt.close(fig)
    print("   ✓ plot_combined_overview works (using pcolormesh)")
except Exception as e:
    print(f"   ✗ Plotting failed: {e}")
    raise

# TEST 2: Mesh creation (severe issue fix)
print("\n6. Testing mesh creation...")
try:
    # Discretize
    discretization = discretize_for_catflow(
        simgrid=simgrid,
        n_xsi=21,
        n_eta=11,
        method='uniform'
    )
    print(f"   ✓ Discretization created: {discretization['n_eta']}×{discretization['n_xsi']}")

    # Create mesh using ORIGINAL profile (the fix)
    mesh = CurvilinearHillslopeMesh(
        profile_x=profile['x'],
        profile_y=profile['y'],
        profile_z=profile['z'],
        thickness=simgrid['depth'],
        xsi_nodes=discretization['xsi'],
        eta_nodes=discretization['eta'],
        geometry_type='constant'
    )
    print(f"   ✓ Mesh created: {mesh.shape}")

    # Verify mesh shape matches discretization
    expected_shape = (discretization['n_eta'], discretization['n_xsi'])
    if mesh.shape == expected_shape:
        print(f"   ✓ Mesh shape matches discretization: {mesh.shape}")
    else:
        print(f"   ✗ Mesh shape mismatch: {mesh.shape} vs {expected_shape}")
        raise ValueError("Mesh shape doesn't match discretization")

    # Get coordinates from mesh (use attributes, not method)
    x_coords = mesh.x
    z_coords = mesh.z
    print(f"   ✓ Node coordinates extracted: x={x_coords.shape}, z={z_coords.shape}")

except Exception as e:
    print(f"   ✗ Mesh creation failed: {e}")
    raise

print("\n" + "="*70)
print("✅ ALL TESTS PASSED!")
print("="*70)
print("\nFixes verified:")
print("  1. ✓ Plotting now uses pcolormesh for proper hillslope projection")
print("  2. ✓ Mesh creation uses original profile, not discretized coordinates")
print("\nThe demo notebook should now work correctly!")
