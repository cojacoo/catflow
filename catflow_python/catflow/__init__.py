"""
CATFLOW - Python Implementation
================================

A modular, physically-based distributed hydrological model for simulating
water and solute dynamics in catchments.

This is a complete refactoring of the original Fortran CATFLOW model with
a focus on modularity, extensibility, and modern Python practices.
"""

__version__ = "0.1.0"
__author__ = "CATFLOW Development Team"

from catflow.core.model import CatflowModel

__all__ = ["CatflowModel"]
