"""
Picard iteration for nonlinear Richards equation.

Implements the Picard (successive substitution) method for solving
the nonlinear Richards equation at each time step.
"""

import numpy as np


class PicardIteration:
    """
    Picard iteration time stepper for nonlinear Richards equation.

    At each time step, iteratively solves:
        1. Linearize with K(ψ^k), C(ψ^k) from current iterate
        2. Solve linear system for ψ^(k+1)
        3. Check convergence
        4. Repeat until converged

    Parameters
    ----------
    linear_solver : LinearSolver
        Linear system solver (e.g., ConjugateGradientSolver)
    max_iterations : int, optional
        Maximum number of Picard iterations (default: 20)
    tolerance : float, optional
        Convergence tolerance in pressure head [m] (default: 1e-4)
    relaxation : float, optional
        Under-relaxation parameter (default: 1.0, no relaxation)
        Set < 1.0 for difficult problems
    """

    def __init__(self, linear_solver, max_iterations=20,
                 tolerance=1e-4, relaxation=1.0):
        """Initialize Picard iteration."""
        self.linear_solver = linear_solver
        self.max_iterations = max_iterations
        self.tolerance = tolerance
        self.relaxation = relaxation

        # Diagnostics
        self.last_iterations = 0
        self.last_error = 0.0
        self.convergence_history = []

    def step(self, equation, psi_old, t, dt, soil_params, bc_override=None):
        """
        Advance solution by one time step using Picard iteration.

        Parameters
        ----------
        equation : Richards2D
            Richards equation assembler
        psi_old : np.ndarray
            Pressure head at previous time step, shape (n_eta, n_xsi) [m]
        t : float
            Current time [s]
        dt : float
            Time step size [s]
        soil_params : dict
            Soil hydraulic parameters
        bc_override : dict, optional
            Override boundary conditions for this timestep

        Returns
        -------
        psi_new : np.ndarray
            Pressure head at new time step, shape (n_eta, n_xsi)
        converged : bool
            Whether iteration converged
        n_iterations : int
            Number of iterations performed

        Raises
        ------
        RuntimeError
            If Picard iteration fails to converge
        """
        # Initialize with old solution
        psi_new = psi_old.copy()

        # Store convergence history
        self.convergence_history = []

        # Picard iteration loop
        for iteration in range(self.max_iterations):
            # Assemble system with current iterate
            A, b = equation.assemble_system(psi_new, dt, soil_params,
                                           bc_override=bc_override)

            # Solve linear system
            psi_flat = self.linear_solver.solve(
                A, b,
                x0=psi_new.flatten()
            )

            # Reshape to 2D
            psi_next = psi_flat.reshape(equation.mesh.shape)

            # Apply under-relaxation if specified
            if self.relaxation < 1.0:
                psi_next = (self.relaxation * psi_next +
                           (1.0 - self.relaxation) * psi_new)

            # Check convergence
            error = np.max(np.abs(psi_next - psi_new))
            self.convergence_history.append(error)

            # Store diagnostics
            self.last_error = error
            self.last_iterations = iteration + 1

            # Check if converged
            if error < self.tolerance:
                return psi_next, True, self.last_iterations

            # Update for next iteration
            psi_new = psi_next

        # Did not converge
        raise RuntimeError(
            f"Picard iteration did not converge in {self.max_iterations} "
            f"iterations (final error: {self.last_error:.2e} m)"
        )

    def get_convergence_info(self):
        """
        Get convergence information from last step.

        Returns
        -------
        info : dict
            Dictionary with convergence diagnostics
        """
        return {
            'iterations': self.last_iterations,
            'error': self.last_error,
            'history': self.convergence_history
        }
