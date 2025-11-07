"""
Curvilinear mesh for boundary-fitted hillslope coordinates.

This implements the coordinate transformation from CATFLOW's nat2koor
approach, creating orthogonal curvilinear coordinates that follow
the hillslope geometry.
"""

import numpy as np
from scipy.integrate import solve_ivp
from scipy.interpolate import CubicSpline
from catflow.core.mesh.base import Mesh


class CurvilinearHillslopeMesh(Mesh):
    """
    Boundary-fitted orthogonal curvilinear mesh for hillslopes.

    Generates a computational grid where coordinate lines follow the
    hillslope geometry. Coordinates (ξ, η) are transformed to physical
    space (x, y) using boundary-fitted transformation.

    Parameters
    ----------
    profile_x : array_like
        X-coordinates of hillslope profile [m]
    profile_y : array_like
        Y-coordinates of hillslope profile [m]
    profile_z : array_like
        Elevation of hillslope profile [m]
    thickness : float
        Hillslope thickness (depth) [m]
    xsi_nodes : array_like
        Normalized lateral discretization (0 to 1)
    eta_nodes : array_like
        Normalized vertical discretization (0 to 1)
    geometry_type : str, optional
        Type of geometry: 'constant' (default) or 'cake'

    Attributes
    ----------
    x : np.ndarray
        Physical x-coordinates, shape (n_eta, n_xsi)
    y : np.ndarray
        Physical y-coordinates, shape (n_eta, n_xsi)
    z : np.ndarray
        Elevation coordinates, shape (n_eta, n_xsi)
    g_xsi : np.ndarray
        Metric coefficient in xsi direction
    g_eta : np.ndarray
        Metric coefficient in eta direction
    """

    def __init__(self, profile_x, profile_y, profile_z, thickness,
                 xsi_nodes, eta_nodes, geometry_type='constant'):
        """Initialize curvilinear hillslope mesh."""
        # Store input parameters
        self.profile_x = np.asarray(profile_x)
        self.profile_y = np.asarray(profile_y)
        self.profile_z = np.asarray(profile_z)
        self.thickness = thickness
        self.xsi = np.asarray(xsi_nodes)
        self.eta = np.asarray(eta_nodes)
        self.geometry_type = geometry_type

        # Grid dimensions
        self.n_xsi = len(xsi_nodes)
        self.n_eta = len(eta_nodes)
        self._n_nodes = self.n_xsi * self.n_eta

        # Generate mesh
        self._create_boundaries()
        self._generate_grid()
        self._compute_metric_coefficients()

    def _create_boundaries(self):
        """Create boundary curves using cubic splines."""
        # Parametric coordinate along profile
        dx = np.diff(self.profile_x)
        dy = np.diff(self.profile_y)
        ds = np.sqrt(dx**2 + dy**2)
        s = np.zeros(len(self.profile_x))
        s[1:] = np.cumsum(ds)
        s = s / s[-1]  # Normalize to [0, 1]

        # Upper boundary (surface)
        self.boundary_upper_x = CubicSpline(s, self.profile_x, bc_type='natural')
        self.boundary_upper_y = CubicSpline(s, self.profile_y, bc_type='natural')
        self.boundary_upper_z = CubicSpline(s, self.profile_z, bc_type='natural')

        # Lower boundary (depends on geometry type)
        if self.geometry_type == 'constant':
            # Constant thickness - offset perpendicular to surface
            dx_ds = self.boundary_upper_x.derivative()(s)
            dy_ds = self.boundary_upper_y.derivative()(s)

            # Normal vector (perpendicular, pointing down)
            norm = np.sqrt(dx_ds**2 + dy_ds**2)
            normal_x = -dy_ds / norm
            normal_y = dx_ds / norm

            # Offset by thickness
            x_lower = self.profile_x + self.thickness * normal_x
            y_lower = self.profile_y + self.thickness * normal_y
            z_lower = self.profile_z - self.thickness

        elif self.geometry_type == 'cake':
            # Horizontal lower boundary
            x_lower = self.profile_x
            y_lower = self.profile_y
            z_lower = self.profile_z - self.thickness

        else:
            raise ValueError(f"Unknown geometry type: {self.geometry_type}")

        self.boundary_lower_x = CubicSpline(s, x_lower, bc_type='natural')
        self.boundary_lower_y = CubicSpline(s, y_lower, bc_type='natural')
        self.boundary_lower_z = CubicSpline(s, z_lower, bc_type='natural')

    def _generate_grid(self):
        """
        Generate coordinate grid using linear interpolation.

        For the prototype, we use simple linear interpolation between
        upper and lower boundaries. A more sophisticated implementation
        would solve ODEs for truly orthogonal coordinates.
        """
        # Initialize coordinate arrays
        self.x = np.zeros((self.n_eta, self.n_xsi))
        self.y = np.zeros((self.n_eta, self.n_xsi))
        self.z = np.zeros((self.n_eta, self.n_xsi))

        # For each lateral position (xsi)
        for j, xsi_val in enumerate(self.xsi):
            # Get boundary coordinates
            x_upper = self.boundary_upper_x(xsi_val)
            y_upper = self.boundary_upper_y(xsi_val)
            z_upper = self.boundary_upper_z(xsi_val)

            x_lower = self.boundary_lower_x(xsi_val)
            y_lower = self.boundary_lower_y(xsi_val)
            z_lower = self.boundary_lower_z(xsi_val)

            # Linear interpolation in eta direction
            for i, eta_val in enumerate(self.eta):
                self.x[i, j] = x_upper + eta_val * (x_lower - x_upper)
                self.y[i, j] = y_upper + eta_val * (y_lower - y_upper)
                self.z[i, j] = z_upper + eta_val * (z_lower - z_upper)

    def _compute_metric_coefficients(self):
        """
        Compute metric tensor components.

        For orthogonal curvilinear coordinates:
        g_ξ = |∂r/∂ξ|
        g_η = |∂r/∂η|
        """
        # Compute derivatives using central differences
        dx_dxsi = np.gradient(self.x, self.xsi, axis=1)
        dy_dxsi = np.gradient(self.y, self.xsi, axis=1)

        dx_deta = np.gradient(self.x, self.eta, axis=0)
        dy_deta = np.gradient(self.y, self.eta, axis=0)

        # Metric coefficients
        self.g_xsi = np.sqrt(dx_dxsi**2 + dy_dxsi**2)
        self.g_eta = np.sqrt(dx_deta**2 + dy_deta**2)

        # Jacobian (for area calculations)
        self.jacobian = dx_dxsi * dy_deta - dx_deta * dy_dxsi

        # Store derivatives for later use
        self.dx_dxsi = dx_dxsi
        self.dy_dxsi = dy_dxsi
        self.dx_deta = dx_deta
        self.dy_deta = dy_deta

    def get_node_coordinates(self):
        """
        Get node coordinates in physical space.

        Returns
        -------
        x : np.ndarray
            X-coordinates, shape (n_eta, n_xsi)
        y : np.ndarray
            Y-coordinates, shape (n_eta, n_xsi)
        """
        return self.x, self.y

    def get_metric_coefficients(self):
        """
        Get metric tensor coefficients.

        Returns
        -------
        dict
            Dictionary with 'g_xsi', 'g_eta', 'jacobian'
        """
        return {
            'g_xsi': self.g_xsi,
            'g_eta': self.g_eta,
            'jacobian': self.jacobian
        }

    def get_cell_volumes(self):
        """
        Get cell areas (2D mesh).

        Returns
        -------
        areas : np.ndarray
            Cell areas, shape (n_eta-1, n_xsi-1)
        """
        # For structured grid, approximate cell area as g_xsi * g_eta * dxsi * deta
        dxsi = np.diff(self.xsi)
        deta = np.diff(self.eta)

        # Cell-centered metric coefficients (average of nodes)
        g_xsi_cell = 0.25 * (self.g_xsi[:-1, :-1] + self.g_xsi[:-1, 1:] +
                             self.g_xsi[1:, :-1] + self.g_xsi[1:, 1:])
        g_eta_cell = 0.25 * (self.g_eta[:-1, :-1] + self.g_eta[:-1, 1:] +
                             self.g_eta[1:, :-1] + self.g_eta[1:, 1:])

        # Cell areas
        areas = np.outer(deta, dxsi) * g_xsi_cell * g_eta_cell

        return areas

    @property
    def n_nodes(self):
        """Total number of nodes."""
        return self._n_nodes

    @property
    def shape(self):
        """Shape of the mesh (n_eta, n_xsi)."""
        return (self.n_eta, self.n_xsi)

    def plot(self, ax=None, show_nodes=True, show_grid=True):
        """
        Plot the mesh for visualization.

        Parameters
        ----------
        ax : matplotlib.axes.Axes, optional
            Axes to plot on. If None, creates new figure.
        show_nodes : bool, optional
            Whether to show node points (default: True)
        show_grid : bool, optional
            Whether to show grid lines (default: True)

        Returns
        -------
        ax : matplotlib.axes.Axes
            The axes object
        """
        import matplotlib.pyplot as plt

        if ax is None:
            fig, ax = plt.subplots(figsize=(10, 6))

        # Plot grid lines
        if show_grid:
            # Lateral lines (constant xsi)
            for j in range(self.n_xsi):
                ax.plot(self.x[:, j], self.y[:, j], 'b-', alpha=0.3, linewidth=0.5)

            # Vertical lines (constant eta)
            for i in range(self.n_eta):
                ax.plot(self.x[i, :], self.y[i, :], 'b-', alpha=0.3, linewidth=0.5)

        # Plot boundaries
        ax.plot(self.x[0, :], self.y[0, :], 'k-', linewidth=2, label='Upper boundary')
        ax.plot(self.x[-1, :], self.y[-1, :], 'k-', linewidth=2, label='Lower boundary')

        # Plot nodes
        if show_nodes:
            ax.plot(self.x.flatten(), self.y.flatten(), 'r.', markersize=2)

        ax.set_xlabel('X [m]')
        ax.set_ylabel('Y [m]')
        ax.set_aspect('equal')
        ax.legend()
        ax.grid(True, alpha=0.2)
        ax.set_title('Curvilinear Hillslope Mesh')

        return ax
