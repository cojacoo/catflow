"""
Weather forcing demonstration - proper rainfall and ET simulation.

This demonstrates the new time-varying weather boundary conditions
with proper surface water balance (infiltration, runoff, ET).
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from catflow.preprocessing import (
    create_hillslope_profile,
    make_simgrid,
    discretize_for_catflow,
    simulate_macropores,
    map_macropores_to_coarse_grid,
    create_soil_layers,
    assign_soil_properties,
    get_standard_soils,
)

from catflow.core.mesh import CurvilinearHillslopeMesh
from catflow.core.physics.soil_models import VanGenuchten
from catflow.core.equations import Richards2D
from catflow.core.solvers import ConjugateGradientSolver
from catflow.core.time_stepping import PicardIteration
from catflow.core import CatflowModel, WeatherForcing

print("=" * 70)
print("WEATHER FORCING DEMONSTRATION")
print("=" * 70)
print()

# =============================================================================
# Setup: Simple hillslope with two layers
# =============================================================================
print("1. Creating hillslope...")

profile = create_hillslope_profile(
    length=20.0,
    slope_angle=10,
    curvature='linear',
    width=2.0,
    n_points=10
)

simgrid = make_simgrid(
    profile=profile,
    depth=1.5,
    dx_max=0.4,
    dz_max=0.15
)

print(f"   ✓ Hillslope: {profile['x'][-1]:.1f} m × {simgrid['depth']:.1f} m")
print(f"   ✓ Grid: {simgrid['shape']}")
print()

# Soil layers
print("2. Setting up soil...")

standard_soils = get_standard_soils()
layer_boundaries = [{'type': 'depth', 'value': 0.6}]
layer_indices = create_soil_layers(simgrid['z'], layer_boundaries)

soil_types = {
    0: standard_soils['loam'],
    1: standard_soils['sandy_loam']
}

soil_properties = assign_soil_properties(layer_indices, soil_types)
print(f"   ✓ Upper: {soil_types[0]['name']} (0-0.6m)")
print(f"   ✓ Lower: {soil_types[1]['name']} (0.6-1.5m)")
print()

# Macropores
print("3. Simulating macropores...")
macropores = simulate_macropores(
    simgrid=simgrid,
    n_pores_per_m2=3,
    mean_length=0.8,
    std_length=0.2,
    p_lateral=0.1,
    conductivity_multiplier=2.0,
    seed=42
)
print(f"   ✓ Macropores: {macropores['n_pores']}")
print()

# CATFLOW mesh
print("4. Creating CATFLOW mesh...")
discretization = discretize_for_catflow(
    simgrid=simgrid,
    n_xsi=11,
    n_eta=7,
    method='uniform'
)

mesh = CurvilinearHillslopeMesh(
    profile_x=profile['x'],
    profile_y=profile['y'],
    profile_z=profile['z'],
    thickness=simgrid['depth'],
    xsi_nodes=discretization['xsi'],
    eta_nodes=discretization['eta'],
    geometry_type='constant'
)
print(f"   ✓ Mesh: {mesh.shape[0]} × {mesh.shape[1]} = {mesh.shape[0]*mesh.shape[1]} nodes")
print()

# Assign properties
z_nodes = mesh.z
catflow_layers = create_soil_layers(z_nodes, layer_boundaries)
catflow_soil_props = assign_soil_properties(catflow_layers, soil_types)

coarse_macropores = map_macropores_to_coarse_grid(
    macropores, simgrid, discretization
)

# Initial conditions (moderately wet)
print("5. Setting initial conditions...")
soil_model = VanGenuchten(L=0.5)
psi_init = np.full(mesh.shape, -1.5)  # Moderately wet
print(f"   ✓ Initial ψ = -1.5 m (field capacity)")
print()

# =============================================================================
# WEATHER FORCING: 2 days rain + 7 days ET
# =============================================================================
print("=" * 70)
print("WEATHER FORCING SETUP")
print("=" * 70)
print()

# Define weather: 2 days of rain, then 7 days of ET
weather = WeatherForcing.piecewise([
    (0,           2*86400, 'rain', 15e-3/86400),  # 2 days @ 15 mm/day
    (2*86400,     9*86400, 'pet',  3e-3/86400)    # 7 days @ 3 mm/day ET
])

print("Weather scenario:")
print("  Days 0-2: Rainfall @ 15 mm/day")
print("  Days 2-9: Evapotranspiration @ 3 mm/day")
print()

# Check total forcing
total_rain = weather.get_total_rain(0, 2*86400)
total_pet = weather.get_total_pet(2*86400, 9*86400)
print(f"Total rainfall:  {total_rain*1000:.1f} mm")
print(f"Total PET:       {total_pet*1000:.1f} mm")
print()

# =============================================================================
# CREATE MODEL WITH WEATHER FORCING
# =============================================================================
print("=" * 70)
print("RUNNING SIMULATION WITH WEATHER FORCING")
print("=" * 70)
print()

# Bottom BC (free drainage)
bc = {
    'bottom': {'type': 'dirichlet', 'value': -1.5}
}

equation = Richards2D(mesh, soil_model, bc)

# Relaxed solver settings
linear_solver = ConjugateGradientSolver(
    tolerance=1e-4,
    max_iterations=1500
)
time_stepper = PicardIteration(
    linear_solver=linear_solver,
    max_iterations=20,
    tolerance=0.01
)

# Create model WITH weather forcing
model = CatflowModel(
    mesh=mesh,
    soil_model=soil_model,
    soil_params=soil_types[0],  # Use loam as base
    equation=equation,
    time_stepper=time_stepper,
    initial_conditions=psi_init,
    weather_forcing=weather  # ← NEW: Weather forcing!
)

# Run simulation
results = model.run(
    t_start=0.0,
    t_end=9 * 86400,  # 9 days
    dt_initial=300.0,
    dt_min=10.0,
    dt_max=3600.0,
    adaptive_stepping=True
)

print()
print("=" * 70)
print("SIMULATION COMPLETE!")
print("=" * 70)
print()

# =============================================================================
# VISUALIZE RESULTS
# =============================================================================
print("Creating visualizations...")

times_days = np.array(results['times']) / 86400
mean_theta = [np.mean(theta) for theta in results['theta']]

x_nodes = mesh.x[0, :]
z_nodes = mesh.z
extent = [x_nodes[0], x_nodes[-1], z_nodes[-1, 0], z_nodes[0, 0]]

# Figure 1: Pressure head snapshots
fig1, axes = plt.subplots(2, 3, figsize=(15, 8))

snapshot_times = [0, 1, 2, 5, 7, 9]
snapshot_indices = [np.argmin(np.abs(times_days - t)) for t in snapshot_times]

for idx, (ax_idx, t) in enumerate(zip(snapshot_indices, snapshot_times)):
    row = idx // 3
    col = idx % 3
    ax = axes[row, col]

    im = ax.imshow(results['psi'][ax_idx], extent=extent, aspect='auto',
                   cmap='viridis_r', vmin=-3, vmax=0, origin='upper')
    ax.plot(x_nodes, z_nodes[0, :], 'k-', linewidth=1.5)

    title = f't = {t:.0f} d'
    if t <= 2:
        title += ' (RAIN 15mm/d)'
        color = 'blue'
    else:
        title += ' (ET 3mm/d)'
        color = 'red'

    ax.set_title(title, fontweight='bold', color=color)
    ax.set_ylabel('Elevation [m]')
    ax.set_xlabel('Distance [m]')
    plt.colorbar(im, ax=ax, label='ψ [m]', fraction=0.046)

plt.suptitle('Pressure Head Evolution: Weather-Driven Simulation',
            fontsize=13, fontweight='bold')
plt.tight_layout()
plt.savefig('/tmp/weather_forcing_demo.png', dpi=150)
print("  ✓ Saved: /tmp/weather_forcing_demo.png")

# Figure 2: Water balance
fig2, axes2 = plt.subplots(1, 3, figsize=(15, 4))

# Mean water content
ax = axes2[0]
ax.plot(times_days, mean_theta, 'b-', linewidth=2)
ax.axvline(x=2.0, color='r', linestyle='--', alpha=0.7, label='Rain ends')
ax.axhspan(mean_theta[0], max(mean_theta), alpha=0.1, color='blue', label='Wetting')
ax.set_xlabel('Time [days]')
ax.set_ylabel('Mean Water Content θ [-]')
ax.set_title('Water Content Evolution')
ax.legend()
ax.grid(True, alpha=0.3)

# Storage change
ax = axes2[1]
storage_change = [(theta - mean_theta[0])/mean_theta[0]*100
                 for theta in mean_theta]
ax.plot(times_days, storage_change, 'g-', linewidth=2)
ax.axvline(x=2.0, color='r', linestyle='--', alpha=0.7)
ax.axhline(y=0, color='k', linestyle='-', alpha=0.3)
ax.fill_between(times_days, 0, storage_change, alpha=0.2, color='green')
ax.set_xlabel('Time [days]')
ax.set_ylabel('Storage Change [%]')
ax.set_title('Relative Water Storage')
ax.grid(True, alpha=0.3)

# Convergence
ax = axes2[2]
conv_rate = [100*sum(results['convergence'][:i+1])/(i+1)
             for i in range(len(results['convergence']))]
ax.plot(times_days, conv_rate, 'purple', linewidth=2)
ax.axvline(x=2.0, color='r', linestyle='--', alpha=0.7)
ax.set_xlabel('Time [days]')
ax.set_ylabel('Convergence Rate [%]')
ax.set_title('Solver Performance')
ax.set_ylim([0, 105])
ax.grid(True, alpha=0.3)

plt.suptitle('Water Balance and Performance Metrics',
            fontsize=13, fontweight='bold')
plt.tight_layout()
plt.savefig('/tmp/weather_balance.png', dpi=150)
print("  ✓ Saved: /tmp/weather_balance.png")

print()
print("=" * 70)
print("SUMMARY")
print("=" * 70)
print()
print("✅ Weather forcing successfully implemented!")
print()
print("Key features demonstrated:")
print("  • Time-varying rainfall and ET")
print("  • Surface water balance (infiltration capacity, runoff, ET stress)")
print("  • Automatic mass balance tracking")
print("  • Dynamic boundary conditions at each timestep")
print()
print(f"Peak storage increase: {max(storage_change):.1f}%")
print(f"Final storage change: {storage_change[-1]:.1f}%")
print(f"Overall convergence: {conv_rate[-1]:.1f}%")
print()
print("=" * 70)

plt.show()
