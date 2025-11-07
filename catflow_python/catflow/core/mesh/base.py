"""
Abstract base class for computational meshes.
"""

from abc import ABC, abstractmethod
import numpy as np


class Mesh(ABC):
    """
    Abstract base class for computational meshes.

    Provides interface for all mesh types used in CATFLOW.
    Concrete implementations must provide coordinate systems,
    metric tensors, and connectivity information.
    """

    @abstractmethod
    def get_node_coordinates(self):
        """
        Get node coordinates in physical space.

        Returns
        -------
        x : np.ndarray
            X-coordinates of nodes
        y : np.ndarray
            Y-coordinates of nodes
        """
        pass

    @abstractmethod
    def get_metric_coefficients(self):
        """
        Get metric tensor coefficients for curvilinear coordinates.

        Returns
        -------
        dict
            Dictionary containing metric coefficients:
            - 'g_xsi': Scale factor in xsi direction
            - 'g_eta': Scale factor in eta direction
            - 'jacobian': Jacobian of transformation (optional)
        """
        pass

    @abstractmethod
    def get_cell_volumes(self):
        """
        Get volumes (or areas in 2D) of computational cells.

        Returns
        -------
        volumes : np.ndarray
            Cell volumes/areas
        """
        pass

    @property
    @abstractmethod
    def n_nodes(self):
        """Total number of nodes in the mesh."""
        pass

    @property
    @abstractmethod
    def shape(self):
        """Shape of the mesh (n_eta, n_xsi) for structured grids."""
        pass

    def node_index(self, i, j):
        """
        Convert 2D indices to flat index.

        Parameters
        ----------
        i : int
            Index in eta direction
        j : int
            Index in xsi direction

        Returns
        -------
        idx : int
            Flat index
        """
        n_eta, n_xsi = self.shape
        return i * n_xsi + j

    def indices_2d(self, idx):
        """
        Convert flat index to 2D indices.

        Parameters
        ----------
        idx : int
            Flat index

        Returns
        -------
        i : int
            Index in eta direction
        j : int
            Index in xsi direction
        """
        n_eta, n_xsi = self.shape
        i = idx // n_xsi
        j = idx % n_xsi
        return i, j
