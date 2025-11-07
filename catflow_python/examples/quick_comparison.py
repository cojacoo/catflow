"""
Quick comparison of Fortran and Python CATFLOW results.

This script loads both outputs and provides initial comparison metrics.
"""

import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

# Paths
python_results = Path(__file__).parent / 'fortran_comparison' / 'python_results.npz'
fortran_results = Path(__file__).parent.parent.parent / 'model' / 'example' / 'out' / 'psi_m.out'

print("="*70)
print("FORTRAN vs PYTHON CATFLOW COMPARISON")
print("="*70)

# Load Python results
print("\n1. Loading Python results...")
py_data = np.load(python_results)
print(f"   Times: {len(py_data['times'])} snapshots")
print(f"   Time range: {py_data['times'][0]:.1f} to {py_data['times'][-1]:.1f} s")
print(f"   Psi shape: {py_data['psi'].shape}")
print(f"   Theta shape: {py_data['theta'].shape}")

# Load Fortran results
print("\n2. Loading Fortran results...")

def read_fortran_psi(filename):
    """Read Fortran psi_m.out file."""
    times = []
    psi_snapshots = []

    with open(filename, 'r') as f:
        while True:
            # Read header line
            header = f.readline()
            if not header or not header.strip():
                break

            parts = header.split()
            if len(parts) != 4:
                continue  # Skip malformed lines

            time = float(parts[0])
            hillslope_id = int(parts[1])
            n_eta = int(parts[2])
            n_xsi = int(parts[3])

            # Read matrix data (n_eta rows × n_xsi cols)
            matrix = np.zeros((n_eta, n_xsi))
            for i in range(n_eta):
                line = f.readline()
                if not line:
                    break
                row = line.split()
                # Make sure we have the right number of values
                if len(row) == n_xsi:
                    matrix[i, :] = [float(x) for x in row]
                else:
                    # Fill with NaN if row is incomplete
                    matrix[i, :len(row)] = [float(x) for x in row]

            times.append(time)
            psi_snapshots.append(matrix)

    return np.array(times), np.array(psi_snapshots)

fortran_times, fortran_psi = read_fortran_psi(fortran_results)
print(f"   Times: {len(fortran_times)} snapshots")
print(f"   Time range: {fortran_times[0]:.1f} to {fortran_times[-1]:.1f} s")
print(f"   Psi shape: {fortran_psi.shape}")

# Initial analysis
print("\n3. Data ranges:")
print(f"   Python psi:  {py_data['psi'].min():.3f} to {py_data['psi'].max():.3f} m")
print(f"   Fortran psi: {fortran_psi.min():.3f} to {fortran_psi.max():.3f} m")

# Check for Fortran no-data values
fortran_valid_mask = fortran_psi < 1000.0  # Assume values > 1000 are no-data
print(f"\n   Fortran valid cells: {fortran_valid_mask.sum()} / {fortran_psi.size}")
print(f"   Fortran no-data marker: {fortran_psi[~fortran_valid_mask].min():.1f} (appears {(~fortran_valid_mask).sum()} times)")

fortran_psi_valid = fortran_psi[fortran_valid_mask]
print(f"   Fortran psi (valid only): {fortran_psi_valid.min():.3f} to {fortran_psi_valid.max():.3f} m")

# Time comparison
print("\n4. Time stepping comparison:")
print(f"   Python dt: {np.diff(py_data['times']).min():.2f} to {np.diff(py_data['times']).max():.2f} s")
print(f"   Fortran dt: {np.diff(fortran_times).min():.2f} to {np.diff(fortran_times).max():.2f} s")

# Find common time for comparison (closest to 1 hour = 3600 s)
target_time = 3600.0
py_idx = np.argmin(np.abs(py_data['times'] - target_time))
fortran_idx = np.argmin(np.abs(fortran_times - target_time))

print(f"\n5. Comparison at t ≈ {target_time:.0f} s:")
print(f"   Python: t = {py_data['times'][py_idx]:.1f} s, snapshot {py_idx}/{len(py_data['times'])}")
print(f"   Fortran: t = {fortran_times[fortran_idx]:.1f} s, snapshot {fortran_idx}/{len(fortran_times)}")

# Plot comparison
fig, axes = plt.subplots(2, 3, figsize=(15, 8))

