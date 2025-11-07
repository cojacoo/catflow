"""
Input/Output utilities for reading Fortran CATFLOW files.

These functions allow Python to read output from the Fortran CATFLOW
model for comparison purposes.
"""

import numpy as np
import pandas as pd
from pathlib import Path


def read_fortran_matrix_output(filename, variable_name='psi'):
    """
    Read Fortran CATFLOW matrix output file.

    Fortran CATFLOW outputs have format:
    time hillslope_id n_eta n_xsi
    [matrix data, n_eta rows × n_xsi columns]

    Parameters
    ----------
    filename : str or Path
        Path to Fortran output file (e.g., 'psi.out', 'theta.out')
    variable_name : str
        Name of variable for metadata

    Returns
    -------
    results : dict
        Dictionary containing:
        - 'times': list of timesteps
        - 'data': list of 2D arrays (one per timestep)
        - 'hillslope_ids': list of hillslope IDs
        - 'shape': tuple (n_eta, n_xsi)

    Examples
    --------
    >>> results = read_fortran_matrix_output('psi.out')
    >>> psi_t0 = results['data'][0]  # First timestep
    >>> times = results['times']
    """
    filename = Path(filename)

    if not filename.exists():
        raise FileNotFoundError(f"File not found: {filename}")

    times = []
    data = []
    hillslope_ids = []
    shape = None

    with open(filename, 'r') as f:
        while True:
            # Read header line
            header = f.readline()
            if not header:
                break  # End of file

            # Parse header
            parts = header.split()
            if len(parts) < 4:
                continue  # Skip invalid lines

            time = float(parts[0])
            hillslope_id = int(parts[1])
            n_eta = int(parts[2])
            n_xsi = int(parts[3])

            if shape is None:
                shape = (n_eta, n_xsi)
            elif shape != (n_eta, n_xsi):
                raise ValueError(
                    f"Inconsistent dimensions: expected {shape}, got {(n_eta, n_xsi)}"
                )

            # Read matrix data
            matrix = []
            for _ in range(n_eta):
                row_line = f.readline()
                if not row_line:
                    raise ValueError(f"Unexpected end of file reading matrix at time {time}")

                # Parse row (space-separated values)
                row_values = list(map(float, row_line.split()))
                if len(row_values) != n_xsi:
                    raise ValueError(
                        f"Expected {n_xsi} values, got {len(row_values)} at time {time}"
                    )
                matrix.append(row_values)

            # Store results
            times.append(time)
            data.append(np.array(matrix))
            hillslope_ids.append(hillslope_id)

    return {
        'times': np.array(times),
        'data': data,
        'hillslope_ids': np.array(hillslope_ids),
        'shape': shape,
        'variable': variable_name,
        'filename': str(filename)
    }


def read_fortran_balance(filename):
    """
    Read Fortran CATFLOW water balance file (bilanz.csv).

    Format is semicolon-separated CSV with German decimal commas.

    Parameters
    ----------
    filename : str or Path
        Path to bilanz.csv file

    Returns
    -------
    balance : pd.DataFrame
        Water balance data with columns:
        - Zeit (time in seconds)
        - Zeitschritt (timestep)
        - totaleBil (total balance)
        - Auffeuchtung (storage change)
        - And many others...

    Examples
    --------
    >>> balance = read_fortran_balance('bilanz.csv')
    >>> total_balance = balance['totaleBil']
    """
    filename = Path(filename)

    if not filename.exists():
        raise FileNotFoundError(f"File not found: {filename}")

    # Read German-formatted CSV
    try:
        balance = pd.read_csv(
            filename,
            sep=';',
            decimal=',',
            encoding='latin1'  # German characters
        )
    except Exception as e:
        raise ValueError(f"Error reading balance file: {e}")

    return balance


def read_fortran_geometry(filename):
    """
    Read Fortran CATFLOW geometry file (.geo).

    This is more complex - geometry file contains:
    - Header with dimensions
    - Eta discretization
    - Xsi discretization
    - Node-by-node data (coordinates, metrics, angles)

    Parameters
    ----------
    filename : str or Path
        Path to .geo file

    Returns
    -------
    geometry : dict
        Dictionary with mesh geometry data

    Examples
    --------
    >>> geom = read_fortran_geometry('hang1.geo')
    >>> x = geom['x']
    >>> y = geom['y']
    """
    # TODO: Implement full .geo file parser
    # This is more complex and depends on exact format
    raise NotImplementedError(
        "Geometry file reader not yet implemented. "
        "For now, use Python mesh generation and compare outputs only."
    )


