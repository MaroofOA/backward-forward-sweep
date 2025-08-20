# -*- coding: utf-8 -*-
"""
Created on Sun Nov  3 16:29:08 2024

@author: Morufdeen ATILOLA!
"""

def generate_opendss_load_script(load_data, phases, kv):
    # Initialize an empty string to hold the full script
    opendss_script = ""
    
    # Iterate over each row in the line_data
    for i, row in enumerate(load_data[1:], start=1):
        bus_number, P, Q = row  # Unpack the row
        
        # Format the OpenDSS command for this line
        load_command = f"New Load.laod{i} bus1={bus_number} phases={phases} kv={kv:.2f} kw={P:.2f} Q={Q:.2f}\n"
        

        # Append the line command to the full script
        opendss_script += load_command
    
    return opendss_script