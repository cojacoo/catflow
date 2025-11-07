"""
Python wrapper for the Fortran CATFLOW example.

This script creates a Python CATFLOW setup that matches the Fortran
example in ../model/example/, enabling direct comparison.
"""

import numpy as np
import sys
from pathlib import Path
import json

# Add catflow to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from catflow.core.mesh import CurvilinearHillslopeMesh
from catflow.core.physics.soil_models import VanGenuchten
from catflow.core.equations import Richards2D
from catflow.core.solvers import ConjugateGradientSolver
from catflow.core.time_stepping import PicardIteration
from catflow.core.model import CatflowModel


class FortranExampleConfig:
    """
    Configuration extracted from Fortran example.

    This reads the Fortran bod5.in file and extracts key parameters.
    """

    def __init__(self, fortran_example_dir):
        """
        Initialize from Fortran example directory.

        Parameters
        ----------
        fortran_example_dir : str or Path
            Path to ../model/example/ directory
        """
        self.fortran_dir = Path(fortran_example_dir)

        # Read Fortran control file
        self._read_fortran_config()

        # Simplified configuration
        self.config = self._create_simplified_config()

    def _read_fortran_config(self):
        """Read key parameters from Fortran bod5.in file."""
        bod_file = self.fortran_dir / 'bod5.in'

        with open(bod_file, 'r') as f:
            lines = f.readlines()

        # Parse key parameters (line numbers are 1-indexed in description)
        self.start_time = lines[0].split()[0]  # Date format
        self.end_time = lines[1].split()[0]
        self.solver = lines[3].split()[0]  # 'pic'
        self.dt_max = float(lines[6].split()[0])
        self.dt_min = float(lines[7].split()[0])
        self.dt_initial = float(lines[8].split()[0])
        self.picard_tol = float(lines[13].split()[0])
        self.cg_tol = float(lines[14].split()[0])
        self.picard_max_iter = int(lines[12].split()[0])

        print(f"Fortran config read from: {bod_file}")
        print(f"  Solver: {self.solver}")
        print(f"  Time steps: dt_min={self.dt_min}, dt_max={self.dt_max}, dt_init={self.dt_initial}")
        print(f"  Tolerances: Picard={self.picard_tol}, CG={self.cg_tol}")

    def _create_simplified_config(self):
        """Create simplified configuration dict."""
        return {
            'simulation': {
                'start_time': self.start_time,
                'end_time': self.end_time,
                'dt_initial': self.dt_initial,
                'dt_min': self.dt_min,
                'dt_max': self.dt_max,
            },
            'solver': {
                'type': self.solver,
                'picard_tolerance': self.picard_tol,
                'picard_max_iter': self.picard_max_iter,
                'cg_tolerance': self.cg_tol,
            },
            'mesh': {
                'n_eta': 41,
                'n_xsi': 101,
                'geometry_file': 'in/twolayer.geo',
            },
            'soil': {
                'model': 'van_genuchten',
                'types': self._extract_soil_types(),
            },
            'initial_conditions': {
                'type': 'layered',
                'layers': [
                    {'eta_range': (0, 3), 'theta': 0.3},
                    {'eta_range': (3, 30), 'theta': 0.1},
                    {'eta_range': (30, 41), 'theta': 0.2},
                ]
            }
        }

    def _extract_soil_types(self):
        """Extract soil parameters from Fortran soil definition file."""
        soil_file = self.fortran_dir / 'in' / 'global' / 'soil_lux.def'

        # For now, use soil type 4 (sandiger Lehm - SL 8)
        # From line 22: 1.23e-5  0.41  0.065  7.50  1.89
        return {
            'default': {
                'name': 'sandiger_lehm_SL8',
                'Ks': 1.23e-5,      # [m/s]
                'theta_s': 0.41,
                'theta_r': 0.065,
                'alpha': 7.50,      # [1/m]
                'n': 1.89,
            }
        }

    def save_to_yaml(self, filename):
        """Save configuration to YAML file."""
        import yaml
        with open(filename, 'w') as f:
            yaml.dump(self.config, f, default_flow_style=False, sort_keys=False)
        print(f"Configuration saved to: {filename}")

    def save_to_json(self, filename):
        """Save configuration to JSON file."""
        with open(filename, 'w') as f:
            json.dump(self.config, f, indent=2)
        print(f"Configuration saved to: {filename}")


