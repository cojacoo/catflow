"""
Generate 1D vertical column benchmark case.

Creates identical inputs for both Python and Fortran CATFLOW
to enable direct numerical comparison.
"""

import numpy as np
import sys
from pathlib import Path

# Add catflow to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from catflow.core.mesh import CurvilinearHillslopeMesh
from catflow.core.physics.soil_models import VanGenuchten
from catflow.core.equations import Richards2D
from catflow.core.solvers import ConjugateGradientSolver
from catflow.core.time_stepping import PicardIteration
from catflow.core.model import CatflowModel


def create_1d_column_mesh(depth=1.0, n_nodes=21):
    """
    Create a 1D vertical column mesh.

    This is implemented as a degenerate 2D mesh that is only
    1 node wide in the lateral direction.

    Parameters
    ----------
    depth : float
        Column depth [m]
    n_nodes : int
        Number of nodes in vertical direction

    Returns
    -------
    mesh : CurvilinearHillslopeMesh
        1D column mesh (degenerate 2D)
    """
    # Create a "hillslope" that is actually a vertical column
    # 0.01m wide (effectively 1D)
    profile_x = np.array([0.0, 0.01])  # Very narrow
    profile_y = np.array([0.0, 0.0])   # No lateral offset
    profile_z = np.array([depth, depth])  # Flat top

    # Discretization
    xsi_nodes = np.array([0.0, 1.0])  # Only 2 nodes laterally (1D)
    eta_nodes = np.linspace(0, 1, n_nodes)  # Vertical discretization

    mesh = CurvilinearHillslopeMesh(
        profile_x=profile_x,
        profile_y=profile_y,
        profile_z=profile_z,
        thickness=depth,
        xsi_nodes=xsi_nodes,
        eta_nodes=eta_nodes,
        geometry_type='constant'
    )

    return mesh


def get_benchmark_soil_params():
    """
    Get standard soil parameters for benchmark.

    Uses well-documented loamy sand parameters that are
    commonly cited in literature.

    Returns
    -------
    params : dict
        Van Genuchten parameters
    """
    return {
        'theta_s': 0.41,    # Carsel & Parrish (1988) loamy sand
        'theta_r': 0.057,
        'alpha': 7.5,       # [1/m]
        'n': 1.89,
        'Ks': 1.23e-5       # [m/s] ≈ 1.06 m/day
    }


