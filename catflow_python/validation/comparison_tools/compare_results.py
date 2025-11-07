"""
Compare Fortran and Python CATFLOW results.

Provides comprehensive statistical and visual comparison of model outputs.
"""

import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import sys

# Add parent to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from validation.comparison_tools.fortran_io import (
    read_fortran_matrix_output,
    read_fortran_balance,
    compare_with_python_results
)


def compute_statistics(fortran_data, python_data):
    """
    Compute comprehensive comparison statistics.

    Parameters
    ----------
    fortran_data : np.ndarray
        Fortran model output
    python_data : np.ndarray
        Python model output

    Returns
    -------
    stats : dict
        Dictionary of statistical metrics
    """
    # Flatten arrays for overall statistics
    f_flat = fortran_data.flatten()
    p_flat = python_data.flatten()

    # Compute differences
    diff = p_flat - f_flat
    abs_diff = np.abs(diff)

    stats = {
        # Central tendency
        'mean_error': np.mean(diff),
        'median_error': np.median(diff),

        # Spread
        'std_error': np.std(diff),
        'rmse': np.sqrt(np.mean(diff**2)),
        'mae': np.mean(abs_diff),

        # Extremes
        'max_error': np.max(abs_diff),
        'min_error': np.min(abs_diff),
        'max_positive_error': np.max(diff),
        'max_negative_error': np.min(diff),

        # Relative metrics
        'relative_rmse': np.sqrt(np.mean(diff**2)) / (np.std(f_flat) + 1e-10),
        'max_relative_error': np.max(abs_diff) / (np.max(np.abs(f_flat)) + 1e-10),

        # Correlation
        'correlation': np.corrcoef(f_flat, p_flat)[0, 1],
        'r_squared': np.corrcoef(f_flat, p_flat)[0, 1]**2,

        # Percentiles
        'p50_error': np.percentile(abs_diff, 50),
        'p90_error': np.percentile(abs_diff, 90),
        'p95_error': np.percentile(abs_diff, 95),
        'p99_error': np.percentile(abs_diff, 99),

        # Sample size
        'n_nodes': len(f_flat),
    }

    return stats


def print_statistics_table(stats, variable='psi', units='m'):
    """
    Print formatted statistics table.

    Parameters
    ----------
    stats : dict
        Statistics from compute_statistics()
    variable : str
        Variable name
    units : str
        Units for display
    """
    print(f"\n{'='*70}")
    print(f"COMPARISON STATISTICS: {variable}")
    print(f"{'='*70}")

    print(f"\nCentral Tendency:")
    print(f"  Mean error:           {stats['mean_error']:>12.6f} {units}")
    print(f"  Median error:         {stats['median_error']:>12.6f} {units}")

    print(f"\nSpread:")
    print(f"  Std dev of error:     {stats['std_error']:>12.6f} {units}")
    print(f"  RMSE:                 {stats['rmse']:>12.6f} {units}")
    print(f"  MAE:                  {stats['mae']:>12.6f} {units}")

    print(f"\nExtremes:")
    print(f"  Max absolute error:   {stats['max_error']:>12.6f} {units}")
    print(f"  Max positive error:   {stats['max_positive_error']:>12.6f} {units}")
    print(f"  Max negative error:   {stats['max_negative_error']:>12.6f} {units}")

    print(f"\nPercentiles:")
    print(f"  50th percentile:      {stats['p50_error']:>12.6f} {units}")
    print(f"  90th percentile:      {stats['p90_error']:>12.6f} {units}")
    print(f"  95th percentile:      {stats['p95_error']:>12.6f} {units}")
    print(f"  99th percentile:      {stats['p99_error']:>12.6f} {units}")

    print(f"\nRelative Metrics:")
    print(f"  Relative RMSE:        {stats['relative_rmse']:>12.6f} [-]")
    print(f"  Max relative error:   {stats['max_relative_error']:>12.2%}")
    print(f"  Correlation:          {stats['correlation']:>12.6f} [-]")
    print(f"  R²:                   {stats['r_squared']:>12.6f} [-]")

    print(f"\nSample Size:")
    print(f"  Number of nodes:      {stats['n_nodes']:>12d}")

    print(f"\n{'='*70}")

    # Assessment
    print(f"\nASSESSMENT:")
    if stats['rmse'] < 0.01:
        print("  ✓ EXCELLENT agreement (RMSE < 1 cm)")
    elif stats['rmse'] < 0.05:
        print("  ✓ GOOD agreement (RMSE < 5 cm)")
    elif stats['rmse'] < 0.1:
        print("  ⚠ ACCEPTABLE agreement (RMSE < 10 cm)")
    else:
        print("  ✗ POOR agreement (RMSE > 10 cm) - investigation needed")

    if abs(stats['mean_error']) < 0.01:
        print("  ✓ No significant bias")
    else:
        print(f"  ⚠ Systematic bias detected: {stats['mean_error']:.4f} {units}")

    if stats['correlation'] > 0.99:
        print("  ✓ Spatial patterns match excellently")
    elif stats['correlation'] > 0.95:
        print("  ✓ Spatial patterns match well")
    else:
        print("  ⚠ Spatial patterns differ")


