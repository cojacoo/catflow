"""
Simple hillslope infiltration example.

Demonstrates the modular CATFLOW architecture with a simple test case:
- Sloping hillslope with uniform soil
- Constant infiltration at surface
- Drainage at bottom boundary
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
from pathlib import Path

# Add catflow to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from catflow.core.mesh import CurvilinearHillslopeMesh
from catflow.core.physics.soil_models import VanGenuchten
from catflow.core.equations import Richards2D
from catflow.core.solvers import ConjugateGradientSolver
from catflow.core.time_stepping import PicardIteration
from catflow.core.model import CatflowModel


def create_hillslope_profile():
    """
    Create a simple hillslope profile.

    Returns a hillslope that is 50m long with 10m elevation drop.
    """
    # Profile coordinates
    x = np.linspace(0, 50, 25)  # 50m long
    y = np.zeros_like(x)         # No lateral offset
    z = 100 - 0.2 * x            # 10m drop over 50m (20% slope)

    return x, y, z


def setup_simulation():
    """
    Set up the complete simulation.

    This demonstrates the modular architecture - each component
    can be easily swapped for a different implementation.
    """
    print("=" * 70)
    print("CATFLOW Prototype - Simple Hillslope Example")
    print("=" * 70)

    # 1. CREATE MESH
    print("\n1. Creating curvilinear mesh...")
    x, y, z = create_hillslope_profile()

    # Discretization
    xsi_nodes = np.linspace(0, 1, 20)  # 20 nodes laterally
    eta_nodes = np.linspace(0, 1, 15)  # 15 nodes vertically

    mesh = CurvilinearHillslopeMesh(
        profile_x=x,
        profile_y=y,
        profile_z=z,
        thickness=2.0,  # 2m thick hillslope
        xsi_nodes=xsi_nodes,
        eta_nodes=eta_nodes,
        geometry_type='constant'
    )
    print(f"   Mesh created: {mesh.shape[0]} × {mesh.shape[1]} = {mesh.n_nodes} nodes")

    # 2. DEFINE SOIL MODEL (PLUGGABLE!)
    print("\n2. Setting up soil hydraulic model...")
    print("   Using: Van Genuchten-Mualem")

    soil_model = VanGenuchten(L=0.5)

    # Soil parameters (loamy sand)
    soil_params = {
        'theta_s': 0.41,   # Saturated water content
        'theta_r': 0.057,  # Residual water content
        'alpha': 7.5,      # [1/m]
        'n': 1.89,         # [-]
        'Ks': 1.23e-5      # Hydraulic conductivity [m/s] ≈ 1 m/day
    }
    print(f"   θ_s = {soil_params['theta_s']}, θ_r = {soil_params['theta_r']}")
    print(f"   α = {soil_params['alpha']} 1/m, n = {soil_params['n']}")
    print(f"   K_s = {soil_params['Ks']:.2e} m/s")

    # 3. SET UP BOUNDARY CONDITIONS
    print("\n3. Defining boundary conditions...")
    boundary_conditions = {
        'top': {'type': 'dirichlet', 'value': -0.5},      # -0.5m (wet)
        'bottom': {'type': 'dirichlet', 'value': -2.0},   # -2.0m (drainage)
    }
    print("   Top: ψ = -0.5 m (infiltration)")
    print("   Bottom: ψ = -2.0 m (drainage)")
    print("   Sides: No flow")

    # 4. CREATE GOVERNING EQUATION
    print("\n4. Assembling Richards equation...")
    equation = Richards2D(
        mesh=mesh,
        soil_model=soil_model,
        boundary_conditions=boundary_conditions
    )
    print("   2D Richards equation in curvilinear coordinates")

    # 5. CHOOSE LINEAR SOLVER (PLUGGABLE!)
    print("\n5. Selecting linear solver...")
    print("   Using: Conjugate Gradient")
    linear_solver = ConjugateGradientSolver(
        tolerance=1e-6,
        max_iterations=1000
    )

    # 6. CHOOSE TIME STEPPING METHOD (PLUGGABLE!)
    print("\n6. Configuring time stepper...")
    print("   Using: Picard iteration")
    time_stepper = PicardIteration(
        linear_solver=linear_solver,
        max_iterations=20,
        tolerance=1e-4
    )

    # 7. SET INITIAL CONDITIONS
    print("\n7. Setting initial conditions...")
    # Start with uniform moderately dry conditions
    initial_psi = -1.0 * np.ones(mesh.shape)  # -1.0m everywhere
    print(f"   Initial ψ = {initial_psi[0, 0]:.2f} m (uniform)")

    # 8. CREATE MODEL
    print("\n8. Creating CATFLOW model...")
    model = CatflowModel(
        mesh=mesh,
        soil_model=soil_model,
        soil_params=soil_params,
        equation=equation,
        time_stepper=time_stepper,
        initial_conditions=initial_psi
    )
    print("   Model ready!")

    return model, mesh, soil_model, soil_params


def run_simulation(model):
    """
    Run the simulation.

    Parameters
    ----------
    model : CatflowModel
        Configured model

    Returns
    -------
    results : dict
        Simulation results
    """
    # Simulation parameters
    t_start = 0.0          # Start time [s]
    t_end = 3600.0 * 6     # End time [s] - 6 hours
    dt_initial = 300.0     # Initial time step [s] - 5 minutes

    # Run simulation
    results = model.run(
        t_start=t_start,
        t_end=t_end,
        dt_initial=dt_initial,
        dt_min=10.0,
        dt_max=600.0,
        adaptive_stepping=True
    )

    return results


def visualize_results(model, results, mesh, soil_model, soil_params):
    """
    Visualize simulation results.

    Creates several plots:
    1. Mesh geometry
    2. Initial and final moisture distribution
    3. Time series at selected points
    """
    print("\n" + "=" * 70)
    print("Visualizing results...")

    fig = plt.figure(figsize=(15, 10))

    # 1. MESH GEOMETRY
    ax1 = plt.subplot(2, 3, 1)
    mesh.plot(ax=ax1, show_nodes=False)
    ax1.set_title('Computational Mesh')

    # 2. INITIAL MOISTURE
    ax2 = plt.subplot(2, 3, 2)
    theta_initial = results['theta'][0]
    im2 = ax2.contourf(mesh.x, mesh.y, theta_initial, levels=15, cmap='Blues')
    ax2.set_title('Initial Water Content')
    ax2.set_xlabel('X [m]')
    ax2.set_ylabel('Y [m]')
    ax2.set_aspect('equal')
    plt.colorbar(im2, ax=ax2, label='θ [-]')

    # 3. FINAL MOISTURE
    ax3 = plt.subplot(2, 3, 3)
    theta_final = results['theta'][-1]
    im3 = ax3.contourf(mesh.x, mesh.y, theta_final, levels=15, cmap='Blues')
    ax3.set_title(f'Final Water Content (t={results["times"][-1]/3600:.1f} hr)')
    ax3.set_xlabel('X [m]')
    ax3.set_ylabel('Y [m]')
    ax3.set_aspect('equal')
    plt.colorbar(im3, ax=ax3, label='θ [-]')

    # 4. TIME SERIES AT SURFACE
    ax4 = plt.subplot(2, 3, 4)
    times_hours = np.array(results['times']) / 3600.0
    # Extract surface moisture at mid-slope
    j_mid = mesh.n_xsi // 2
    theta_surface = [theta[0, j_mid] for theta in results['theta']]
    ax4.plot(times_hours, theta_surface, 'b-', linewidth=2)
    ax4.set_xlabel('Time [hours]')
    ax4.set_ylabel('Surface θ [-]')
    ax4.set_title('Moisture at Surface (mid-slope)')
    ax4.grid(True, alpha=0.3)

    # 5. VERTICAL PROFILE AT FINAL TIME
    ax5 = plt.subplot(2, 3, 5)
    j_mid = mesh.n_xsi // 2
    theta_profile = theta_final[:, j_mid]
    depth = mesh.z[:, j_mid] - mesh.z[-1, j_mid]  # Depth from bottom
    ax5.plot(theta_profile, depth, 'b-o', linewidth=2, markersize=4)
    ax5.set_xlabel('Water Content θ [-]')
    ax5.set_ylabel('Depth [m]')
    ax5.set_title('Final Vertical Profile (mid-slope)')
    ax5.grid(True, alpha=0.3)
    ax5.invert_yaxis()

    # 6. WATER BALANCE
    ax6 = plt.subplot(2, 3, 6)
    balance = model.get_water_balance()
    ax6.plot(times_hours, balance['total_water'], 'b-', linewidth=2)
    ax6.set_xlabel('Time [hours]')
    ax6.set_ylabel('Total Water [m³]')
    ax6.set_title('Water Balance')
    ax6.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig('catflow_example_results.png', dpi=150, bbox_inches='tight')
    print("   Results saved to: catflow_example_results.png")

    plt.show()


def main():
    """Main execution function."""
    # Set up simulation
    model, mesh, soil_model, soil_params = setup_simulation()

    # Run simulation
    print("\n" + "=" * 70)
    results = run_simulation(model)

    # Visualize results
    visualize_results(model, results, mesh, soil_model, soil_params)

    # Print summary
    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"Total simulation time: {results['times'][-1]/3600:.2f} hours")
    print(f"Number of outputs: {len(results['times'])}")
    print(f"Final surface moisture: {results['theta'][-1][0, mesh.n_xsi//2]:.3f}")
    print(f"Initial surface moisture: {results['theta'][0][0, mesh.n_xsi//2]:.3f}")

    # Export results
    output_file = 'catflow_example_results.npz'
    model.export_results(output_file, format='npz')

    print("\n" + "=" * 70)
    print("DEMONSTRATION OF MODULARITY")
    print("=" * 70)
    print("To swap components, simply change the initialization:")
    print("\n# Different soil model:")
    print("from catflow.core.physics.soil_models import BrooksCorey")
    print("soil_model = BrooksCorey()")
    print("\n# Different solver:")
    print("from catflow.core.solvers import BiCGSTABSolver")
    print("linear_solver = BiCGSTABSolver()")
    print("\n# Different ET model (when implemented):")
    print("from catflow.core.physics.sources import PriestleyTaylorET")
    print("et_model = PriestleyTaylorET(climate_data)")
    print("=" * 70)


if __name__ == '__main__':
    main()
