"""
Main CATFLOW model orchestrator.

Coordinates all components to run a complete simulation.
"""

import numpy as np
from datetime import datetime, timedelta


class CatflowModel:
    """
    Main CATFLOW simulation model.

    Orchestrates the complete simulation workflow:
    1. Mesh generation and initialization
    2. Time stepping
    3. Equation assembly and solving
    4. Results storage

    This class provides the high-level interface for running
    CATFLOW simulations with the modular plugin architecture.

    Parameters
    ----------
    mesh : Mesh
        Computational mesh
    soil_model : SoilHydraulicModel
        Soil hydraulic model (pluggable)
    soil_params : dict
        Soil hydraulic parameters
    equation : Richards2D
        Governing equation assembler
    time_stepper : PicardIteration
        Time stepping algorithm
    initial_conditions : np.ndarray
        Initial pressure head field, shape (n_eta, n_xsi)

    Attributes
    ----------
    results : dict
        Simulation results stored as:
        - 'times': List of output times
        - 'psi': List of pressure head arrays
        - 'theta': List of water content arrays
    """

    def __init__(self, mesh, soil_model, soil_params, equation,
                 time_stepper, initial_conditions,
                 weather_forcing=None, surface_balance=None):
        """Initialize CATFLOW model."""
        self.mesh = mesh
        self.soil = soil_model
        self.soil_params = soil_params
        self.equation = equation
        self.time_stepper = time_stepper
        self.psi = initial_conditions.copy()

        # Weather forcing (optional)
        self.weather = weather_forcing
        self.surface = surface_balance

        # Initialize surface balance if weather provided
        if self.weather is not None and self.surface is None:
            from .surface_balance import SurfaceWaterBalance
            self.surface = SurfaceWaterBalance(mesh)

        # Results storage
        self.results = {
            'times': [],
            'psi': [],
            'theta': [],
            'convergence': []
        }

        # Simulation state
        self.current_time = 0.0
        self.timestep_count = 0

    def run(self, t_start, t_end, dt_initial, dt_min=1.0, dt_max=3600.0,
            output_times=None, adaptive_stepping=True):
        """
        Run the simulation.

        Parameters
        ----------
        t_start : float
            Start time [s]
        t_end : float
            End time [s]
        dt_initial : float
            Initial time step [s]
        dt_min : float, optional
            Minimum time step [s] (default: 1.0)
        dt_max : float, optional
            Maximum time step [s] (default: 3600.0)
        output_times : list of float, optional
            Specific times to save output. If None, saves every step.
        adaptive_stepping : bool, optional
            Whether to use adaptive time stepping (default: True)

        Returns
        -------
        results : dict
            Simulation results with times, psi, theta
        """
        print(f"\nStarting CATFLOW simulation")
        print(f"Time range: {t_start:.1f} to {t_end:.1f} seconds")
        print(f"Initial time step: {dt_initial:.1f} seconds")
        print(f"Mesh size: {self.mesh.shape}")
        print("-" * 60)

        # Initialize
        self.current_time = t_start
        dt = dt_initial

        # Save initial conditions
        self._save_output(self.current_time, self.psi, converged=True)

        # Main time loop
        while self.current_time < t_end:
            # Adjust last time step to hit t_end exactly
            if self.current_time + dt > t_end:
                dt = t_end - self.current_time

            # Get weather forcing and compute dynamic BC if applicable
            bc_override = None
            if self.weather is not None:
                from .surface_balance import compute_infiltration_capacity

                # Get forcing for this timestep
                rain, pet = self.weather.get_forcing(
                    self.current_time,
                    self.current_time + dt
                )

                # Get current surface state
                psi_surface = self.psi[0, :]  # Top row

                # Get Ks at surface (handle both array and scalar)
                Ks_param = self.soil_params['Ks']
                if isinstance(Ks_param, np.ndarray) and Ks_param.ndim > 1:
                    Ks_surface = Ks_param[0, :]
                elif isinstance(Ks_param, np.ndarray):
                    Ks_surface = Ks_param
                else:
                    # Scalar - broadcast to surface
                    Ks_surface = np.full(self.mesh.shape[1], Ks_param)

                # Get soil width at surface
                # Use uniform width for now (could be improved with actual hillslope width)
                soil_width = np.ones(self.mesh.shape[1])

                # Compute infiltration capacity
                infil_capacity = compute_infiltration_capacity(
                    psi_surface,
                    Ks_surface,
                    self.soil_params['theta_s'],
                    self.soil_params['theta_r'],
                    self.soil_params['alpha'],
                    self.soil_params['n']
                )

                # Update surface water balance
                bc_flux, runoff, actual_et = self.surface.update(
                    dt, rain, pet, infil_capacity,
                    psi_surface, soil_width
                )

                # Create BC override (keep bottom BC from equation)
                bc_override = {
                    'top': bc_flux,
                    'bottom': self.equation.bc.get('bottom', {'type': 'dirichlet', 'value': -2.5})
                }

            # Try to take a time step
            try:
                psi_new, converged, n_iter = self.time_stepper.step(
                    self.equation,
                    self.psi,
                    self.current_time,
                    dt,
                    self.soil_params,
                    bc_override=bc_override
                )

                # Step succeeded
                self.psi = psi_new
                self.current_time += dt
                self.timestep_count += 1

                # Print progress
                progress = (self.current_time - t_start) / (t_end - t_start) * 100
                print(f"Time: {self.current_time:8.1f} s  "
                      f"dt: {dt:6.1f} s  "
                      f"Picard iter: {n_iter:2d}  "
                      f"Progress: {progress:5.1f}%")

                # Save output
                if output_times is None:
                    self._save_output(self.current_time, self.psi, converged)
                elif any(abs(self.current_time - t) < 0.1 for t in output_times):
                    self._save_output(self.current_time, self.psi, converged)

                # Adaptive time stepping
                if adaptive_stepping:
                    dt = self._adapt_timestep(dt, n_iter, dt_min, dt_max)

            except RuntimeError as e:
                # Time step failed - reduce dt and retry
                print(f"  Step failed: {e}")
                dt = max(dt * 0.5, dt_min)
                print(f"  Reducing time step to {dt:.2f} s and retrying...")

                if dt < dt_min:
                    raise RuntimeError(
                        f"Time step fell below minimum ({dt_min} s). "
                        "Simulation terminated."
                    )

        print("-" * 60)
        print(f"Simulation completed!")
        print(f"Total time steps: {self.timestep_count}")
        print(f"Output snapshots: {len(self.results['times'])}")

        # Print water balance if weather forcing was used
        if self.weather is not None:
            balance = self.surface.get_water_balance()
            print()
            print("Water Balance:")
            print(f"  Rainfall:      {balance['rain']:.6f} m³")
            print(f"  Infiltration:  {balance['infiltration']:.6f} m³")
            print(f"  Runoff:        {balance['runoff']:.6f} m³")
            print(f"  ET:            {balance['et']:.6f} m³")
            print(f"  Balance error: {balance['balance_error']:.6e} m³")

        return self.results

    def _save_output(self, time, psi, converged):
        """
        Save output at current time.

        Parameters
        ----------
        time : float
            Current simulation time
        psi : np.ndarray
            Pressure head field
        converged : bool
            Whether the time step converged
        """
        # Calculate derived quantities
        theta = self.soil.theta_from_psi(psi, self.soil_params)

        # Store results
        self.results['times'].append(time)
        self.results['psi'].append(psi.copy())
        self.results['theta'].append(theta.copy())
        self.results['convergence'].append(converged)

    def _adapt_timestep(self, dt_current, n_iterations, dt_min, dt_max):
        """
        Adapt time step based on convergence rate.

        Parameters
        ----------
        dt_current : float
            Current time step
        n_iterations : int
            Number of Picard iterations in last step
        dt_min : float
            Minimum allowed time step
        dt_max : float
            Maximum allowed time step

        Returns
        -------
        dt_new : float
            New time step
        """
        # Heuristic: adjust based on iteration count
        if n_iterations < 5:
            # Converged quickly - increase time step
            dt_new = min(dt_current * 1.2, dt_max)
        elif n_iterations < 10:
            # Normal convergence - keep time step
            dt_new = dt_current
        else:
            # Slow convergence - decrease time step
            dt_new = max(dt_current * 0.8, dt_min)

        return dt_new

    def get_water_balance(self):
        """
        Calculate water balance for the simulation.

        Returns
        -------
        balance : dict
            Water balance components
        """
        # Calculate total water content at each time
        volumes = []
        for theta in self.results['theta']:
            # Volume = integral of theta over domain
            cell_volumes = self.mesh.get_cell_volumes()
            # Average theta to cells
            theta_cells = 0.25 * (theta[:-1, :-1] + theta[:-1, 1:] +
                                 theta[1:, :-1] + theta[1:, 1:])
            total_volume = np.sum(theta_cells * cell_volumes)
            volumes.append(total_volume)

        balance = {
            'times': self.results['times'],
            'total_water': volumes,
            'storage_change': np.diff(volumes).tolist() if len(volumes) > 1 else []
        }

        return balance

    def export_results(self, filename, format='npz'):
        """
        Export results to file.

        Parameters
        ----------
        filename : str
            Output filename
        format : str, optional
            Export format: 'npz' (NumPy) or 'vtk' (ParaView)

        Returns
        -------
        None
        """
        if format == 'npz':
            # Export as NumPy compressed archive
            np.savez_compressed(
                filename,
                times=np.array(self.results['times']),
                psi=np.array(self.results['psi']),
                theta=np.array(self.results['theta']),
                x=self.mesh.x,
                y=self.mesh.y,
                z=self.mesh.z
            )
            print(f"Results exported to {filename}")

        elif format == 'vtk':
            # VTK export would go here
            # (requires pyvista or similar)
            raise NotImplementedError("VTK export not yet implemented")

        else:
            raise ValueError(f"Unknown export format: {format}")
