# SPDX-FileCopyrightText: Copyright 2026 GlobalFoundries PDK Authors
# SPDX-License-Identifier: Apache License 2.0
"""Generate antenna-equality.gds.gz for the default test variant C.

The published antenna rules are in section 8.0 of the design manual:
https://gf180mcu-pdk.readthedocs.io/en/latest/physical_verification/design_manual/drm_08.html
ANT.2 specifies a maximum Metal1 perimeter ratio of 400; ANT.9 specifies
a maximum Via1 area ratio of 20. Equality must therefore pass.

The six independent thin-gate nets exercise both custom antenna helpers
without diode credit, with an unconnected substrate tap near each net:

* metal_below, metal_equal, metal_above: ratios 399.99, 400, 400.01.
* via_below, via_equal, via_above: ratios below, equal to, and above 20.

Only metal_above and via_above should report. The golden report contains
the two polygons of metal_above and the 101 polygons of via_above (the
gate and its 100 cuts).

This file generates test data; the existing pytest collector discovers
antenna-equality.gds.gz and compares its results with the accompanying
antenna-equality.lyrdb. No separate Python test runner is needed.

From klayout/drc/testing, regenerate the GDS and run the fixture with:

    python unit/antenna_equality.py
    pytest -k 'test_device_drc[antenna-equality]'

The fixed GDS timestamp and gzip timestamp make regeneration deterministic.
"""

import datetime
import gzip
import tempfile
from pathlib import Path

import gdstk


def box(cell: gdstk.Cell, layer: int, bounds: tuple[float, ...]) -> None:
    """Add one drawn-layer rectangle in micrometers."""
    x0, y0, x1, y1 = bounds
    cell.add(gdstk.rectangle((x0, y0), (x1, y1), layer=layer))


def tap(cell: gdstk.Cell) -> None:
    """An isolated p+ substrate tap gives each case the same context."""
    box(cell, 22, (10, 0, 12, 2))
    box(cell, 31, (9.75, -0.25, 12.25, 2.25))


def metal(cell: gdstk.Cell, end: float) -> None:
    """Metal perimeter 400 um * 0.54 um / gate area 0.54 um2 = 400.

    Moving the far metal edge by 5 nm straddles the exact maximum.
    """
    box(cell, 22, (0, 0, 2, 1.8))
    box(cell, 32, (-0.25, -0.25, 2.25, 2.05))
    box(cell, 30, (1, -0.3, 1.3, 3.3))
    box(cell, 30, (0.93, 2.4, 1.37, 3.3))
    box(cell, 33, (1.04, 2.7, 1.26, 2.92))
    box(cell, 34, (0.9, 2.4, 1.5, end))
    tap(cell)


def via(cell: gdstk.Cell, height: float) -> None:
    """100 Via1 cuts * 0.26 um * 0.26 um / gate area 0.338 um2 = 20.

    Moving the COMP edge by 5 nm changes the gate area on either side
    of the maximum without changing the cuts or their connectivity.
    """
    box(cell, 22, (0, 0, 2, height))
    box(cell, 32, (-0.25, -0.25, 2.25, height + 0.25))
    box(cell, 30, (1, -0.3, 1.325, 2.6))
    box(cell, 30, (0.9, 1.5, 1.425, 2.6))
    box(cell, 33, (1.04, 1.8, 1.26, 2.02))
    box(cell, 34, (0, 1.5, 7, 8))
    box(cell, 36, (0, 1.5, 7, 8))
    for row in range(10):
        for column in range(10):
            x, y = 0.4 + column * 0.62, 2 + row * 0.62
            box(cell, 35, (x, y, x + 0.26, y + 0.26))
    tap(cell)


def main() -> None:
    library = gdstk.Library(unit=1e-6, precision=1e-9)
    top = library.new_cell("antenna_equality")
    for index, (name, value) in enumerate((
        ("metal_below", 201.795),
        ("metal_equal", 201.8),
        ("metal_above", 201.805),
        ("via_below", 1.045),
        ("via_equal", 1.04),
        ("via_above", 1.035),
    )):
        cell = library.new_cell(name)
        if name.startswith("metal"):
            metal(cell, value)
        else:
            via(cell, value)
        top.add(gdstk.Reference(cell, origin=(index * 20, 0)))
    output = Path(__file__).with_name("antenna-equality.gds.gz")
    with tempfile.TemporaryDirectory() as directory:
        source = Path(directory) / "antenna-equality.gds"
        library.write_gds(source, timestamp=datetime.datetime(2000, 1, 1))
        output.write_bytes(gzip.compress(source.read_bytes(), mtime=0))


if __name__ == "__main__":
    main()
