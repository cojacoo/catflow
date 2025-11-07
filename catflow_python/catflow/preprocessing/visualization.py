"""
Visualization tools for CATFLOW preprocessing.

Functions for plotting hillslopes, soil layers, and macropores.
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon
from matplotlib.collections import PatchCollection


def plot_hillslope(profile, simgrid=None, title="Hillslope Profile"):
    """
    Plot hillslope profile and optionally the simulation grid.

    Parameters
    ----------
    profile : dict
        Hillslope profile with 'x', 'z', 'width' keys
    simgrid : dict, optional
        Simulation grid to overlay
    title : str
        Plot title

    Returns
    -------
    fig, ax : matplotlib figure and axes
    """
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))

    # Left: Profile view
    ax = axes[0]
    ax.plot(profile['x'], profile['z'], 'k-', linewidth=2, label='Surface')

    if simgrid is not None:
        # Plot grid
        x = simgrid['x']
        z = simgrid['z']

        # Bottom boundary
        ax.plot(x, z[-1, :], 'k--', linewidth=1, alpha=0.7, label='Bottom')

        # Vertical grid lines (subsample for clarity)
        step = max(1, len(x) // 20)
        for i in range(0, len(x), step):
            ax.plot([x[i], x[i]], [z[0, i], z[-1, i]],
                   'gray', linewidth=0.5, alpha=0.3)

        # Horizontal grid lines
        nz = z.shape[0]
        step = max(1, nz // 10)
        for j in range(0, nz, step):
            ax.plot(x, z[j, :], 'gray', linewidth=0.5, alpha=0.3)

    ax.set_xlabel('Horizontal Distance [m]')
    ax.set_ylabel('Elevation [m]')
    ax.set_title('Profile View')
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.set_aspect('equal')

    # Right: Width profile
    ax = axes[1]
    ax.plot(profile['x'], profile['width'], 'b-', linewidth=2)
    ax.set_xlabel('Horizontal Distance [m]')
    ax.set_ylabel('Hillslope Width [m]')
    ax.set_title('Width Profile')
    ax.grid(True, alpha=0.3)

    plt.suptitle(title, fontsize=14, fontweight='bold')
    plt.tight_layout()

    return fig, axes


def plot_macropores(simgrid, macropores, title="Macropore Distribution"):
    """
    Plot macropore distribution on hillslope.

    Parameters
    ----------
    simgrid : dict
        Simulation grid
    macropores : dict
        Macropore simulation results
    title : str
        Plot title

    Returns
    -------
    fig, ax : matplotlib figure and axes
    """
    fig, ax = plt.subplots(figsize=(12, 6))

    x = simgrid['x']
    z = simgrid['z']
    multiplier = macropores['multiplier']

    # Create 2D coordinate arrays for proper hillslope projection
    nz, nx = z.shape
    X = np.tile(x, (nz, 1))
    Z = z

    # Plot using pcolormesh for proper alignment
    im = ax.pcolormesh(X, Z, multiplier, cmap='YlOrRd',
                      vmin=1.0, vmax=2.0, shading='auto')

    # Overlay macropore paths
    for path in macropores['positions']:
        path = np.array(path)
        rows = path[:, 0]
        cols = path[:, 1]

        # Convert to actual coordinates
        x_path = x[cols]
        z_path = z[rows, cols]

        ax.plot(x_path, z_path, 'k-', linewidth=1.5, alpha=0.7)

    # Colorbar
    cbar = plt.colorbar(im, ax=ax, label='Conductivity Multiplier')
    cbar.set_label('Conductivity Multiplier', rotation=270, labelpad=20)

    # Plot boundaries
    ax.plot(x, z[0, :], 'k-', linewidth=2, label='Surface')
    ax.plot(x, z[-1, :], 'k--', linewidth=2, label='Bottom')

    ax.set_xlabel('Horizontal Distance [m]')
    ax.set_ylabel('Elevation [m]')
    ax.set_title(f'{title}\n({macropores["n_pores"]} macropores simulated)')
    ax.legend(loc='upper right')
    ax.grid(True, alpha=0.3)

    plt.tight_layout()

    return fig, ax


def plot_soil_layers(simgrid, layer_indices, soil_properties=None,
                    title="Soil Layers"):
    """
    Plot soil layer distribution on hillslope.

    Parameters
    ----------
    simgrid : dict
        Simulation grid
    layer_indices : ndarray
        2D array with layer indices
    soil_properties : dict, optional
        Soil properties from assign_soil_properties
    title : str
        Plot title

    Returns
    -------
    fig, axes : matplotlib figure and axes
    """
    x = simgrid['x']
    z = simgrid['z']

    n_layers = len(np.unique(layer_indices))

    if soil_properties is not None:
        # Plot multiple properties
        fig, axes = plt.subplots(2, 3, figsize=(16, 8))
        axes = axes.flatten()

        properties = [
            ('Layer Index', layer_indices, 'tab20'),
            ('Ks [m/s]', soil_properties['Ks'], 'viridis'),
            ('θs [-]', soil_properties['theta_s'], 'Blues'),
            ('θr [-]', soil_properties['theta_r'], 'Greens'),
            ('α [1/m]', soil_properties['alpha'], 'plasma'),
            ('n [-]', soil_properties['n'], 'YlOrRd')
        ]

        # Create 2D coordinate arrays for pcolormesh
        nz, nx = z.shape
        X = np.tile(x, (nz, 1))  # Repeat x for each vertical layer
        Z = z  # Already in correct shape (nz, nx)

        for idx, (name, data, cmap) in enumerate(properties):
            ax = axes[idx]

            if name == 'Ks [m/s]':
                # Log scale for Ks
                data_plot = np.log10(data + 1e-20)  # Avoid log(0)
                im = ax.pcolormesh(X, Z, data_plot, cmap=cmap,
                                  shading='auto')
                cbar = plt.colorbar(im, ax=ax)
                cbar.set_label('log₁₀(Ks) [m/s]', rotation=270, labelpad=15)
            else:
                im = ax.pcolormesh(X, Z, data, cmap=cmap,
                                  shading='auto')
                cbar = plt.colorbar(im, ax=ax)
                cbar.set_label(name, rotation=270, labelpad=15)

            # Boundaries
            ax.plot(x, z[0, :], 'k-', linewidth=1)
            ax.plot(x, z[-1, :], 'k--', linewidth=1)

            ax.set_xlabel('Distance [m]')
            ax.set_ylabel('Elevation [m]')
            ax.set_title(name)

        plt.suptitle(title, fontsize=14, fontweight='bold')

    else:
        # Just plot layer indices
        fig, ax = plt.subplots(figsize=(12, 6))

        # Create 2D coordinate arrays
        nz, nx = z.shape
        X = np.tile(x, (nz, 1))
        Z = z

        im = ax.pcolormesh(X, Z, layer_indices, cmap='tab20',
                          vmin=0, vmax=n_layers-1, shading='auto')

        cbar = plt.colorbar(im, ax=ax, ticks=range(n_layers))
        cbar.set_label('Layer Index', rotation=270, labelpad=15)

        # Boundaries
        ax.plot(x, z[0, :], 'k-', linewidth=2, label='Surface')
        ax.plot(x, z[-1, :], 'k--', linewidth=2, label='Bottom')

        ax.set_xlabel('Horizontal Distance [m]')
        ax.set_ylabel('Elevation [m]')
        ax.set_title(title)
        ax.legend()
        ax.grid(True, alpha=0.3)

        axes = ax

    plt.tight_layout()

    return fig, axes


def plot_combined_overview(profile, simgrid, layer_indices, macropores,
                           soil_properties=None):
    """
    Create comprehensive overview plot with all components.

    Parameters
    ----------
    profile : dict
        Hillslope profile
    simgrid : dict
        Simulation grid
    layer_indices : ndarray
        Soil layer indices
    macropores : dict
        Macropore simulation results
    soil_properties : dict, optional
        Soil properties

    Returns
    -------
    fig : matplotlib figure
    """
    fig = plt.figure(figsize=(16, 10))
    gs = fig.add_gridspec(3, 2, hspace=0.3, wspace=0.3)

    x = simgrid['x']
    z = simgrid['z']

    # Create 2D coordinate arrays for proper hillslope projection
    nz, nx = z.shape
    X = np.tile(x, (nz, 1))
    Z = z

    # 1. Hillslope profile
    ax1 = fig.add_subplot(gs[0, :])
    ax1.plot(profile['x'], profile['z'], 'k-', linewidth=2, label='Surface')
    ax1.plot(x, z[-1, :], 'k--', linewidth=1, label='Bottom')
    ax1.fill_between(x, z[0, :], z[-1, :], alpha=0.2, color='brown')
    ax1.set_xlabel('Horizontal Distance [m]')
    ax1.set_ylabel('Elevation [m]')
    ax1.set_title('Hillslope Profile', fontweight='bold')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    ax1.set_aspect('equal')

    # 2. Soil layers
    ax2 = fig.add_subplot(gs[1, 0])
    n_layers = len(np.unique(layer_indices))
    im2 = ax2.pcolormesh(X, Z, layer_indices, cmap='tab20',
                        vmin=0, vmax=n_layers-1, shading='auto')
    ax2.plot(x, z[0, :], 'k-', linewidth=1)
    ax2.set_xlabel('Distance [m]')
    ax2.set_ylabel('Elevation [m]')
    ax2.set_title('Soil Layers', fontweight='bold')
    cbar2 = plt.colorbar(im2, ax=ax2, ticks=range(n_layers))
    cbar2.set_label('Layer', rotation=270, labelpad=15)

    # 3. Macropores
    ax3 = fig.add_subplot(gs[1, 1])
    multiplier = macropores['multiplier']
    im3 = ax3.pcolormesh(X, Z, multiplier, cmap='YlOrRd',
                        vmin=1.0, vmax=2.0, shading='auto')
    ax3.plot(x, z[0, :], 'k-', linewidth=1)
    ax3.set_xlabel('Distance [m]')
    ax3.set_ylabel('Elevation [m]')
    ax3.set_title(f'Macropores (n={macropores["n_pores"]})',
                 fontweight='bold')
    cbar3 = plt.colorbar(im3, ax=ax3)
    cbar3.set_label('K multiplier', rotation=270, labelpad=15)

    # 4. Hydraulic conductivity (if available)
    if soil_properties is not None:
        ax4 = fig.add_subplot(gs[2, 0])
        Ks_log = np.log10(soil_properties['Ks'] + 1e-20)
        im4 = ax4.pcolormesh(X, Z, Ks_log, cmap='viridis', shading='auto')
        ax4.plot(x, z[0, :], 'k-', linewidth=1)
        ax4.set_xlabel('Distance [m]')
        ax4.set_ylabel('Elevation [m]')
        ax4.set_title('Hydraulic Conductivity', fontweight='bold')
        cbar4 = plt.colorbar(im4, ax=ax4)
        cbar4.set_label('log₁₀(Ks) [m/s]', rotation=270, labelpad=15)

        # 5. Water retention parameters
        ax5 = fig.add_subplot(gs[2, 1])
        theta_diff = soil_properties['theta_s'] - soil_properties['theta_r']
        im5 = ax5.pcolormesh(X, Z, theta_diff, cmap='Blues', shading='auto')
        ax5.plot(x, z[0, :], 'k-', linewidth=1)
        ax5.set_xlabel('Distance [m]')
        ax5.set_ylabel('Elevation [m]')
        ax5.set_title('Available Water Capacity (θs - θr)',
                     fontweight='bold')
        cbar5 = plt.colorbar(im5, ax=ax5)
        cbar5.set_label('θs - θr [-]', rotation=270, labelpad=15)

    plt.suptitle('CATFLOW Hillslope Setup - Overview',
                fontsize=16, fontweight='bold')

    return fig
