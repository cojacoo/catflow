"""
Hillslope geometry generation for CATFLOW.

Python implementation of make.simgrid and create_hillslope_profile
from the RCatflow preprocessing package.
"""

import numpy as np
from scipy.interpolate import interp1d, CubicSpline


def create_hillslope_profile(length, slope_angle=10, curvature='linear',
                             width=1.0, n_points=20):
    """
    Create a simple hillslope profile.

    Parameters
    ----------
    length : float
        Horizontal length of hillslope [m]
    slope_angle : float
        Average slope angle [degrees]
    curvature : str
        Type of hillslope curvature:
        - 'linear': Straight slope
        - 'convex': Convex curvature (steep top, gentle bottom)
        - 'concave': Concave curvature (gentle top, steep bottom)
        - 'complex': Sinusoidal variation
    width : float or array
        Hillslope width [m]. Can be scalar or array of length n_points
    n_points : int
        Number of points defining the hillslope

    Returns
    -------
    profile : dict
        Dictionary containing:
        - x: Horizontal distance along slope [m]
        - y: Lateral coordinate (set to 0 for 2D) [m]
        - z: Elevation [m]
        - width: Hillslope width [m]

    Examples
    --------
    >>> # Simple linear hillslope
    >>> profile = create_hillslope_profile(100, slope_angle=15, curvature='linear')
    >>>
    >>> # Complex hillslope with variable width
    >>> widths = np.linspace(0.5, 2.0, 20)
    >>> profile = create_hillslope_profile(100, slope_angle=10,
    ...                                    curvature='complex', width=widths)
    """
    # Horizontal coordinate
    x = np.linspace(0, length, n_points)
    y = np.zeros_like(x)

    # Calculate elevation based on curvature type
    slope_rad = np.radians(slope_angle)
    total_drop = length * np.tan(slope_rad)

    if curvature == 'linear':
        # Simple linear slope
        z = total_drop * (1 - x / length)

    elif curvature == 'convex':
        # Convex: z = a * x^2 + b * x + c
        # Steep at top, gentle at bottom
        normalized_x = x / length
        z = total_drop * (1 - normalized_x**2)

    elif curvature == 'concave':
        # Concave: gentle at top, steep at bottom
        normalized_x = x / length
        z = total_drop * (1 - normalized_x)**2

    elif curvature == 'complex':
        # Sinusoidal variation for more realistic hillslope
        normalized_x = x / length
        base_slope = total_drop * (1 - normalized_x)
        # Add gentle sinusoidal variation (5% of total drop)
        variation = 0.05 * total_drop * np.sin(normalized_x * 3 * np.pi)
        z = base_slope + variation

    else:
        raise ValueError(f"Unknown curvature type: {curvature}")

    # Handle width
    if np.isscalar(width):
        width = np.full(n_points, width)
    elif len(width) != n_points:
        raise ValueError(f"Width array length ({len(width)}) must match n_points ({n_points})")

    return {
        'x': x,
        'y': y,
        'z': z,
        'width': width
    }


def make_simgrid(profile, depth, dx_max=0.1, dz_max=0.1):
    """
    Create a fine Cartesian simulation grid for a hillslope profile.

    This function creates a high-resolution grid suitable for simulating
    macropores and other fine-scale structures.

    Parameters
    ----------
    profile : dict
        Hillslope profile from create_hillslope_profile, with keys:
        - x: horizontal coordinates [m]
        - y: lateral coordinates [m]
        - z: elevation [m]
        - width: hillslope width [m]
    depth : float
        Depth of simulation domain below surface [m]
    dx_max : float, optional
        Maximum horizontal resolution [m] (default: 0.1)
    dz_max : float, optional
        Maximum vertical resolution [m] (default: 0.1)

    Returns
    -------
    simgrid : dict
        Dictionary containing:
        - x: 1D array of horizontal coordinates [m]
        - z: 2D array of vertical coordinates (nz, nx) [m]
        - width: 1D array of interpolated widths [m]
        - dx: Actual horizontal spacing [m]
        - dz: Actual vertical spacing [m]
        - shape: (nz, nx)

    Examples
    --------
    >>> profile = create_hillslope_profile(50, slope_angle=10)
    >>> simgrid = make_simgrid(profile, depth=3.0, dx_max=0.1, dz_max=0.05)
    >>> print(f"Grid shape: {simgrid['shape']}")
    """
    # Extract profile data
    x_profile = profile['x']
    z_profile = profile['z']
    width_profile = profile['width']

    # Calculate cumulative distance along slope
    dx_orig = np.diff(x_profile)
    dy_orig = np.diff(profile['y'])
    distances = np.sqrt(dx_orig**2 + dy_orig**2)
    cumulative_distance = np.concatenate([[0], np.cumsum(distances)])

    # Total length along slope
    total_length = cumulative_distance[-1]

    # Number of horizontal points
    nx = int(np.ceil(total_length / dx_max)) + 1
    dx_actual = total_length / (nx - 1)

    # Create new horizontal coordinates (equally spaced along slope)
    x_new = np.linspace(0, total_length, nx)

    # Interpolate elevation along new x coordinates
    interp_z = interp1d(cumulative_distance, z_profile, kind='cubic',
                        fill_value='extrapolate')
    z_surface = interp_z(x_new)

    # Interpolate width
    interp_width = interp1d(cumulative_distance, width_profile, kind='linear',
                           fill_value='extrapolate')
    width_new = interp_width(x_new)

    # Create vertical discretization
    nz = int(np.ceil(depth / dz_max)) + 1
    dz_actual = depth / (nz - 1)

    # Create 2D grid of z coordinates
    # Each column starts at surface elevation and extends downward
    z_grid = np.zeros((nz, nx))
    for i in range(nx):
        z_grid[:, i] = z_surface[i] - np.linspace(0, depth, nz)

    return {
        'x': x_new,
        'z': z_grid,
        'width': width_new,
        'dx': dx_actual,
        'dz': dz_actual,
        'shape': (nz, nx),
        'depth': depth
    }


