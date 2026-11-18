import numpy as np
O=np.array([-1757.0,3296.0])          # Amber x 10th
A=np.array([-0.4446,0.8955])          # along Amber, toward SSW (pilot +Z)
B=np.array([0.8955,0.4446])           # along 10th, toward ESE (pilot +X)
def to_grid(x,z): p=np.array([x,z])-O; return float(p@B), float(p@A)
def to_world(u,v): p=O+B*u+A*v; return float(p[0]), float(p[1])
