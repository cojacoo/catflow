"""
Macropore simulation for CATFLOW.

Python implementation of sim.mak from RCatflow - random walk simulation
of vertical macropores.
"""

import numpy as np
from scipy.stats import poisson, norm


def simulate_macropores(simgrid, n_pores_per_m2=4, mean_length=0.9,
                       std_length=0.1, p_lateral=0.2, min_separation=10,
                       conductivity_multiplier=2.0, layer_depths=None,
                       layer_properties=None, seed=None):
    """
    Simulate vertical macropores using random walk.

    Macropores are simulated as tortuous vertical pathways starting
    from the surface. The number of macropores follows a Poisson
    distribution, and their paths are determined by random walk.

    Parameters
    ----------
    simgrid : dict
        Fine simulation grid from make_simgrid
    n_pores_per_m2 : float
        Average number of macropores per square meter
    mean_length : float
        Mean vertical length of macropores [m]
    std_length : float
        Standard deviation of macropore length [m]
    p_lateral : float or list
        Probability for lateral step at each cell.
        Can be single value or list for multiple layers.
    min_separation : int
        Minimum separation between macropore starting points
        (in number of grid cells)
    conductivity_multiplier : float
        Factor by which macropores increase local conductivity
    layer_depths : list of float, optional
        Depths of layer boundaries [m] for multi-layer macropore
        properties
    layer_properties : list of dict, optional
        Properties for each layer, each dict containing:
        - p_lateral: probability of lateral step
        - conductivity: base conductivity [m/s]
    seed : int, optional
        Random seed for reproducibility

    Returns
    -------
    macropores : dict
        Dictionary containing:
        - multiplier: 2D array (same shape as simgrid['z']) with
          conductivity multipliers (1.0 = no macropore, >1.0 = macropore)
        - n_pores: Number of macropores simulated
        - lengths: Array of macropore lengths [m]
        - positions: Array of (row, col) starting positions

    Examples
    --------
    >>> # Single layer macropores
    >>> simgrid = make_simgrid(profile, depth=3.0, dx_max=0.1, dz_max=0.05)
    >>> macropores = simulate_macropores(simgrid, n_pores_per_m2=4,
    ...                                  mean_length=1.2, std_length=0.3)
    >>>
    >>> # Two-layer system with different properties
    >>> layer_depths = [1.0]  # boundary at 1m depth
    >>> layer_props = [
    ...     {'p_lateral': 0.1, 'conductivity': 1e-5},  # upper layer
    ...     {'p_lateral': 0.3, 'conductivity': 1e-6}   # lower layer
    ... ]
    >>> macropores = simulate_macropores(simgrid, layer_depths=layer_depths,
    ...                                  layer_properties=layer_props)
    """
    if seed is not None:
        np.random.seed(seed)

    nz, nx = simgrid['shape']
    x_coords = simgrid['x']
    z_grid = simgrid['z']
    widths = simgrid['width']
    dx = simgrid['dx']
    dz = simgrid['dz']

    # Initialize multiplier grid (1.0 = soil matrix, >1.0 = macropore)
    multiplier = np.ones((nz, nx))

    # Calculate surface area and expected number of macropores
    surface_area = np.sum(widths * dx)  # Total surface area [m²]
    expected_n_pores = n_pores_per_m2 * surface_area

    # Sample number of macropores from Poisson distribution
    n_pores = poisson.rvs(expected_n_pores)

    if n_pores == 0:
        return {
            'multiplier': multiplier,
            'n_pores': 0,
            'lengths': np.array([]),
            'positions': np.array([])
        }

    # Determine starting positions (surface, random x-coordinates)
    # Ensure minimum separation between pores
    available_cols = list(range(nx))
    start_cols = []

    for _ in range(n_pores):
        if not available_cols:
            break
        # Choose random column from available
        col = np.random.choice(available_cols)
        start_cols.append(col)

        # Remove columns within min_separation
        to_remove = []
        for c in available_cols:
            if abs(c - col) < min_separation:
                to_remove.append(c)
        for c in to_remove:
            available_cols.remove(c)

    n_pores_actual = len(start_cols)

    # Sample macropore lengths from normal distribution
    lengths = norm.rvs(loc=mean_length, scale=std_length, size=n_pores_actual)
    lengths = np.maximum(lengths, dz)  # At least one cell deep

    # Setup layer properties if specified
    if layer_depths is not None and layer_properties is not None:
        # Create layer assignment for each depth
        depth_below_surface = np.zeros((nz, nx))
        for i in range(nx):
            surface_z = z_grid[0, i]
            depth_below_surface[:, i] = surface_z - z_grid[:, i]

        # Assign layer index to each cell
        layer_indices = np.zeros((nz, nx), dtype=int)
        for i, boundary_depth in enumerate(layer_depths):
            layer_indices[depth_below_surface > boundary_depth] = i + 1

        # Extract p_lateral for each layer
        p_lateral_layers = [layer_properties[i]['p_lateral']
                           for i in range(len(layer_properties))]
    else:
        # Single layer
        layer_indices = np.zeros((nz, nx), dtype=int)
        p_lateral_layers = [p_lateral]

    # Simulate each macropore as random walk
    macropore_positions = []

    for pore_idx, (start_col, length) in enumerate(zip(start_cols, lengths)):
        # Current position
        row = 0
        col = start_col
        current_depth = 0.0

        path = [(row, col)]

        # Random walk downward
        while current_depth < length and row < nz - 1:
            # Determine layer at current position
            layer_idx = layer_indices[row, col]
            p_lat = p_lateral_layers[layer_idx]

            # Decide on lateral step
            if np.random.random() < p_lat:
                # Lateral step (left or right)
                direction = np.random.choice([-1, 1])
                new_col = col + direction

                # Check bounds
                if 0 <= new_col < nx:
                    col = new_col
                # If out of bounds, just continue downward

            # Move down one cell
            row += 1
            current_depth += dz

            # Record position
            path.append((row, col))

            # Mark this cell as macropore
            multiplier[row, col] = conductivity_multiplier

        macropore_positions.append(np.array(path))

    return {
        'multiplier': multiplier,
        'n_pores': n_pores_actual,
        'lengths': lengths,
        'positions': macropore_positions,
        'start_columns': start_cols
    }


