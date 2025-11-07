"""
Rainfall simulation on hillslope with two-layer soil and macropores.

Simulates:
- 2 days of rain at 15 mm/day
- 7 days of drainage afterwards
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
from pathlib import Path

# Add catflow to path
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
from catflow.core.model import CatflowModel

print("=" * 70)
print("RAINFALL SIMULATION ON TWO-LAYER HILLSLOPE")
print("=" * 70)
print()

# =============================================================================
# STEP 1: Create hillslope geometry
# =============================================================================
print("1. Creating hillslope geometry...")

profile = create_hillslope_profile(
    length=50.0,
    slope_angle=12,
    curvature='complex',
    width=2.0,
    n_points=30
)

simgrid = make_simgrid(
    profile=profile,
    depth=3.0,
    dx_max=0.1,
    dz_max=0.05
)

print(f"   ✓ Hillslope: {profile['x'][-1]:.1f} m long, {simgrid['depth']:.1f} m deep")
print(f"   ✓ Fine grid: {simgrid['shape']}")
print()

# =============================================================================
# STEP 2: Define two-layer soil profile
# =============================================================================
print("2. Creating two-layer soil profile...")

standard_soils = get_standard_soils()
layer_boundaries = [{'type': 'depth', 'value': 1.0}]
layer_indices = create_soil_layers(simgrid['z'], layer_boundaries)

soil_types = {
    0: standard_soils['sandy_loam'],  # 0-1m: high K
    1: standard_soils['clay_loam']    # 1-3m: low K
}

soil_properties = assign_soil_properties(layer_indices, soil_types)

print(f"   ✓ Upper layer (0-1.0 m): {soil_types[0]['name']}")
print(f"      Ks = {soil_types[0]['Ks']:.2e} m/s")
print(f"   ✓ Lower layer (1.0-3.0 m): {soil_types[1]['name']}")
print(f"      Ks = {soil_types[1]['Ks']:.2e} m/s")
print()

# =============================================================================
# STEP 3: Simulate macropores
# =============================================================================
print("3. Simulating macropores...")

macropores = simulate_macropores(
    simgrid=simgrid,
    n_pores_per_m2=5,
    mean_length=1.5,
    std_length=0.4,
    p_lateral=0.15,
    conductivity_multiplier=3.0,
    seed=42
)

print(f"   ✓ Macropores: {macropores['n_pores']} pores")
print()

# =============================================================================
# STEP 4: Create CATFLOW mesh
# =============================================================================
print("4. Creating CATFLOW mesh...")

discretization = discretize_for_catflow(
    simgrid=simgrid,
    n_xsi=51,
    n_eta=31,
    method='adaptive'
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

# =============================================================================
# STEP 5: Assign properties to CATFLOW grid
# =============================================================================
print("5. Assigning properties to CATFLOW grid...")

z_nodes = mesh.z
catflow_layers = create_soil_layers(z_nodes, layer_boundaries)
catflow_soil_props = assign_soil_properties(catflow_layers, soil_types)

# Map macropores
coarse_macropores = map_macropores_to_coarse_grid(
    macropores, simgrid, discretization
)

# Modify conductivity with macropores
Ks_with_macropores = catflow_soil_props['Ks'] * coarse_macropores

print(f"   ✓ Properties assigned")
print(f"   ✓ Macroporous cells: {np.sum(coarse_macropores > 1.0)}")
print()

# =============================================================================
# STEP 6: Initial conditions
# =============================================================================
print("6. Setting initial conditions...")

soil_model = VanGenuchten(L=0.5)
psi_init = np.zeros(mesh.shape)

# Moderately dry initial conditions
for layer_idx in [0, 1]:
    mask = catflow_layers == layer_idx
    params = soil_types[layer_idx]

    # Start with moderately dry soil (theta = 0.15)
    target_theta = 0.15

    Se = (target_theta - params['theta_r']) / (params['theta_s'] - params['theta_r'])
    Se = np.clip(Se, 0.01, 0.99)

    m = 1 - 1/params['n']
    psi = -(1/params['alpha']) * (Se**(-1/m) - 1)**(1/params['n'])

    psi_init[mask] = psi

print(f"   ✓ Initial conditions: θ ≈ 0.15 (moderately dry)")
print(f"   ✓ Pressure head range: {psi_init.min():.2f} to {psi_init.max():.2f} m")
print()

# =============================================================================
# STEP 7: Run RAINFALL simulation (2 days @ 15 mm/day)
# =============================================================================
print("=" * 70)
print("PHASE 1: RAINFALL (2 days @ 15 mm/day)")
print("=" * 70)
print()

# Convert 15 mm/day to m/s
rainfall_rate = (15e-3) / (24 * 3600)  # m/s
print(f"Rainfall rate: {rainfall_rate:.2e} m/s = 15 mm/day")
print()

# Boundary conditions for rainfall
bc_rainfall = {
    'top': {
        'type': 'neumann',
        'value': -rainfall_rate  # Negative = infiltration
    },
    'bottom': {
        'type': 'dirichlet',
        'value': -2.5  # Free drainage
    }
}

# Create model for rainfall phase
base_soil_params = soil_types[0].copy()
equation_rain = Richards2D(mesh, soil_model, bc_rainfall)

linear_solver = ConjugateGradientSolver(tolerance=1e-6, max_iterations=1000)
time_stepper = PicardIteration(
    linear_solver=linear_solver,
    max_iterations=15,
    tolerance=0.001
)

model = CatflowModel(
    mesh=mesh,
    soil_model=soil_model,
    soil_params=base_soil_params,
    equation=equation_rain,
    time_stepper=time_stepper,
    initial_conditions=psi_init
)

# Run rainfall simulation
results_rain = model.run(
    t_start=0.0,
    t_end=2 * 24 * 3600,  # 2 days
    dt_initial=60.0,
    dt_min=1.0,
    dt_max=3600.0,
    adaptive_stepping=True
)

print()
print("Rainfall phase complete!")
print(f"  Timesteps: {model.timestep_count}")
print(f"  Outputs: {len(results_rain['times'])}")
print(f"  Convergence: {sum(results_rain['convergence'])}/{len(results_rain['convergence'])} steps converged")
print()

# =============================================================================
# STEP 8: Run DRAINAGE simulation (7 days)
# =============================================================================
print("=" * 70)
print("PHASE 2: DRAINAGE (7 days, no rain)")
print("=" * 70)
print()

# Boundary conditions for drainage
bc_drainage = {
    'top': {
        'type': 'neumann',
        'value': 0.0  # No flux
    },
    'bottom': {
        'type': 'dirichlet',
        'value': -2.5  # Free drainage
    }
}

# Create new model for drainage phase with final state from rainfall
equation_drain = Richards2D(mesh, soil_model, bc_drainage)

model_drain = CatflowModel(
    mesh=mesh,
    soil_model=soil_model,
    soil_params=base_soil_params,
    equation=equation_drain,
    time_stepper=time_stepper,
    initial_conditions=results_rain['psi'][-1]  # Start from end of rainfall
)

# Run drainage simulation
results_drain = model_drain.run(
    t_start=2 * 24 * 3600,  # Start where rainfall ended
    t_end=9 * 24 * 3600,     # 2 days rain + 7 days drainage = 9 days total
    dt_initial=60.0,
    dt_min=1.0,
    dt_max=3600.0,
    adaptive_stepping=True
)

print()
print("Drainage phase complete!")
print(f"  Timesteps: {model_drain.timestep_count}")
print(f"  Outputs: {len(results_drain['times'])}")
print(f"  Convergence: {sum(results_drain['convergence'])}/{len(results_drain['convergence'])} steps converged")
print()

# =============================================================================
# STEP 9: Combine and analyze results
# =============================================================================
print("=" * 70)
print("COMBINING RESULTS")
print("=" * 70)
print()

# Combine results from both phases
all_times = results_rain['times'] + results_drain['times']
all_psi = results_rain['psi'] + results_drain['psi']
all_theta = results_rain['theta'] + results_drain['theta']
all_convergence = results_rain['convergence'] + results_drain['convergence']

times_days = np.array(all_times) / (24 * 3600)  # Convert to days

# Calculate mean water content
mean_theta = [np.mean(theta) for theta in all_theta]

print(f"Total simulation: 9 days")
print(f"  Rain phase: 0-2 days ({len(results_rain['times'])} outputs)")
print(f"  Drain phase: 2-9 days ({len(results_drain['times'])} outputs)")
print(f"  Total outputs: {len(all_times)}")
print(f"  Total convergence: {sum(all_convergence)}/{len(all_convergence)} steps")
print()

# =============================================================================
# STEP 10: Visualize results
# =============================================================================
print("Creating visualizations...")

x_nodes = mesh.x[0, :]
z_nodes = mesh.z
extent = [x_nodes[0], x_nodes[-1], z_nodes[-1, 0], z_nodes[0, 0]]

# Figure 1: Snapshots at key times
fig1, axes = plt.subplots(3, 4, figsize=(18, 12))

# Times to plot: 0, 0.5, 1, 2, 3, 5, 7, 9 days
snapshot_times = [0, 0.5, 1.0, 2.0, 3.0, 5.0, 7.0, 9.0]
snapshot_indices = [np.argmin(np.abs(times_days - t)) for t in snapshot_times]

for i, (idx, t) in enumerate(zip(snapshot_indices, snapshot_times)):
    row = i // 4
    col = i % 4

    # Pressure head
    ax = axes[row, col]
    im = ax.imshow(all_psi[idx], extent=extent, aspect='auto',
                   cmap='viridis_r', vmin=-3, vmax=0, origin='upper')
    ax.plot(x_nodes, z_nodes[0, :], 'k-', linewidth=1)

    # Mark rainfall period
    if t <= 2.0:
        ax.set_title(f't = {t:.1f} d (RAIN)', fontweight='bold', color='blue')
    else:
        ax.set_title(f't = {t:.1f} d (drain)', fontweight='bold')

    ax.set_ylabel('Elevation [m]')
    ax.set_xlabel('Distance [m]')
    plt.colorbar(im, ax=ax, label='ψ [m]', fraction=0.046)

plt.suptitle('Pressure Head Evolution: 2 Days Rain (15 mm/day) + 7 Days Drainage',
            fontsize=14, fontweight='bold')
plt.tight_layout()
plt.savefig('/tmp/rainfall_snapshots.png', dpi=150)
print("  ✓ Saved: /tmp/rainfall_snapshots.png")

# Figure 2: Water content evolution
fig2, axes = plt.subplots(2, 2, figsize=(14, 10))

# Mean water content over time
ax = axes[0, 0]
ax.plot(times_days, mean_theta, 'b-', linewidth=2)
ax.axvline(x=2.0, color='r', linestyle='--', alpha=0.7, label='Rain ends')
ax.set_xlabel('Time [days]')
ax.set_ylabel('Mean Water Content θ [-]')
ax.set_title('Mean Water Content Evolution')
ax.grid(True, alpha=0.3)
ax.legend()

# Water storage change
ax = axes[0, 1]
storage_change = (np.array(mean_theta) - mean_theta[0]) / mean_theta[0] * 100
ax.plot(times_days, storage_change, 'g-', linewidth=2)
ax.axvline(x=2.0, color='r', linestyle='--', alpha=0.7, label='Rain ends')
ax.axhline(y=0, color='k', linestyle='-', alpha=0.3)
ax.set_xlabel('Time [days]')
ax.set_ylabel('Storage Change [%]')
ax.set_title('Relative Water Storage Change')
ax.grid(True, alpha=0.3)
ax.legend()

# Water content snapshots
snapshot_times_2 = [0, 1, 2, 5, 9]
snapshot_indices_2 = [np.argmin(np.abs(times_days - t)) for t in snapshot_times_2]

ax = axes[1, 0]
for idx, t in zip(snapshot_indices_2, snapshot_times_2):
    label = f'{t:.1f} d (rain)' if t <= 2.0 else f'{t:.1f} d (drain)'
    ax.plot(all_theta[idx].flatten(), 'o-', alpha=0.6, markersize=2, label=label)
ax.set_xlabel('Grid Cell Index')
ax.set_ylabel('Water Content θ [-]')
ax.set_title('Spatial Distribution at Different Times')
ax.legend()
ax.grid(True, alpha=0.3)

# Convergence tracking
ax = axes[1, 1]
convergence_pct = [100 * sum(all_convergence[:i+1]) / (i+1)
                   for i in range(len(all_convergence))]
ax.plot(times_days, convergence_pct, 'purple', linewidth=2)
ax.axvline(x=2.0, color='r', linestyle='--', alpha=0.7, label='Rain ends')
ax.set_xlabel('Time [days]')
ax.set_ylabel('Convergence Rate [%]')
ax.set_title('Cumulative Convergence Success Rate')
ax.set_ylim([0, 105])
ax.grid(True, alpha=0.3)
ax.legend()

plt.suptitle('Water Balance Analysis: Rainfall + Drainage',
            fontsize=14, fontweight='bold')
plt.tight_layout()
plt.savefig('/tmp/rainfall_analysis.png', dpi=150)
print("  ✓ Saved: /tmp/rainfall_analysis.png")

# =============================================================================
# SUMMARY
# =============================================================================
print()
print("=" * 70)
print("SIMULATION SUMMARY")
print("=" * 70)
print()
print("Scenario:")
print("  • 2 days rainfall @ 15 mm/day")
print("  • 7 days drainage (no rain)")
print("  • Two-layer soil: sandy loam (0-1m) / clay loam (1-3m)")
print(f"  • Macropores: {macropores['n_pores']} preferential flow paths")
print()
print("Results:")
print(f"  • Initial mean θ: {mean_theta[0]:.4f}")
print(f"  • Peak mean θ (end of rain): {max(mean_theta):.4f}")
print(f"  • Final mean θ (after drainage): {mean_theta[-1]:.4f}")
print(f"  • Total water gained: {storage_change[snapshot_indices[3]]:.2f}% (at end of rain)")
print(f"  • Water remaining: {storage_change[-1]:.2f}% (after 7 days drainage)")
print()
print(f"  • Total timesteps: {model.timestep_count + model_drain.timestep_count}")
print(f"  • Total convergence rate: {100*sum(all_convergence)/len(all_convergence):.1f}%")
print()
print("=" * 70)

plt.show()
