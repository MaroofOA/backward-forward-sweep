# -*- coding: utf-8 -*-
"""
Created on Sun Nov  3 15:16:01 2024

@author: Morufdeen ATILOLA!
"""

import numpy as np
from generateOpenDSSlineScript import generate_opendss_line_script
from generateOpenDSSloadScript import generate_opendss_load_script

# bus_data = pd.read_csv('powerdata_33bus.txt',delimiter='\t', header=None, dtype={0: int}) 
bus_data = np.loadtxt('powerdata_33bus.txt')
line_data = np.loadtxt('linedata_33bus.txt')


load_scipt = generate_opendss_load_script(bus_data, phases=1, kv=12.66)

print(load_scipt)