def setup_python_case(output_dir, n_vertical=21):
    """
    Set up Python CATFLOW 1D column case.

    Parameters
    ----------
    output_dir : str or Path
        Directory to save Python configuration
    n_vertical : int
        Number of vertical nodes

    Returns
    -------
    model : CatflowModel
        Configured model ready to run
    config : dict
        Configuration for reproduction
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    print("Setting up Python 1D column case...")

    # 1. Mesh
    mesh = create_1d_column_mesh(depth=1.0, n_nodes=n_vertical)
    print(f"  Mesh: {mesh.shape[0]} × {mesh.shape[1]} nodes")

    # 2. Soil
    soil_model = VanGenuchten(L=0.5)
    soil_params = get_benchmark_soil_params()
    print(f"  Soil: Van Genuchten (loamy sand)")

    # 3. Boundary conditions
    boundary_conditions = {
        'top': {'type': 'dirichlet', 'value': -0.1},     # -10 cm (infiltration)
        'bottom': {'type': 'dirichlet', 'value': -1.0},  # -100 cm (drainage)
    }
    print(f"  BC top: ψ = {boundary_conditions['top']['value']} m")
    print(f"  BC bottom: ψ = {boundary_conditions['bottom']['value']} m")

    # 4. Equation
    equation = Richards2D(mesh, soil_model, boundary_conditions)

    # 5. Solver
    linear_solver = ConjugateGradientSolver(tolerance=1e-8, max_iterations=1000)
    time_stepper = PicardIteration(linear_solver, max_iterations=20, tolerance=1e-5)

    # 6. Initial conditions - uniform
    initial_psi = -0.5 * np.ones(mesh.shape)  # -50 cm initial suction
    print(f"  Initial: ψ = {initial_psi[0,0]} m (uniform)")

    # 7. Model
    model = CatflowModel(
        mesh=mesh,
        soil_model=soil_model,
        soil_params=soil_params,
        equation=equation,
        time_stepper=time_stepper,
        initial_conditions=initial_psi
    )

    # Configuration for reproduction
    config = {
        'depth': 1.0,
        'n_vertical': n_vertical,
        'n_lateral': 2,
        'soil_params': soil_params,
        'boundary_conditions': boundary_conditions,
        'initial_psi': -0.5,
        'time_start': 0.0,
        'time_end': 3600.0,  # 1 hour
        'dt_initial': 60.0,   # 1 minute
        'dt_min': 1.0,
        'dt_max': 300.0,
    }

    # Save configuration
    import json
    with open(output_dir / 'python_config.json', 'w') as f:
        json.dump(config, f, indent=2)

    print(f"  Configuration saved to {output_dir / 'python_config.json'}")

    return model, config


def write_fortran_inputs(output_dir, config):
    """
    Write Fortran CATFLOW input files for 1D column.

    Creates all necessary input files for Fortran CATFLOW
    to run the identical case.

    Parameters
    ----------
    output_dir : str or Path
        Directory to save Fortran inputs
    config : dict
        Configuration from setup_python_case()
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    print("\nGenerating Fortran input files...")

    # Import Fortran I/O utilities
    sys.path.insert(0, str(Path(__file__).parent.parent))
    from comparison_tools.fortran_io import (
        write_fortran_initial_conditions,
        write_fortran_soil_file
    )

    # 1. Initial conditions file
    n_eta = config['n_vertical']
    n_xsi = config['n_lateral']
    psi_init = config['initial_psi'] * np.ones((n_eta, n_xsi))
    write_fortran_initial_conditions(output_dir / 'hang1.ini', psi_init)

    # 2. Soil file
    write_fortran_soil_file(
        output_dir / 'soil.bod',
        config['soil_params'],
        soil_name='loamy_sand'
    )

    # 3. Control file (simplified - user must adapt)
    with open(output_dir / 'catflow.in', 'w') as f:
        f.write("# CATFLOW control file for 1D column benchmark\n")
        f.write("# Generated automatically - ADAPT AS NEEDED\n")
        f.write("#\n")
        f.write(f"# Case: 1D vertical column infiltration\n")
        f.write(f"# Depth: {config['depth']} m\n")
        f.write(f"# Nodes: {n_eta} vertical × {n_xsi} lateral\n")
        f.write(f"# Duration: {config['time_end']/3600:.1f} hours\n")
        f.write("#\n")
        f.write("# TODO: Complete with proper Fortran CATFLOW syntax\n")

    print(f"  Files written to: {output_dir}")
    print(f"    - hang1.ini (initial conditions)")
    print(f"    - soil.bod (soil parameters)")
    print(f"    - catflow.in (control file template)")

    # 4. Geometry file would go here
    print("\n  NOTE: Geometry file (.geo) generation not yet implemented.")
    print("        You may need to generate this manually or adapt existing one.")


def run_python_benchmark(model, config, output_dir):
    """
    Run the Python benchmark case.

    Parameters
    ----------
    model : CatflowModel
        Configured model
    config : dict
        Configuration
    output_dir : str or Path
        Directory to save results

    Returns
    -------
    results : dict
        Simulation results
    """
    output_dir = Path(output_dir)

    print("\n" + "=" * 70)
    print("RUNNING PYTHON BENCHMARK")
    print("=" * 70)

    results = model.run(
        t_start=config['time_start'],
        t_end=config['time_end'],
        dt_initial=config['dt_initial'],
        dt_min=config['dt_min'],
        dt_max=config['dt_max'],
        adaptive_stepping=True
    )

    # Export results
    model.export_results(output_dir / 'python_results.npz', format='npz')

    print("\n" + "=" * 70)
    print("Python benchmark complete!")
    print(f"Results saved to: {output_dir / 'python_results.npz'}")
    print("=" * 70)

    return results


def main():
    """Main execution."""
    print("=" * 70)
    print("1D COLUMN BENCHMARK CASE GENERATOR")
    print("=" * 70)

    # Setup directories
    base_dir = Path(__file__).parent / '1d_column_infiltration'
    python_dir = base_dir / 'python'
    fortran_dir = base_dir / 'fortran'

    # Generate Python case
    model, config = setup_python_case(python_dir, n_vertical=21)

    # Generate Fortran inputs
    write_fortran_inputs(fortran_dir, config)

    # Run Python case
    results = run_python_benchmark(model, config, python_dir)

    # Summary
    print("\n" + "=" * 70)
    print("NEXT STEPS")
    print("=" * 70)
    print("1. Adapt Fortran inputs in:", fortran_dir)
    print("2. Run Fortran CATFLOW with these inputs")
    print("3. Use comparison tools to analyze differences:")
    print("   python validation/comparison_tools/compare_results.py \\")
    print(f"       {python_dir}/python_results.npz \\")
    print(f"       {fortran_dir}/psi.out")
    print("=" * 70)


if __name__ == '__main__':
    main()