def load_fortran_geometry(geo_file):
    """
    Load geometry from Fortran .geo file.

    This is a simplified loader that extracts just the coordinate arrays.

    Parameters
    ----------
    geo_file : str or Path
        Path to .geo file

    Returns
    -------
    x, y, z : np.ndarray
        Coordinate arrays, shape (n_eta, n_xsi)
    """
    geo_file = Path(geo_file)

    with open(geo_file, 'r') as f:
        # Read header line
        header = f.readline().split()
        n_eta = int(header[0])
        n_xsi = int(header[1])

        print(f"Loading geometry: {n_eta} × {n_xsi} nodes")

        # Skip reference coordinates
        for _ in range(2):
            f.readline()

        # Read eta discretization
        eta = []
        for _ in range(n_eta):
            eta.append(float(f.readline().strip()))
        eta = np.array(eta)

        # Read xsi discretization (with coordinates)
        xsi = []
        xsi_coords = []
        for _ in range(n_xsi):
            line = f.readline().split()
            xsi.append(float(line[0]))
            xsi_coords.append([float(line[1]), float(line[2])])
        xsi = np.array(xsi)

        # Read node data - this is complex, for now we'll create a simplified mesh
        # In Fortran .geo format, each node has: x, y, z, and metric coefficients
        # We'll read just the coordinates

        # For simplicity, create a regular grid based on xsi_coords
        # This is approximate but sufficient for testing
        x_profile = np.array([c[0] for c in xsi_coords])
        y_profile = np.array([c[1] for c in xsi_coords])

        # Create profile elevation (simplified - assuming flat or reading from BNA)
        z_profile = np.zeros_like(x_profile)  # Placeholder

    print(f"  Eta range: {eta[0]:.3f} to {eta[-1]:.3f}")
    print(f"  Xsi range: {xsi[0]:.3f} to {xsi[-1]:.3f}")
    print(f"  Profile length: {x_profile[-1] - x_profile[0]:.1f} m")

    return x_profile, y_profile, z_profile, eta, xsi


def theta_to_psi(theta, soil_params):
    """
    Convert water content to pressure head using Van Genuchten inverse.

    Parameters
    ----------
    theta : float or array
        Water content [-]
    soil_params : dict
        Soil parameters

    Returns
    -------
    psi : float or array
        Pressure head [m]
    """
    theta_s = soil_params['theta_s']
    theta_r = soil_params['theta_r']
    alpha = soil_params['alpha']
    n = soil_params['n']
    m = 1 - 1/n

    # Effective saturation
    Se = (theta - theta_r) / (theta_s - theta_r)
    Se = np.clip(Se, 0.001, 0.999)  # Avoid numerical issues

    # Van Genuchten inverse
    psi = -(1.0 / alpha) * (Se**(-1.0/m) - 1.0)**(1.0/n)

    return psi