# Python results
im1 = axes[0, 0].imshow(py_data['psi'][py_idx], aspect='auto', cmap='viridis')
axes[0, 0].set_title(f'Python ψ @ t={py_data["times"][py_idx]:.0f}s')
axes[0, 0].set_ylabel('η index')
plt.colorbar(im1, ax=axes[0, 0], label='ψ [m]')

im2 = axes[0, 1].imshow(py_data['theta'][py_idx], aspect='auto', cmap='Blues')
axes[0, 1].set_title(f'Python θ @ t={py_data["times"][py_idx]:.0f}s')
plt.colorbar(im2, ax=axes[0, 1], label='θ [-]')

# Python time evolution (middle column)
py_psi_mean = np.mean(py_data['psi'], axis=(1, 2))
axes[0, 2].plot(py_data['times']/3600, py_psi_mean, 'b-', label='Python')
axes[0, 2].set_xlabel('Time [hours]')
axes[0, 2].set_ylabel('Mean ψ [m]')
axes[0, 2].set_title('Mean pressure head evolution')
axes[0, 2].grid(True)
axes[0, 2].legend()

# Fortran results - mask no-data values
fortran_psi_plot = fortran_psi[fortran_idx].copy()
fortran_psi_plot[fortran_psi_plot > 1000] = np.nan  # Replace no-data with NaN

im3 = axes[1, 0].imshow(fortran_psi_plot, aspect='auto', cmap='viridis')
axes[1, 0].set_title(f'Fortran ψ @ t={fortran_times[fortran_idx]:.0f}s')
axes[1, 0].set_ylabel('η index')
axes[1, 0].set_xlabel('ξ index')
plt.colorbar(im3, ax=axes[1, 0], label='ψ [m]')

# Fortran time evolution
fortran_psi_mean = []
for snapshot in fortran_psi:
    valid_data = snapshot[snapshot < 1000]
    if len(valid_data) > 0:
        fortran_psi_mean.append(np.mean(valid_data))
    else:
        fortran_psi_mean.append(np.nan)
fortran_psi_mean = np.array(fortran_psi_mean)

axes[1, 1].plot(fortran_times/3600, fortran_psi_mean, 'r-', label='Fortran')
axes[1, 1].set_xlabel('Time [hours]')
axes[1, 1].set_ylabel('Mean ψ [m]')
axes[1, 1].set_title('Mean pressure head evolution')
axes[1, 1].grid(True)
axes[1, 1].legend()

# Overlay comparison
axes[1, 2].plot(py_data['times']/3600, py_psi_mean, 'b-', label='Python', linewidth=2)
axes[1, 2].plot(fortran_times/3600, fortran_psi_mean, 'r--', label='Fortran', linewidth=2, alpha=0.7)
axes[1, 2].set_xlabel('Time [hours]')
axes[1, 2].set_ylabel('Mean ψ [m]')
axes[1, 2].set_title('Overlay comparison')
axes[1, 2].grid(True)
axes[1, 2].legend()

plt.tight_layout()
plt.savefig(Path(__file__).parent / 'fortran_comparison' / 'quick_comparison.png', dpi=150)
print(f"\n6. Plot saved to: fortran_comparison/quick_comparison.png")

# Statistical summary
print("\n" + "="*70)
print("SUMMARY")
print("="*70)
print(f"\nPython simulation:")
print(f"  - {len(py_data['times'])} timesteps over {py_data['times'][-1]/3600:.2f} hours")
print(f"  - Mesh: {py_data['psi'].shape[1]} × {py_data['psi'].shape[2]} = {py_data['psi'][0].size} nodes")
print(f"  - Pressure head range: {py_data['psi'].min():.3f} to {py_data['psi'].max():.3f} m")

print(f"\nFortran simulation:")
print(f"  - {len(fortran_times)} timesteps over {fortran_times[-1]/3600:.2f} hours")
print(f"  - Mesh: {fortran_psi.shape[1]} × {fortran_psi.shape[2]} nodes")
print(f"  - Pressure head range (valid): {fortran_psi_valid.min():.3f} to {fortran_psi_valid.max():.3f} m")
print(f"  - No-data cells: {(~fortran_valid_mask).sum()} ({100*(~fortran_valid_mask).sum()/fortran_valid_mask.size:.1f}%)")

print("\n" + "="*70)