def plot_comparison(fortran_data, python_data, time, variable='psi',
                    output_file=None):
    """
    Create comprehensive comparison plots.

    Parameters
    ----------
    fortran_data : np.ndarray
        Fortran output, shape (n_eta, n_xsi)
    python_data : np.ndarray
        Python output, same shape
    time : float
        Time of this snapshot [s]
    variable : str
        Variable name
    output_file : str or Path, optional
        Save figure to file
    """
    fig = plt.figure(figsize=(16, 10))

    # Compute difference
    diff = python_data - fortran_data

    # Plot limits
    vmin = min(fortran_data.min(), python_data.min())
    vmax = max(fortran_data.max(), python_data.max())

    # 1. Fortran output
    ax1 = plt.subplot(2, 3, 1)
    im1 = ax1.imshow(fortran_data, cmap='viridis', vmin=vmin, vmax=vmax,
                     aspect='auto', origin='upper')
    ax1.set_title(f'Fortran CATFLOW\nt = {time/3600:.2f} hr')
    ax1.set_ylabel('Depth index')
    ax1.set_xlabel('Lateral index')
    plt.colorbar(im1, ax=ax1, label=variable)

    # 2. Python output
    ax2 = plt.subplot(2, 3, 2)
    im2 = ax2.imshow(python_data, cmap='viridis', vmin=vmin, vmax=vmax,
                     aspect='auto', origin='upper')
    ax2.set_title(f'Python CATFLOW\nt = {time/3600:.2f} hr')
    ax2.set_ylabel('Depth index')
    ax2.set_xlabel('Lateral index')
    plt.colorbar(im2, ax=ax2, label=variable)

    # 3. Difference map
    ax3 = plt.subplot(2, 3, 3)
    diff_max = max(abs(diff.min()), abs(diff.max()))
    im3 = ax3.imshow(diff, cmap='RdBu_r', vmin=-diff_max, vmax=diff_max,
                     aspect='auto', origin='upper')
    ax3.set_title(f'Difference\n(Python - Fortran)')
    ax3.set_ylabel('Depth index')
    ax3.set_xlabel('Lateral index')
    plt.colorbar(im3, ax=ax3, label=f'Δ{variable}')

    # 4. Scatter plot
    ax4 = plt.subplot(2, 3, 4)
    ax4.scatter(fortran_data.flatten(), python_data.flatten(),
                alpha=0.5, s=10, edgecolors='none')
    # Add 1:1 line
    plot_lim = [min(vmin, vmin), max(vmax, vmax)]
    ax4.plot(plot_lim, plot_lim, 'r--', linewidth=2, label='1:1 line')
    ax4.set_xlabel(f'Fortran {variable}')
    ax4.set_ylabel(f'Python {variable}')
    ax4.set_title('Scatter plot')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    ax4.axis('equal')

    # 5. Histogram of differences
    ax5 = plt.subplot(2, 3, 5)
    ax5.hist(diff.flatten(), bins=50, edgecolor='black', alpha=0.7)
    ax5.axvline(0, color='r', linestyle='--', linewidth=2, label='Zero')
    ax5.axvline(np.mean(diff), color='g', linestyle='--', linewidth=2,
                label=f'Mean = {np.mean(diff):.4f}')
    ax5.set_xlabel(f'Difference (Python - Fortran)')
    ax5.set_ylabel('Frequency')
    ax5.set_title('Histogram of differences')
    ax5.legend()
    ax5.grid(True, alpha=0.3)

    # 6. Vertical profiles (for 1D/2D cases)
    ax6 = plt.subplot(2, 3, 6)
    if fortran_data.shape[1] <= 5:  # Likely 1D case
        # Average over lateral direction
        fortran_profile = np.mean(fortran_data, axis=1)
        python_profile = np.mean(python_data, axis=1)
        depth = np.arange(len(fortran_profile))

        ax6.plot(fortran_profile, depth, 'b-o', label='Fortran', linewidth=2)
        ax6.plot(python_profile, depth, 'r--s', label='Python', linewidth=2)
        ax6.set_ylabel('Depth index')
        ax6.set_xlabel(variable)
        ax6.set_title('Vertical profiles')
        ax6.legend()
        ax6.grid(True, alpha=0.3)
        ax6.invert_yaxis()
    else:
        # For 2D, show lateral average
        fortran_avg = np.mean(fortran_data, axis=0)
        python_avg = np.mean(python_data, axis=0)
        lateral = np.arange(len(fortran_avg))

        ax6.plot(lateral, fortran_avg, 'b-o', label='Fortran', linewidth=2)
        ax6.plot(lateral, python_avg, 'r--s', label='Python', linewidth=2)
        ax6.set_xlabel('Lateral index')
        ax6.set_ylabel(f'Mean {variable}')
        ax6.set_title('Lateral averages')
        ax6.legend()
        ax6.grid(True, alpha=0.3)

    plt.tight_layout()

    if output_file:
        plt.savefig(output_file, dpi=150, bbox_inches='tight')
        print(f"Comparison plot saved to: {output_file}")

    return fig


