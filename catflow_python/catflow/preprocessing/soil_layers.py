"""
Soil layer assignment for CATFLOW.

Tools for creating multi-layer soil profiles and assigning
hydraulic properties.
"""

import numpy as np


def create_soil_layers(z_grid, layer_boundaries):
    """
    Create soil layer assignment for a grid.

    Parameters
    ----------
    z_grid : ndarray
        2D array of elevation coordinates (nz, nx) [m]
    layer_boundaries : list of dict
        List defining layer boundaries, each with:
        - type: 'depth' (below surface) or 'elevation' (absolute z)
        - value: depth or elevation [m]
        - name: layer name (optional)

    Returns
    -------
    layer_indices : ndarray
        2D array (nz, nx) with layer index for each cell (0, 1, 2, ...)

    Examples
    --------
    >>> z_grid = simgrid['z']
    >>> # Two layers: 0-1m and 1m-bottom
    >>> boundaries = [
    ...     {'type': 'depth', 'value': 1.0, 'name': 'topsoil'},
    ... ]
    >>> layers = create_soil_layers(z_grid, boundaries)
    """
    nz, nx = z_grid.shape
    layer_indices = np.zeros((nz, nx), dtype=int)

    # Calculate depth below surface for each cell
    depth_below_surface = np.zeros((nz, nx))
    for i in range(nx):
        surface_z = z_grid[0, i]
        depth_below_surface[:, i] = surface_z - z_grid[:, i]

    # Assign layers based on boundaries
    for layer_idx, boundary in enumerate(layer_boundaries):
        if boundary['type'] == 'depth':
            # Depth below surface
            mask = depth_below_surface > boundary['value']
            layer_indices[mask] = layer_idx + 1

        elif boundary['type'] == 'elevation':
            # Absolute elevation
            mask = z_grid < boundary['value']
            layer_indices[mask] = layer_idx + 1

        else:
            raise ValueError(f"Unknown boundary type: {boundary['type']}")

    return layer_indices


def assign_soil_properties(layer_indices, soil_types):
    """
    Assign soil hydraulic properties to layers.

    Parameters
    ----------
    layer_indices : ndarray
        2D array with layer index for each cell
    soil_types : dict
        Dictionary mapping layer index to soil parameters, e.g.:
        {
            0: {'name': 'sandy_loam', 'Ks': 1.23e-5, 'theta_s': 0.41,
                'theta_r': 0.065, 'alpha': 7.5, 'n': 1.89},
            1: {'name': 'clay', 'Ks': 1e-6, 'theta_s': 0.45,
                'theta_r': 0.1, 'alpha': 2.0, 'n': 1.4}
        }

    Returns
    -------
    properties : dict
        Dictionary with 2D arrays for each property:
        - Ks: Saturated hydraulic conductivity [m/s]
        - theta_s: Saturated water content [-]
        - theta_r: Residual water content [-]
        - alpha: Van Genuchten parameter [1/m]
        - n: Van Genuchten parameter [-]
        - soil_names: 2D array of soil type names

    Examples
    --------
    >>> layers = create_soil_layers(z_grid, boundaries)
    >>> soil_types = {
    ...     0: {'name': 'topsoil', 'Ks': 1e-5, 'theta_s': 0.4,
    ...         'theta_r': 0.05, 'alpha': 5.0, 'n': 1.8},
    ...     1: {'name': 'subsoil', 'Ks': 1e-6, 'theta_s': 0.35,
    ...         'theta_r': 0.08, 'alpha': 2.0, 'n': 1.5}
    ... }
    >>> props = assign_soil_properties(layers, soil_types)
    """
    shape = layer_indices.shape
    n_layers = len(soil_types)

    # Initialize property arrays
    Ks = np.zeros(shape)
    theta_s = np.zeros(shape)
    theta_r = np.zeros(shape)
    alpha = np.zeros(shape)
    n = np.zeros(shape)
    soil_names = np.empty(shape, dtype=object)

    # Assign properties based on layer index
    for layer_idx, props in soil_types.items():
        mask = layer_indices == layer_idx

        Ks[mask] = props['Ks']
        theta_s[mask] = props['theta_s']
        theta_r[mask] = props['theta_r']
        alpha[mask] = props['alpha']
        n[mask] = props['n']
        soil_names[mask] = props.get('name', f'layer_{layer_idx}')

    return {
        'Ks': Ks,
        'theta_s': theta_s,
        'theta_r': theta_r,
        'alpha': alpha,
        'n': n,
        'soil_names': soil_names
    }


def get_standard_soils():
    """
    Get dictionary of standard soil types from literature.

    Returns
    -------
    soils : dict
        Dictionary of soil types with Van Genuchten parameters

    Examples
    --------
    >>> soils = get_standard_soils()
    >>> sandy_loam = soils['sandy_loam']
    >>> print(f"Ks = {sandy_loam['Ks']:.2e} m/s")
    """
    # Based on Carsel & Parrish (1988) and other sources
    soils = {
        'sand': {
            'name': 'Sand',
            'Ks': 8.25e-5,      # m/s
            'theta_s': 0.43,
            'theta_r': 0.045,
            'alpha': 14.5,      # 1/m
            'n': 2.68
        },
        'loamy_sand': {
            'name': 'Loamy Sand',
            'Ks': 4.05e-5,
            'theta_s': 0.41,
            'theta_r': 0.057,
            'alpha': 12.4,
            'n': 2.28
        },
        'sandy_loam': {
            'name': 'Sandy Loam (SL8)',
            'Ks': 1.23e-5,
            'theta_s': 0.41,
            'theta_r': 0.065,
            'alpha': 7.5,
            'n': 1.89
        },
        'loam': {
            'name': 'Loam',
            'Ks': 2.89e-6,
            'theta_s': 0.43,
            'theta_r': 0.078,
            'alpha': 3.6,
            'n': 1.56
        },
        'silt_loam': {
            'name': 'Silt Loam',
            'Ks': 1.25e-6,
            'theta_s': 0.45,
            'theta_r': 0.067,
            'alpha': 2.0,
            'n': 1.41
        },
        'sandy_clay_loam': {
            'name': 'Sandy Clay Loam',
            'Ks': 3.64e-6,
            'theta_s': 0.39,
            'theta_r': 0.100,
            'alpha': 5.9,
            'n': 1.48
        },
        'clay_loam': {
            'name': 'Clay Loam',
            'Ks': 7.22e-7,
            'theta_s': 0.41,
            'theta_r': 0.095,
            'alpha': 1.9,
            'n': 1.31
        },
        'silty_clay_loam': {
            'name': 'Silty Clay Loam',
            'Ks': 1.94e-7,
            'theta_s': 0.43,
            'theta_r': 0.089,
            'alpha': 1.0,
            'n': 1.23
        },
        'sandy_clay': {
            'name': 'Sandy Clay',
            'Ks': 3.33e-7,
            'theta_s': 0.38,
            'theta_r': 0.100,
            'alpha': 2.7,
            'n': 1.23
        },
        'silty_clay': {
            'name': 'Silty Clay',
            'Ks': 5.56e-8,
            'theta_s': 0.36,
            'theta_r': 0.070,
            'alpha': 0.5,
            'n': 1.09
        },
        'clay': {
            'name': 'Clay',
            'Ks': 5.56e-8,
            'theta_s': 0.38,
            'theta_r': 0.068,
            'alpha': 0.8,
            'n': 1.09
        }
    }

    return soils
