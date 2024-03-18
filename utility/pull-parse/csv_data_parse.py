#!/usr/bin/env python3

import pandas as pd
import sys

def process_data(data):
    """
    Processes the input DataFrame to calculate summaries by repository and by user,
    including total pulls and pushes and percentages of the overall totals.
    
    Args:
        data (pd.DataFrame): The input data to process.
    
    Returns:
        tuple: A tuple containing two DataFrames: the summary by repository and the summary by user.
    """
    # Convert columns to numeric, removing commas
    data['# Pulls (GET\'s)'] = data['# Pulls (GET\'s)'].str.replace(',', '').astype(int)
    data['# Pushes (PUT\'s)'] = data['# Pushes (PUT\'s)'].str.replace(',', '').astype(int)

    # Calculate total pulls and pushes for percentages
    total_pulls = data['# Pulls (GET\'s)'].sum()
    total_pushes = data['# Pushes (PUT\'s)'].sum()

    # Summarize by repository
    summary_by_repository = data.groupby('Repository')[['# Pulls (GET\'s)', '# Pushes (PUT\'s)']].sum().reset_index()
    summary_by_repository.sort_values(by='# Pulls (GET\'s)', ascending=False, inplace=True)
    summary_by_repository['% of Total Pulls'] = (summary_by_repository['# Pulls (GET\'s)'] / total_pulls) * 100
    summary_by_repository['% of Total Pushes'] = (summary_by_repository['# Pushes (PUT\'s)'] / total_pushes) * 100

    # Summarize by user
    summary_by_user = data.groupby('User Name')[['# Pulls (GET\'s)', '# Pushes (PUT\'s)']].sum().reset_index()
    summary_by_user.sort_values(by='# Pulls (GET\'s)', ascending=False, inplace=True)
    summary_by_user['% of Total Pulls'] = (summary_by_user['# Pulls (GET\'s)'] / total_pulls) * 100
    summary_by_user['% of Total Pushes'] = (summary_by_user['# Pushes (PUT\'s)'] / total_pushes) * 100

    return summary_by_repository, summary_by_user

def process_file(file_path):
    """
    Loads data from a CSV file, processes it, and saves summaries to new CSV files.
    
    Args:
        file_path (str): The path to the CSV file to process.
    """
    # Load the data
    data = pd.read_csv(file_path)
    
    # Ensure the relevant columns are treated as strings
    data['# Pulls (GET\'s)'] = data['# Pulls (GET\'s)'].astype(str)
    data['# Pushes (PUT\'s)'] = data['# Pushes (PUT\'s)'].astype(str)
    
    # Process the data
    summary_by_repository, summary_by_user = process_data(data)

    # Save the summaries to new CSV files in an 'output' directory
    summary_by_repository.to_csv('output/summary_by_repository.csv', index=False)
    summary_by_user.to_csv('output/summary_by_user.csv', index=False)

    print("Summaries have been saved to 'output/summary_by_repository.csv' and 'output/summary_by_user.csv'.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python cvs_data_parse.py <path_to_your_file.csv>")
    else:
        file_path = sys.argv[1]
        process_file(file_path)
