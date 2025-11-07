"""
Rainfall simulation on hillslope - IMPROVED VERSION

Better numerical settings for stability:
- Wetter initial conditions
- Relaxed tolerances
- Smaller mesh for faster computation
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
from catflow.core.model import CatflowModel

print("=" * 70)
print("RAINFALL SIMULATION - IMPROVED VERSION")
print("=" * 70)
print()

# Smaller, faster mesh
print("1. Creating hillslope geometry...")
profile = create_hillslope_profile(
    length=30.0,  # Shorter hillslope
    slope_angle=10,
    curvature='linear',  # Simpler geometry
    width=2.0,
    n_points=15
)

simgrid = make_simgrid(
    profile=profile,
    depth=2.0,  # Shallower
    dx_max=0.3,  # Coarser
    dz_max=0.1
)

print(f"   ✓ Hillslope: {profile['x'][-1]:.1f} m long, {simgrid['depth']:.1f} m deep")
print(f"   ✓ Grid: {simgrid['shape']}")
print()

# Two-layer soil
print("2. Creating soil profile...")
standard_soils = get_standard_soils()
layer_boundaries = [{'type': 'depth', 'value': 0.8}]
layer_indices = create_soil_layers(simgrid['z'], layer_boundaries)

soil_types = {
    0: standard_soils['loam'],       # 0-0.8m: moderate K
    1: standard_soils['sandy_loam']  # 0.8-2.0m: higher K
}

soil_properties = assign_soil_properties(layer_indices, soil_types)
print(f"   ✓ Upper: {soil_types[0]['name']} (Ks={soil_types[0]['Ks']:.2e} m/s)")
print(f"   ✓ Lower: {soil_types[1]['name']} (Ks={soil_types[1]['Ks']:.2e} m/s)")
print()

# Macropores
print("3. Simulating macropores...")
macropores = simulate_macropores(
    simgrid=simgrid,
    n_pores_per_m2=3,  # Fewer pores
    mean_length=1.0,
    std_length=0.3,
    p_lateral=0.1,
    conductivity_multiplier=2.0,  # Less contrast
    seed=42
)
print(f"   ✓ Macropores: {macropores['n_pores']}")
print()

# CATFLOW mesh - smaller
print("4. Creating CATFLOW mesh...")
discretization = discretize_for_catflow(
    simgrid=simgrid,
    n_xsi=21,  # Smaller mesh
    n_eta=11,
    method='uniform'  # Simpler
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
print("5. Assigning properties...")
z_nodes = mesh.z
catflow_layers = create_soil_layers(z_nodes, layer_boundaries)
catflow_soil_props = assign_soil_properties(catflow_layers, soil_types)

coarse_macropores = map_macropores_to_coarse_grid(
    macropores, simgrid, discretization
)
print(f"   ✓ Macroporous cells: {np.sum(coarse_macropores > 1.0)}")
print()

# WETTER initial conditions (θ = 0.25 instead of 0.15)
print("6. Setting initial conditions...")
soil_model = VanGenuchten(L=0.5)
psi_init = np.zeros(mesh.shape)

for layer_idx in [0, 1]:
    mask = catflow_layers == layer_idx
    params = soil_types[layer_idx]

    # Start WETTER to reduce gradients
    target_theta = 0.25  # Much wetter than before

    Se = (target_theta - params['theta_r']) / (params['theta_s'] - params['theta_r'])
    Se = np.clip(Se, 0.01, 0.99)

    m = 1 - 1/params['n']
    psi = -(1/params['alpha']) * (Se**(-1/m) - 1)**(1/params['n'])

    psi_init[mask] = psi

print(f"   ✓ Initial θ ≈ 0.25 (moderately wet)")
print(f"   ✓ Pressure range: {psi_init.min():.2f} to {psi_init.max():.2f} m")
print()

# =============================================================================
# RAINFALL PHASE (2 days @ 15 mm/day)
# =============================================================================
print("=" * 70)
print("PHASE 1: RAINFALL (2 days @ 15 mm/day)")
print("=" * 70)

rainfall_rate = (15e-3) / (24 * 3600)
print(f"Rainfall: {rainfall_rate:.2e} m/s = 15 mm/day")
print()

bc_rainfall = {
    'top': {'type': 'neumann', 'value': -rainfall_rate},
    'bottom': {'type': 'dirichlet', 'value': -1.5}
}

base_soil_params = soil_types[0].copy()
equation_rain = Richards2D(mesh, soil_model, bc_rainfall)

# RELAXED solver settings
linear_solver = ConjugateGradientSolver(
    tolerance=1e-4,  # Relaxed from 1e-6
    max_iterations=2000  # Increased from 1000
)
time_stepper = PicardIteration(
    linear_solver=linear_solver,
    max_iterations=20,  # Increased from 15
    tolerance=0.01  # Relaxed from 0.001
)

model = CatflowModel(
    mesh=mesh,
    soil_model=soil_model,
    soil_params=base_soil_params,
    equation=equation_rain,
    time_stepper=time_stepper,
    initial_conditions=psi_init
)

results_rain = model.run(
    t_start=0.0,
    t_end=2 * 24 * 3600,
    dt_initial=300.0,  # Start larger
    dt_min=10.0,  # Higher minimum
    dt_max=3600.0,
    adaptive_stepping=True
)

print()
print(f"✓ Rainfall complete: {model.timestep_count} steps, "
      f"{len(results_rain['times'])} outputs")
print(f"  Convergence: {sum(results_rain['convergence'])}/{len(results_rain['convergence'])}")
print()

# =============================================================================
# DRAINAGE PHASE (7 days)
# =============================================================================
print("=" * 70)
print("PHASE 2: DRAINAGE (7 days)")
print("=" * 70)
print()

bc_drainage = {
    'top': {'type': 'neumann', 'value': 0.0},
    'bottom': {'type': 'dirichlet', 'value': -1.5}
}

equation_drain = Richards2D(mesh, soil_model, bc_drainage)

model_drain = CatflowModel(
    mesh=mesh,
    soil_model=soil_model,
    soil_params=base_soil_params,
    equation=equation_drain,
    time_stepper=time_stepper,
    initial_conditions=results_rain['psi'][-1]
)

results_drain = model_drain.run(
    t_start=2 * 24 * 3600,
    t_end=9 * 24 * 3600,
    dt_initial=300.0,
    dt_min=10.0,
    dt_max=3600.0,
    adaptive_stepping=True
)

print()
print(f"✓ Drainage complete: {model_drain.timestep_count} steps, "
      f"{len(results_drain['times'])} outputs")
print(f"  Convergence: {sum(results_drain['convergence'])}/{len(results_drain['convergence'])}")
print()

# =============================================================================
# ANALYZE RESULTS
# =============================================================================
print("=" * 70)
print("ANALYSIS")
print("=" * 70)
print()

all_times = results_rain['times'] + results_drain['times']
all_psi = results_rain['psi'] + results_drain['psi']
all_theta = results_rain['theta'] + results_drain['theta']
all_convergence = results_rain['convergence'] + results_drain['convergence']

times_days = np.array(all_times) / (24 * 3600)
mean_theta = [np.mean(theta) for theta in all_theta]

print(f"Total outputs: {len(all_times)}")
print(f"Convergence rate: {100*sum(all_convergence)/len(all_convergence):.1f}%")
print()
print(f"Initial mean θ: {mean_theta[0]:.4f}")
print(f"Peak mean θ:    {max(mean_theta):.4f} (at day {times_days[np.argmax(mean_theta)]:.2f})")
print(f"Final mean θ:   {mean_theta[-1]:.4f}")
print(f"Water gained:   {(max(mean_theta)-mean_theta[0])/mean_theta[0]*100:.1f}%")
print(f"Water retained: {(mean_theta[-1]-mean_theta[0])/mean_theta[0]*100:.1f}%")
print()

# =============================================================================
# VISUALIZE
# =============================================================================
x_nodes = mesh.x[0, :]
z_nodes = mesh.z
extent = [x_nodes[0], x_nodes[-1], z_nodes[-1, 0], z_nodes[0, 0]]

fig, axes = plt.subplots(2, 3, figsize=(15, 8))

# Snapshots at 0, 1, 2, 5, 9 days
snapshot_times = [0, 1.0, 2.0, 5.0, 9.0]
snapshot_indices = [np.argmin(np.abs(times_days - t)) for t in snapshot_times[:5]]

for i, (idx, t) in enumerate(zip(snapshot_indices[:5], snapshot_times[:5])):
    row = i // 3
    col = i % 3
    ax = axes[row, col]

    im = ax.imshow(all_psi[idx], extent=extent, aspect='auto',
                   cmap='viridis_r', vmin=-3, vmax=0, origin='upper')
    ax.plot(x_nodes, z_nodes[0, :], 'k-', linewidth=1.5)

    title = f't = {t:.1f} d (RAIN)' if t <= 2.0 else f't = {t:.1f} d (drain)'
    ax.set_title(title, fontweight='bold',
                color='blue' if t <= 2.0 else 'black')
    ax.set_ylabel('Elevation [m]')
    ax.set_xlabel('Distance [m]')
    plt.colorbar(im, ax=ax, label='ψ [m]')

# Water content evolution
ax = axes[1, 2]
ax.plot(times_days, mean_theta, 'b-', linewidth=2, label='Mean θ')
ax.axvline(x=2.0, color='r', linestyle='--', alpha=0.5, label='Rain ends')
ax.set_xlabel('Time [days]')
ax.set_ylabel('Mean θ [-]')
ax.set_title('Water Content Evolution')
ax.legend()
ax.grid(True, alpha=0.3)

plt.suptitle('Rainfall Simulation: 2 Days Rain (15 mm/d) + 7 Days Drainage',
            fontsize=13, fontweight='bold')
plt.tight_layout()
plt.savefig('/tmp/rainfall_improved.png', dpi=150)
print("✓ Saved: /tmp/rainfall_improved.png")

# Summary plot
fig2, axes2 = plt.subplots(1, 2, figsize=(12, 4))

# Water storage
ax = axes2[0]
storage = [(np.mean(theta) - mean_theta[0])/mean_theta[0]*100
           for theta in all_theta]
ax.plot(times_days, storage, 'g-', linewidth=2)
ax.axvline(x=2.0, color='r', linestyle='--', alpha=0.5)
ax.axhline(y=0, color='k', linestyle='-', alpha=0.3)
ax.set_xlabel('Time [days]')
ax.set_ylabel('Storage Change [%]')
ax.set_title('Water Storage Change')
ax.grid(True, alpha=0.3)

# Convergence
ax = axes2[1]
conv_rate = [100 * sum(all_convergence[:i+1])/(i+1)
             for i in range(len(all_convergence))]
ax.plot(times_days, conv_rate, 'purple', linewidth=2)
ax.axvline(x=2.0, color='r', linestyle='--', alpha=0.5)
ax.set_xlabel('Time [days]')
ax.set_ylabel('Success Rate [%]')
ax.set_title('Convergence Rate')
ax.set_ylim([0, 105])
ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('/tmp/rainfall_summary.png', dpi=150)
print("✓ Saved: /tmp/rainfall_summary.png")

print()
print("=" * 70)
print("SIMULATION COMPLETE!")
print("=" * 70)

plt.show()