def map_macropores_to_coarse_grid(macropores, simgrid, discretization):
    """
    Map macropores from fine simulation grid to coarser CATFLOW grid.

    Parameters
    ----------
    macropores : dict
        Macropore data from simulate_macropores
    simgrid : dict
        Fine simulation grid
    discretization : dict
        Coarse CATFLOW discretization from discretize_for_catflow

    Returns
    -------
    coarse_multiplier : ndarray
        Conductivity multiplier on coarse grid (n_eta, n_xsi)

    Examples
    --------
    >>> macropores = simulate_macropores(simgrid, ...)
    >>> disc = discretize_for_catflow(simgrid, n_xsi=41, n_eta=21)
    >>> coarse_mult = map_macropores_to_coarse_grid(macropores, simgrid, disc)
    """
    fine_mult = macropores['multiplier']
    nz_fine, nx_fine = simgrid['shape']

    n_eta = discretization['n_eta']
    n_xsi = discretization['n_xsi']

    # Create coarse multiplier grid
    coarse_mult = np.ones((n_eta, n_xsi))

    # Map fine grid indices to coarse grid
    xsi = discretization['xsi']
    eta = discretization['eta']

    # For each coarse cell, check if any fine cells contain macropores
    for i in range(n_xsi):
        # Find fine grid x range for this coarse cell
        if i == 0:
            x_start = 0
        else:
            x_start = int(xsi[i] * (nx_fine - 1))

        if i == n_xsi - 1:
            x_end = nx_fine
        else:
            x_end = int(xsi[i + 1] * (nx_fine - 1))

        for j in range(n_eta):
            # Find fine grid z range for this coarse cell
            if j == 0:
                z_start = 0
            else:
                z_start = int(eta[j] * (nz_fine - 1))

            if j == n_eta - 1:
                z_end = nz_fine
            else:
                z_end = int(eta[j + 1] * (nz_fine - 1))

            # Check if any fine cells in this region have macropores
            region = fine_mult[z_start:z_end, x_start:x_end]

            if np.any(region > 1.0):
                # Calculate average multiplier in this region
                coarse_mult[j, i] = np.mean(region[region > 1.0])

    return coarse_mult
