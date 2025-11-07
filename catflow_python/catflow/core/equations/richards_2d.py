"""
2D Richards equation in curvilinear coordinates.

Implements the assembly of the discretized Richards equation for
variably saturated flow in boundary-fitted coordinates.
"""

import numpy as np
from scipy.sparse import lil_matrix


class Richards2D:
    """
    2D Richards equation assembler for curvilinear coordinates.

    The Richards equation in conservative form:
        ∂θ/∂t = ∇·[K(θ)∇(ψ+z)]

    In curvilinear orthogonal coordinates (ξ, η):
        C ∂ψ/∂t = (1/J)[∂/∂ξ(J/g_ξ² K ∂ψ/∂ξ) + ∂/∂η(J/g_η² K ∂ψ/∂η)] + ∂K/∂z

    where:
        C = dθ/dψ (specific moisture capacity)
        J = g_ξ * g_η (Jacobian for orthogonal coordinates)
        g_ξ, g_η are metric coefficients

    This class assembles the discretized linear system for each time step
    using the method of lines (spatial discretization followed by time
    discretization).

    Parameters
    ----------
    mesh : Mesh
        Computational mesh with curvilinear coordinates
    soil_model : SoilHydraulicModel
        Soil hydraulic model (e.g., Van Genuchten)
    boundary_conditions : dict
        Boundary condition specifications
    """

    def __init__(self, mesh, soil_model, boundary_conditions=None):
        """Initialize Richards equation assembler."""
        self.mesh = mesh
        self.soil = soil_model
        self.bc = boundary_conditions or {}

        # Get mesh properties
        self.n_eta, self.n_xsi = mesh.shape
        self.n_nodes = mesh.n_nodes

        # Get metric coefficients
        metrics = mesh.get_metric_coefficients()
        self.g_xsi = metrics['g_xsi']
        self.g_eta = metrics['g_eta']

    def assemble_system(self, psi, dt, soil_params, bc_override=None):
        """
        Assemble the linearized system A·ψ^(n+1) = b.

        Uses modified Picard iteration (Celia et al., 1990) for better
        mass conservation.

        Parameters
        ----------
        psi : np.ndarray
            Current pressure head estimate, shape (n_eta, n_xsi) [m]
        dt : float
            Time step size [s]
        soil_params : dict
            Soil hydraulic parameters
        bc_override : dict, optional
            Override boundary conditions for this timestep

        Returns
        -------
        A : scipy.sparse.csr_matrix
            System matrix, shape (n_nodes, n_nodes)
        b : np.ndarray
            Right-hand side vector, shape (n_nodes,)
        """
        # Get current state
        theta = self.soil.theta_from_psi(psi, soil_params)
        K = self.soil.K_from_theta(theta, soil_params)
        C = self.soil.capacity(psi, soil_params)

        # Initialize sparse matrix (LIL format for assembly)
        A = lil_matrix((self.n_nodes, self.n_nodes))
        b = np.zeros(self.n_nodes)

        # Grid spacings (assuming uniform for now)
        dxsi = np.mean(np.diff(self.mesh.xsi))
        deta = np.mean(np.diff(self.mesh.eta))

        # Assemble interior nodes
        for i in range(1, self.n_eta - 1):
            for j in range(1, self.n_xsi - 1):
                idx = self.mesh.node_index(i, j)

                # Assemble this node's equation
                self._assemble_interior_node(
                    A, b, idx, i, j,
                    psi, K, C, dt, dxsi, deta, soil_params
                )

        # Apply boundary conditions (use override if provided)
        bc_to_use = bc_override if bc_override is not None else self.bc
        self._apply_boundary_conditions(A, b, psi, K, soil_params, bc_to_use)

        # Convert to CSR format for efficient solving
        return A.tocsr(), b

    def _assemble_interior_node(self, A, b, idx, i, j,
                                psi, K, C, dt, dxsi, deta, soil_params):
        """
        Assemble equations for a single interior node.

        Uses finite differences with harmonic averaging of hydraulic
        conductivity between nodes.

        Parameters
        ----------
        A : scipy.sparse.lil_matrix
            System matrix to fill
        b : np.ndarray
            RHS vector to fill
        idx : int
            Flat index of current node
        i, j : int
            2D indices of current node
        psi : np.ndarray
            Pressure head field
        K : np.ndarray
            Hydraulic conductivity field
        C : np.ndarray
            Specific moisture capacity field
        dt : float
            Time step
        dxsi, deta : float
            Grid spacings
        soil_params : dict
            Soil parameters
        """
        # Hydraulic conductivity at faces (harmonic mean)
        K_e = self._harmonic_mean(K[i, j], K[i, j+1])  # East face
        K_w = self._harmonic_mean(K[i, j], K[i, j-1])  # West face
        K_n = self._harmonic_mean(K[i, j], K[i+1, j])  # North face
        K_s = self._harmonic_mean(K[i, j], K[i-1, j])  # South face

        # Metric coefficients at current node
        g_xi = self.g_xsi[i, j]
        g_et = self.g_eta[i, j]

        # Compute flux coefficients with metric tensors
        # In curvilinear coords: (1/J) * ∂/∂ξ(J/g_ξ² K ∂ψ/∂ξ)
        # Simplified for orthogonal coords: (1/(g_ξ*g_η)) * ∂/∂ξ(g_η/g_ξ K ∂ψ/∂ξ)

        # East-West (ξ direction)
        coef_e = (K_e * g_et / g_xi) / dxsi**2
        coef_w = (K_w * g_et / g_xi) / dxsi**2

        # North-South (η direction)
        coef_n = (K_n * g_xi / g_et) / deta**2
        coef_s = (K_s * g_xi / g_et) / deta**2

        # Diagonal coefficient (time derivative + spatial terms)
        coef_center = -(coef_e + coef_w + coef_n + coef_s) - C[i, j] / dt

        # Fill matrix (5-point stencil)
        A[idx, idx] = coef_center                              # Center
        A[idx, idx + 1] = coef_e                               # East
        A[idx, idx - 1] = coef_w                               # West
        A[idx, idx + self.n_xsi] = coef_n                      # North
        A[idx, idx - self.n_xsi] = coef_s                      # South

        # Right-hand side
        # Time derivative term: -C * ψ^n / dt
        b[idx] = -C[i, j] * psi[i, j] / dt

        # Gravity term: ∂K/∂z
        # Approximate: K_n - K_s
        dK_dz = (K_n - K_s) / (2 * deta * g_et)
        b[idx] += dK_dz

    def _apply_boundary_conditions(self, A, b, psi, K, soil_params, bc):
        """
        Apply boundary conditions.

        Supports both static (dict) and dynamic (array) boundary conditions.

        Parameters
        ----------
        A : scipy.sparse.lil_matrix
            System matrix
        b : np.ndarray
            RHS vector
        psi : np.ndarray
            Current pressure head
        K : np.ndarray
            Hydraulic conductivity
        soil_params : dict
            Soil parameters
        bc : dict
            Boundary conditions (can contain arrays for dynamic BC)
        """
        # Top boundary (i=0)
        top_bc = bc.get('top', {'type': 'dirichlet', 'value': 0.0})

        # Check if top_bc is an array (dynamic flux) or dict (static)
        if isinstance(top_bc, np.ndarray):
            # Dynamic flux BC (Neumann) - spatially variable
            flux_array = top_bc
            for j in range(self.n_xsi):
                idx = self.mesh.node_index(0, j)
                flux = flux_array[j]  # m/s (+ = into soil, - = out)

                # For Neumann BC, modify the equation for top node
                # Keep interior discretization but add flux term to RHS
                # Note: This is simplified - proper implementation would
                # modify the stencil near boundary
                b[idx] += flux

        elif isinstance(top_bc, dict):
            # Static BC (old format)
            bc_type = top_bc.get('type', 'dirichlet')

            if bc_type == 'dirichlet':
                # Fixed head
                bc_value = top_bc.get('value', 0.0)
                for j in range(self.n_xsi):
                    idx = self.mesh.node_index(0, j)
                    A[idx, :] = 0.0
                    A[idx, idx] = 1.0
                    b[idx] = bc_value

            elif bc_type == 'neumann':
                # Fixed flux (uniform)
                flux = top_bc.get('value', 0.0)
                for j in range(self.n_xsi):
                    idx = self.mesh.node_index(0, j)
                    b[idx] += flux

        # Bottom boundary (i=n_eta-1)
        bottom_bc = bc.get('bottom', {'type': 'dirichlet', 'value': 0.0})

        if isinstance(bottom_bc, dict):
            bc_type = bottom_bc.get('type', 'dirichlet')
            bc_value = bottom_bc.get('value', 0.0)

            if bc_type == 'dirichlet':
                for j in range(self.n_xsi):
                    idx = self.mesh.node_index(self.n_eta - 1, j)
                    A[idx, :] = 0.0
                    A[idx, idx] = 1.0
                    b[idx] = bc_value

        # Left boundary (j=0): No-flow (symmetric condition)
        for i in range(1, self.n_eta - 1):
            idx = self.mesh.node_index(i, 0)
            # Set ψ[i,0] = ψ[i,1] (no gradient)
            A[idx, :] = 0.0
            A[idx, idx] = 1.0
            A[idx, idx + 1] = -1.0
            b[idx] = 0.0

        # Right boundary (j=n_xsi-1): No-flow
        for i in range(1, self.n_eta - 1):
            idx = self.mesh.node_index(i, self.n_xsi - 1)
            A[idx, :] = 0.0
            A[idx, idx] = 1.0
            A[idx, idx - 1] = -1.0
            b[idx] = 0.0

    @staticmethod
    def _harmonic_mean(a, b):
        """
        Compute harmonic mean of two values.

        Used for averaging hydraulic conductivity between nodes.

        Parameters
        ----------
        a, b : float
            Values to average

        Returns
        -------
        mean : float
            Harmonic mean
        """
        if a <= 0 or b <= 0:
            return 0.0
        return 2.0 * a * b / (a + b)
