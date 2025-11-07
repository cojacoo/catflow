"""
CATFLOW preprocessing tools.

Python implementation of the RCatflow preprocessing package for
creating hillslope geometries, soil layers, and macropore structures.
"""

from .hillslope import (
    make_simgrid,
    create_hillslope_profile,
    discretize_for_catflow
)
from .macropores import (
    simulate_macropores,
    map_macropores_to_coarse_grid
)
from .soil_layers import (
    create_soil_layers,
    assign_soil_properties,
    get_standard_soils
)
from .visualization import (
    plot_hillslope,
    plot_macropores,
    plot_soil_layers,
    plot_combined_overview
)

__all__ = [
    'make_simgrid',
    'create_hillslope_profile',
    'discretize_for_catflow',
    'simulate_macropores',
    'map_macropores_to_coarse_grid',
    'create_soil_layers',
    'assign_soil_properties',
    'get_standard_soils',
    'plot_hillslope',
    'plot_macropores',
    'plot_soil_layers',
    'plot_combined_overview',
]
