"""
Iterative linear system solvers.

Wraps SciPy's sparse linear algebra solvers with a consistent interface.
"""

import numpy as np
from scipy.sparse.linalg import cg, bicgstab, gmres


class ConjugateGradientSolver:
    """
    Conjugate Gradient solver for symmetric positive definite systems.

    Wraps scipy.sparse.linalg.cg with consistent interface and
    convergence tracking.

    Parameters
    ----------
    tolerance : float, optional
        Convergence tolerance (default: 1e-6)
    max_iterations : int, optional
        Maximum number of iterations (default: 1000)
    """

    def __init__(self, tolerance=1e-6, max_iterations=1000):
        """Initialize CG solver."""
        self.tolerance = tolerance
        self.max_iterations = max_iterations
        self.last_iterations = 0
        self.last_residual = 0.0

    def solve(self, A, b, x0=None):
        """
        Solve the linear system A·x = b.

        Parameters
        ----------
        A : scipy.sparse matrix
            System matrix (must be symmetric positive definite)
        b : np.ndarray
            Right-hand side vector
        x0 : np.ndarray, optional
            Initial guess (default: zeros)

        Returns
        -------
        x : np.ndarray
            Solution vector

        Raises
        ------
        RuntimeError
            If the solver fails to converge
        """
        # Callback to track iterations
        self.last_iterations = 0

        def callback(xk):
            self.last_iterations += 1

        # Solve using SciPy's CG
        x, info = cg(
            A, b,
            x0=x0,
            atol=self.tolerance,
            maxiter=self.max_iterations,
            callback=callback
        )

        # Check convergence
        if info > 0:
            raise RuntimeError(
                f"CG solver did not converge in {info} iterations"
            )
        elif info < 0:
            raise RuntimeError(
                f"CG solver failed with illegal input or breakdown (info={info})"
            )

        # Calculate residual
        self.last_residual = np.linalg.norm(A @ x - b)

        return x

    def get_convergence_info(self):
        """
        Get information about the last solve.

        Returns
        -------
        info : dict
            Dictionary with 'iterations' and 'residual'
        """
        return {
            'iterations': self.last_iterations,
            'residual': self.last_residual
        }


class BiCGSTABSolver:
    """
    BiConjugate Gradient Stabilized solver for non-symmetric systems.

    Wraps scipy.sparse.linalg.bicgstab.

    Parameters
    ----------
    tolerance : float, optional
        Convergence tolerance (default: 1e-6)
    max_iterations : int, optional
        Maximum number of iterations (default: 1000)
    """

    def __init__(self, tolerance=1e-6, max_iterations=1000):
        """Initialize BiCGSTAB solver."""
        self.tolerance = tolerance
        self.max_iterations = max_iterations
        self.last_iterations = 0
        self.last_residual = 0.0

    def solve(self, A, b, x0=None):
        """
        Solve the linear system A·x = b.

        Parameters
        ----------
        A : scipy.sparse matrix
            System matrix
        b : np.ndarray
            Right-hand side vector
        x0 : np.ndarray, optional
            Initial guess

        Returns
        -------
        x : np.ndarray
            Solution vector
        """
        self.last_iterations = 0

        def callback(xk):
            self.last_iterations += 1

        x, info = bicgstab(
            A, b,
            x0=x0,
            atol=self.tolerance,
            maxiter=self.max_iterations,
            callback=callback
        )

        if info != 0:
            raise RuntimeError(f"BiCGSTAB solver failed (info={info})")

        self.last_residual = np.linalg.norm(A @ x - b)

        return x

    def get_convergence_info(self):
        """Get convergence information."""
        return {
            'iterations': self.last_iterations,
            'residual': self.last_residual
        }