def create_python_model_from_fortran(fortran_example_dir):
    """
    Create Python CATFLOW model matching Fortran example.

    Parameters
    ----------
    fortran_example_dir : str or Path
        Path to Fortran example directory

    Returns
    -------
    model : CatflowModel
        Configured Python model
    config : FortranExampleConfig
        Configuration object
    """
    print("=" * 70)
    print("CREATING PYTHON MODEL FROM FORTRAN EXAMPLE")
    print("=" * 70)

    # Load configuration
    config_obj = FortranExampleConfig(fortran_example_dir)
    config = config_obj.config

    # Note: Full geometry loading from .geo is complex
    # For this prototype, we'll create a simplified mesh with same dimensions
    print("\nCreating simplified mesh (full .geo parsing not yet implemented)...")

    # Create a simple hillslope profile
    # This is a placeholder - ideally we'd parse the full .geo file
    n_xsi = config['mesh']['n_xsi']
    x_profile = np.linspace(0, 100, n_xsi)  # 100m hillslope
    y_profile = np.zeros_like(x_profile)
    z_profile = 100 - 0.1 * x_profile  # 10m drop over 100m

    n_eta = config['mesh']['n_eta']
    eta_nodes = np.linspace(0, 1, n_eta)
    xsi_nodes = np.linspace(0, 1, n_xsi)

    mesh = CurvilinearHillslopeMesh(
        profile_x=x_profile,
        profile_y=y_profile,
        profile_z=z_profile,
        thickness=3.0,  # Approximate from geometry
        xsi_nodes=xsi_nodes,
        eta_nodes=eta_nodes,
        geometry_type='constant'
    )
    print(f"  Mesh created: {mesh.shape}")

    # Soil model
    soil_model = VanGenuchten(L=0.5)
    soil_params = config['soil']['types']['default']
    print(f"\nSoil: {soil_params['name']}")
    print(f"  Ks = {soil_params['Ks']:.2e} m/s")
    print(f"  θs = {soil_params['theta_s']}, θr = {soil_params['theta_r']}")
    print(f"  α = {soil_params['alpha']}, n = {soil_params['n']}")

    # Initial conditions - layered theta converted to psi
    print("\nInitial conditions:")
    psi_init = np.zeros(mesh.shape)
    for layer in config['initial_conditions']['layers']:
        eta_start, eta_end = layer['eta_range']
        theta_layer = layer['theta']
        psi_layer = theta_to_psi(theta_layer, soil_params)

        psi_init[eta_start:eta_end, :] = psi_layer
        print(f"  Rows {eta_start}-{eta_end}: θ = {theta_layer} → ψ = {psi_layer:.3f} m")

    # Boundary conditions (simplified - would need to parse .rb file)
    boundary_conditions = {
        'top': {'type': 'dirichlet', 'value': -0.5},    # Placeholder
        'bottom': {'type': 'dirichlet', 'value': -2.0}, # Placeholder
    }
    print("\nBoundary conditions (placeholder):")
    print(f"  Top: ψ = {boundary_conditions['top']['value']} m")
    print(f"  Bottom: ψ = {boundary_conditions['bottom']['value']} m")

    # Equation
    equation = Richards2D(mesh, soil_model, boundary_conditions)

    # Solver
    solver_config = config['solver']
    linear_solver = ConjugateGradientSolver(
        tolerance=solver_config['cg_tolerance'],
        max_iterations=1000
    )
    time_stepper = PicardIteration(
        linear_solver=linear_solver,
        max_iterations=solver_config['picard_max_iter'],
        tolerance=solver_config['picard_tolerance']
    )
    print(f"\nSolver: Picard iteration with CG")
    print(f"  Picard tol: {solver_config['picard_tolerance']}")
    print(f"  CG tol: {solver_config['cg_tolerance']}")

    # Create model
    model = CatflowModel(
        mesh=mesh,
        soil_model=soil_model,
        soil_params=soil_params,
        equation=equation,
        time_stepper=time_stepper,
        initial_conditions=psi_init
    )

    print("\n" + "=" * 70)
    print("Python model created successfully!")
    print("=" * 70)

    return model, config_obj


def run_comparison(fortran_example_dir, output_dir, duration_hours=1):
    """
    Run Python model and prepare for comparison with Fortran.

    Parameters
    ----------
    fortran_example_dir : str or Path
        Path to Fortran example
    output_dir : str or Path
        Where to save results
    duration_hours : float
        How long to simulate (for quick test)
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Create model
    model, config = create_python_model_from_fortran(fortran_example_dir)

    # Save configuration
    config.save_to_json(output_dir / 'python_config.json')

    # Run for short duration (can increase later)
    print(f"\n{'='*70}")
    print(f"RUNNING PYTHON MODEL ({duration_hours} hour test)")
    print(f"{'='*70}")

    t_end = duration_hours * 3600.0
    results = model.run(
        t_start=0.0,
        t_end=t_end,
        dt_initial=config.config['simulation']['dt_initial'],
        dt_min=config.config['simulation']['dt_min'],
        dt_max=config.config['simulation']['dt_max'],
        adaptive_stepping=True
    )

    # Export results
    model.export_results(output_dir / 'python_results.npz')

    print(f"\n{'='*70}")
    print("Python run complete!")
    print(f"Results saved to: {output_dir}")
    print(f"{'='*70}")

    return results


def main():
    """Main execution."""
    # Paths
    fortran_example = Path(__file__).parent.parent.parent / 'model' / 'example'
    output_dir = Path(__file__).parent.parent / 'examples' / 'fortran_comparison'

    print("=" * 70)
    print("FORTRAN EXAMPLE WRAPPER FOR PYTHON CATFLOW")
    print("=" * 70)
    print(f"\nFortran example: {fortran_example}")
    print(f"Output directory: {output_dir}")

    if not fortran_example.exists():
        print(f"\nERROR: Fortran example not found at {fortran_example}")
        print("Please check the path.")
        return

    # Run comparison
    results = run_comparison(fortran_example, output_dir, duration_hours=1)

    print("\n" + "=" * 70)
    print("NEXT STEPS")
    print("=" * 70)
    print("\n1. Run Fortran CATFLOW:")
    print(f"   cd {fortran_example}")
    print("   ./catflow")
    print("\n2. Compare results:")
    print("   python catflow_python/validation/comparison_tools/compare_results.py \\")
    print(f"       {output_dir}/python_results.npz \\")
    print(f"       {fortran_example}/out/psi_m.out")
    print("\n" + "=" * 70)


if __name__ == '__main__':
    main()
