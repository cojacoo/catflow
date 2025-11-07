"""
Tests for Van Genuchten soil hydraulic model.

Validates the implementation against known relationships.
"""

import numpy as np
import sys
from pathlib import Path

# Add catflow to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from catflow.core.physics.soil_models import VanGenuchten


def test_saturation():
    """Test that theta = theta_s when psi >= 0."""
    print("Testing saturation condition (ψ ≥ 0)...")

    soil = VanGenuchten()
    params = {
        'theta_s': 0.45,
        'theta_r': 0.05,
        'alpha': 2.0,
        'n': 1.5,
        'Ks': 1e-5
    }

    psi = np.array([0.0, 0.1, 1.0])
    theta = soil.theta_from_psi(psi, params)

    # Should all equal theta_s
    expected = np.full_like(theta, params['theta_s'])
    np.testing.assert_allclose(theta, expected, rtol=1e-10)

    print("   ✓ Saturated conditions correct")


def test_residual():
    """Test approach to residual water content at very dry conditions."""
    print("Testing residual water content (ψ → -∞)...")

    soil = VanGenuchten()
    params = {
        'theta_s': 0.45,
        'theta_r': 0.05,
        'alpha': 2.0,
        'n': 1.5,
        'Ks': 1e-5
    }

    # Very dry conditions
    psi = np.array([-1000, -10000, -100000])
    theta = soil.theta_from_psi(psi, params)

    # Should approach theta_r
    assert np.all(theta > params['theta_r'])
    assert np.all(theta < params['theta_r'] + 0.01)  # Close to residual

    print(f"   ✓ Approaches θ_r = {params['theta_r']} (got {theta[-1]:.4f})")


def test_conductivity_saturation():
    """Test that K = Ks when theta = theta_s."""
    print("Testing saturated conductivity...")

    soil = VanGenuchten()
    params = {
        'theta_s': 0.45,
        'theta_r': 0.05,
        'alpha': 2.0,
        'n': 1.5,
        'Ks': 1.23e-5
    }

    theta = np.array([params['theta_s']])
    K = soil.K_from_theta(theta, params)

    np.testing.assert_allclose(K, params['Ks'], rtol=1e-10)

    print(f"   ✓ K(θ_s) = K_s = {params['Ks']:.2e} m/s")


def test_conductivity_decreases():
    """Test that K decreases monotonically with decreasing theta."""
    print("Testing conductivity monotonicity...")

    soil = VanGenuchten()
    params = {
        'theta_s': 0.45,
        'theta_r': 0.05,
        'alpha': 2.0,
        'n': 1.5,
        'Ks': 1.23e-5
    }

    theta = np.linspace(params['theta_r'] + 0.01, params['theta_s'], 20)
    K = soil.K_from_theta(theta, params)

    # K should decrease as theta decreases
    dK = np.diff(K)
    assert np.all(dK >= -1e-10)  # Allow small numerical errors

    print(f"   ✓ K monotonically decreases from {K[0]:.2e} to {K[-1]:.2e}")


def test_capacity():
    """Test specific moisture capacity calculation."""
    print("Testing specific moisture capacity...")

    soil = VanGenuchten()
    params = {
        'theta_s': 0.45,
        'theta_r': 0.05,
        'alpha': 2.0,
        'n': 1.5,
        'Ks': 1.23e-5
    }

    # Test at various pressures
    psi = np.array([0.0, -0.1, -1.0, -10.0])
    C = soil.capacity(psi, params)

    # C should be 0 at saturation
    assert C[0] == 0.0

    # C should be positive for unsaturated
    assert np.all(C[1:] > 0.0)

    # C should have a maximum (Van Genuchten capacity is not monotonic)
    # It increases from 0, reaches a maximum, then decreases
    # For very dry soils, C should approach 0
    assert C[-1] < np.max(C)  # Very dry has smaller C than the maximum

    # C should be finite and reasonable
    assert np.all(np.isfinite(C))
    assert np.all(C >= 0.0)

    print(f"   ✓ C(ψ=0) = {C[0]}, C(ψ=-0.1) = {C[1]:.4f}, C(ψ=-1) = {C[2]:.4f}, C(ψ=-10) = {C[3]:.4f}")


def test_consistency():
    """Test consistency between theta_from_psi and K_from_theta vs K_from_psi."""
    print("Testing consistency of K calculations...")

    soil = VanGenuchten()
    params = {
        'theta_s': 0.45,
        'theta_r': 0.05,
        'alpha': 2.0,
        'n': 1.5,
        'Ks': 1.23e-5
    }

    psi = np.array([-0.5, -1.0, -5.0])

    # Method 1: psi -> theta -> K
    theta = soil.theta_from_psi(psi, params)
    K1 = soil.K_from_theta(theta, params)

    # Method 2: psi -> K (direct)
    K2 = soil.K_from_psi(psi, params)

    np.testing.assert_allclose(K1, K2, rtol=1e-10)

    print("   ✓ K_from_psi consistent with theta_from_psi -> K_from_theta")


def run_all_tests():
    """Run all validation tests."""
    print("\n" + "=" * 70)
    print("CATFLOW - Van Genuchten Model Validation Tests")
    print("=" * 70 + "\n")

    tests = [
        test_saturation,
        test_residual,
        test_conductivity_saturation,
        test_conductivity_decreases,
        test_capacity,
        test_consistency
    ]

    failed = 0
    for test in tests:
        try:
            test()
        except AssertionError as e:
            print(f"   ✗ TEST FAILED: {e}")
            failed += 1
        except Exception as e:
            print(f"   ✗ ERROR: {e}")
            failed += 1

    print("\n" + "=" * 70)
    if failed == 0:
        print(f"ALL TESTS PASSED ({len(tests)}/{len(tests)})")
    else:
        print(f"SOME TESTS FAILED ({len(tests)-failed}/{len(tests)} passed)")
    print("=" * 70 + "\n")

    return failed == 0


if __name__ == '__main__':
    success = run_all_tests()
    sys.exit(0 if success else 1)