def compare_with_python_results(fortran_results, python_results, variable='psi'):
    """
    Helper function to align and compare Fortran and Python results.

    Handles potential differences in:
    - Time sampling
    - Array orientations
    - Mesh numbering

    Parameters
    ----------
    fortran_results : dict
        From read_fortran_matrix_output()
    python_results : dict
        From CatflowModel.results

    Returns
    -------
    comparison : dict
        Aligned data for comparison
    """
    # Get time arrays
    fortran_times = fortran_results['times']
    python_times = np.array(python_results['times'])

    # Find common times (within tolerance)
    tolerance = 1.0  # 1 second tolerance
    common_indices_fortran = []
    common_indices_python = []

    for i, ft in enumerate(fortran_times):
        # Find closest Python time
        time_diffs = np.abs(python_times - ft)
        min_idx = np.argmin(time_diffs)

        if time_diffs[min_idx] < tolerance:
            common_indices_fortran.append(i)
            common_indices_python.append(min_idx)

    if len(common_indices_fortran) == 0:
        raise ValueError(
            "No common times found between Fortran and Python results. "
            f"Fortran times: {fortran_times[:5]}..., "
            f"Python times: {python_times[:5]}..."
        )

    # Extract data at common times
    fortran_data = [fortran_results['data'][i] for i in common_indices_fortran]
    python_data = [python_results[variable][i] for i in common_indices_python]

    return {
        'times': [fortran_times[i] for i in common_indices_fortran],
        'fortran_data': fortran_data,
        'python_data': python_data,
        'n_common': len(common_indices_fortran),
        'variable': variable
    }


def write_fortran_initial_conditions(filename, psi):
    """
    Write initial conditions in Fortran CATFLOW format.

    Parameters
    ----------
    filename : str or Path
        Output filename (e.g., 'hang1.ini')
    psi : np.ndarray
        Initial pressure head, shape (n_eta, n_xsi)

    Examples
    --------
    >>> psi_init = -1.0 * np.ones((15, 20))
    >>> write_fortran_initial_conditions('hang1.ini', psi_init)
    """
    filename = Path(filename)

    with open(filename, 'w') as f:
        n_eta, n_xsi = psi.shape

        # Write each row
        for i in range(n_eta):
            row_str = ' '.join(f'{val:12.6f}' for val in psi[i, :])
            f.write(row_str + '\n')

    print(f"Wrote initial conditions to {filename}")


def write_fortran_soil_file(filename, soil_params, soil_name='loamy_sand'):
    """
    Write soil parameters in Fortran CATFLOW format (.bod file).

    Parameters
    ----------
    filename : str or Path
        Output filename (e.g., 'soil.bod')
    soil_params : dict
        Van Genuchten parameters
    soil_name : str
        Name for the soil type

    Examples
    --------
    >>> params = {'theta_s': 0.41, 'theta_r': 0.057, 'alpha': 7.5, 'n': 1.89, 'Ks': 1.23e-5}
    >>> write_fortran_soil_file('soil.bod', params)
    """
    filename = Path(filename)

    # Fortran soil file format (simplified)
    # Full format is complex, this is a minimal version
    with open(filename, 'w') as f:
        f.write(f"1  {soil_name}\n")  # 1 soil type
        f.write(f"{soil_params['theta_s']:.4f}  ")  # theta_s
        f.write(f"{soil_params['theta_r']:.4f}  ")  # theta_r
        f.write(f"{soil_params['alpha']:.4f}  ")    # alpha [1/m]
        f.write(f"{soil_params['n']:.4f}  ")        # n
        f.write(f"{soil_params['Ks']:.6e}  ")       # Ks [m/s]
        f.write(f"1\n")                              # Model type (1=VG)

    print(f"Wrote soil parameters to {filename}")


if __name__ == '__main__':
    # Example usage and testing
    print("Fortran I/O utilities for CATFLOW comparison")
    print("=" * 60)
    print("\nExample 1: Read matrix output")
    print(">>> results = read_fortran_matrix_output('psi.out')")
    print(">>> print(f'Found {len(results[\"times\"])} timesteps')")
    print(">>> psi_final = results['data'][-1]")

    print("\nExample 2: Read water balance")
    print(">>> balance = read_fortran_balance('bilanz.csv')")
    print(">>> total_balance = balance['totaleBil']")

    print("\nExample 3: Write initial conditions for Fortran")
    print(">>> psi_init = -1.0 * np.ones((15, 20))")
    print(">>> write_fortran_initial_conditions('hang1.ini', psi_init)")

    print("\n" + "=" * 60)
    print("See docstrings for full API documentation")