def compare_time_series(fortran_results, python_results, variable='psi'):
    """
    Compare evolution over time.

    Parameters
    ----------
    fortran_results : dict
        Fortran results with 'times' and 'data'
    python_results : dict
        Python results
    variable : str
        Variable to compare
    """
    # Get aligned data
    aligned = compare_with_python_results(fortran_results, python_results, variable)

    times = np.array(aligned['times']) / 3600.0  # Convert to hours

    # Compute statistics at each timestep
    rmse_history = []
    mae_history = []
    max_error_history = []

    for f_data, p_data in zip(aligned['fortran_data'], aligned['python_data']):
        diff = p_data - f_data
        rmse_history.append(np.sqrt(np.mean(diff**2)))
        mae_history.append(np.mean(np.abs(diff)))
        max_error_history.append(np.max(np.abs(diff)))

    # Plot
    fig, axes = plt.subplots(3, 1, figsize=(10, 10))

    # RMSE
    axes[0].plot(times, rmse_history, 'b-o', linewidth=2)
    axes[0].set_ylabel('RMSE [m]')
    axes[0].set_title('Root Mean Square Error over time')
    axes[0].grid(True, alpha=0.3)

    # MAE
    axes[1].plot(times, mae_history, 'g-s', linewidth=2)
    axes[1].set_ylabel('MAE [m]')
    axes[1].set_title('Mean Absolute Error over time')
    axes[1].grid(True, alpha=0.3)

    # Max error
    axes[2].plot(times, max_error_history, 'r-^', linewidth=2)
    axes[2].set_ylabel('Max |error| [m]')
    axes[2].set_xlabel('Time [hours]')
    axes[2].set_title('Maximum Absolute Error over time')
    axes[2].grid(True, alpha=0.3)

    plt.tight_layout()
    return fig


def main():
    """
    Main comparison script.

    Usage:
        python compare_results.py <python_results.npz> <fortran_psi.out>
    """
    import argparse

    parser = argparse.ArgumentParser(description='Compare Fortran and Python CATFLOW results')
    parser.add_argument('python_results', help='Python results file (.npz)')
    parser.add_argument('fortran_output', help='Fortran output file (.out)')
    parser.add_argument('--variable', default='psi', help='Variable to compare (default: psi)')
    parser.add_argument('--output-dir', default='comparison_output', help='Output directory')

    args = parser.parse_args()

    # Create output directory
    output_dir = Path(args.output_dir)
    output_dir.mkdir(exist_ok=True)

    print("=" * 70)
    print("CATFLOW COMPARISON: Fortran vs Python")
    print("=" * 70)
    print(f"\nPython results:  {args.python_results}")
    print(f"Fortran results: {args.fortran_output}")
    print(f"Variable:        {args.variable}")

    # Load Python results
    print("\nLoading Python results...")
    python_data = np.load(args.python_results, allow_pickle=True)
    python_results = {
        'times': python_data['times'],
        args.variable: list(python_data[args.variable])
    }
    print(f"  Found {len(python_results['times'])} timesteps")

    # Load Fortran results
    print("\nLoading Fortran results...")
    fortran_results = read_fortran_matrix_output(args.fortran_output, args.variable)
    print(f"  Found {len(fortran_results['times'])} timesteps")

    # Align and compare
    print("\nAligning timesteps...")
    aligned = compare_with_python_results(fortran_results, python_results, args.variable)
    print(f"  {aligned['n_common']} common timesteps found")

    # Compare final timestep
    print("\n" + "=" * 70)
    print("COMPARING FINAL TIMESTEP")
    print("=" * 70)

    fortran_final = aligned['fortran_data'][-1]
    python_final = aligned['python_data'][-1]
    time_final = aligned['times'][-1]

    stats = compute_statistics(fortran_final, python_final)
    print_statistics_table(stats, variable=args.variable)

    # Plot comparison
    plot_comparison(
        fortran_final, python_final, time_final,
        variable=args.variable,
        output_file=output_dir / 'comparison_final.png'
    )

    # Time series comparison
    print("\n" + "=" * 70)
    print("TIME SERIES COMPARISON")
    print("=" * 70)

    fig_time = compare_time_series(fortran_results, python_results, args.variable)
    fig_time.savefig(output_dir / 'comparison_timeseries.png', dpi=150, bbox_inches='tight')
    print(f"Time series plot saved to: {output_dir / 'comparison_timeseries.png'}")

    plt.show()

    print("\n" + "=" * 70)
    print("COMPARISON COMPLETE")
    print("=" * 70)


if __name__ == '__main__':
    # If run without arguments, show help
    if len(sys.argv) == 1:
        print(__doc__)
        print("\nUsage:")
        print("  python compare_results.py <python_results.npz> <fortran_output.out>")
        print("\nExample:")
        print("  python compare_results.py \\")
        print("      ../benchmark_cases/1d_column/python/python_results.npz \\")
        print("      ../benchmark_cases/1d_column/fortran/psi.out")
    else:
        main()
