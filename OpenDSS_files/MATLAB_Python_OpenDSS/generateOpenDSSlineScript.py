# -*- coding: utf-8 -*-
"""
Created on Sun Nov  3 14:59:02 2024

@author: Morufdeen ATILOLA
"""

def generate_opendss_line_script(line_data, phases):
    # Initialize an empty string to hold the full script
    opendss_script = ""
    
    # Iterate over each row in the line_data
    for i, row in enumerate(line_data, start=1):
        sending, receiving, R, X = row  # Unpack the row
        
        # Format the OpenDSS command for this line
        line_command = f"New Line.Line{i} bus1={int(sending)} bus2={int(receiving)} phases={phases} R1={R:.4f} X1={X:.4f}\n"
        
        # Append the line command to the full script
        opendss_script += line_command
    
    return opendss_script