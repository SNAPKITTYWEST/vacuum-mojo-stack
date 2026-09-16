"""Interactive demo. Run inside IPython: %run vacuum_ipython/demo.py"""
from vacuum_ipython import install

runtime = install()
print("vacuum-ipython installed.")

# Try:
# q> 1 + 1
# q@ radius = 3.14159 * 2
# #~ just finished calibration
# %%vacuum experiment-01
# q> sum(range(10))
# q@ result = 42
#
# Then:
# print(vacuum.pretty_audit())