def discretize_for_catflow(simgrid, n_xsi=41, n_eta=21, method='adaptive'):
    """
    Create CATFLOW discretization from fine simulation grid.

    Reduces the fine simulation grid to a coarser grid suitable for
    CATFLOW simulations.

    Parameters
    ----------
    simgrid : dict
        Fine simulation grid from make_simgrid
    n_xsi : int
        Number of nodes in lateral (horizontal) direction
    n_eta : int
        Number of nodes in vertical direction
    method : str
        Discretization method:
        - 'uniform': Uniform spacing
        - 'adaptive': Finer near surface and bottom

    Returns
    -------
    discretization : dict
        Dictionary containing:
        - xsi: Relative coordinates in lateral direction (0 to 1)
        - eta: Relative coordinates in vertical direction (0 to 1)
        - x_nodes: Actual horizontal positions [m]
        - z_nodes: 2D array of vertical positions [m]

    Examples
    --------
    >>> simgrid = make_simgrid(profile, depth=3.0)
    >>> disc = discretize_for_catflow(simgrid, n_xsi=41, n_eta=21,
    ...                               method='adaptive')
    """
    if method == 'uniform':
        # Uniform spacing in both directions
        xsi = np.linspace(0, 1, n_xsi)
        eta = np.linspace(0, 1, n_eta)

    elif method == 'adaptive':
        # Finer near boundaries for better resolution of gradients
        # Use power law distribution
        power = 1.5

        # Lateral: finer near ends
        xsi_left = (np.linspace(0, 0.5, n_xsi//2 + 1)**power) * 0.5
        xsi_right = 0.5 + (np.linspace(0, 0.5, n_xsi - n_xsi//2)**power) * 0.5
        xsi = np.concatenate([xsi_left[:-1], xsi_right])

        # Vertical: finer near surface and bottom
        eta_top = (np.linspace(0, 0.5, n_eta//2 + 1)**(1/power)) * 0.5
        eta_bottom = 0.5 + (np.linspace(0, 0.5, n_eta - n_eta//2)**(1/power)) * 0.5
        eta = np.concatenate([eta_top[:-1], eta_bottom])

    else:
        raise ValueError(f"Unknown discretization method: {method}")

    # Map to actual coordinates
    nx_fine = simgrid['shape'][1]
    nz_fine = simgrid['shape'][0]

    # Horizontal positions
    x_indices = xsi * (nx_fine - 1)
    x_nodes = np.interp(x_indices, np.arange(nx_fine), simgrid['x'])

    # Vertical positions (interpolate each column)
    z_nodes = np.zeros((n_eta, n_xsi))
    for i, xi in enumerate(x_indices):
        # Find nearest column in fine grid
        col_idx = int(np.round(xi))
        z_column = simgrid['z'][:, col_idx]
        z_indices = eta * (nz_fine - 1)
        z_nodes[:, i] = np.interp(z_indices, np.arange(nz_fine), z_column)

    return {
        'xsi': xsi,
        'eta': eta,
        'x_nodes': x_nodes,
        'z_nodes': z_nodes,
        'n_xsi': n_xsi,
        'n_eta': n_eta
    }
