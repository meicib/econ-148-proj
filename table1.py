import pandas as pd
import numpy as np

def standardize_column_names(df):
    """
    This function standardizes all column names to uppercase to avoid case sensitivity issues.
    """
    if df is None:
        return None
    # Create a mapping of lowercase to uppercase column names
    column_map = {col: col.upper() for col in df.columns}
    # Rename all columns to uppercase
    df = df.rename(columns=column_map)
    return df

def process_cps_data(df):
    # Make a copy of the dataframe to avoid modifying the original
    df = df.copy()
    
    # Standardize column names to uppercase to ensure consistency
    df.columns = [col.upper() for col in df.columns]
    
    # Filter age range
    df = df[(df['AGE'] >= 21) & (df['AGE'] <= 58)]
    
    # Calculate wages
    df['lnwkwage'] = np.where(
        (df['WKSWORK'] > 0) & (df['WSAL_VAL'] > 0),
        np.log(df['WSAL_VAL'] / df['WKSWORK']),
        np.nan
    )
    df['wkwage'] = np.where(
        df['WKSWORK'] > 0,
        df['WSAL_VAL'] / df['WKSWORK'],
        np.nan
    )
    df['totwage'] = df['WSAL_VAL']
    df['jobwage'] = df['ERN_VAL']
    
    # Adjust weights
    df['FNLWGT'] = df['FNLWGT'] / 100
    df['MARSUPWT'] = df['MARSUPWT'] / 100
    df['FNLWGT2'] = df['FNLWGT2'] / 100
    
    # Age groups
    df['agegrp'] = 10 * (df['AGE'] // 10)
    df['age20'] = (df['agegrp'] == 20).astype(int)
    df['age30'] = (df['agegrp'] == 30).astype(int)
    df['age40'] = (df['agegrp'] == 40).astype(int)
    df['age50'] = (df['agegrp'] == 50).astype(int)
    
    # Sample classification
    df['sample'] = np.where(df['AGE'] < 40, 'young', 'old')
    
    # Race groups
    df['racegrp'] = np.where(df['RACE'] >= 3, 3, df['RACE'])
    df['white'] = (df['RACE'] == 1).astype(int)
    df['black'] = (df['RACE'] == 2).astype(int)
    df['other'] = (df['RACE'] == 3).astype(int)
    
    # CPI-W adjustments
    cpiw_dict = {
        88: 117,
        89: 122.6,
        90: 129.0,
        91: 134.3,
        92: 138.2,
        93: 142.1,
        94: 145.6,
        95: 149.8,
        96: 154.1,
        97: 157.6
    }
    df['cpiw'] = df['YEAR'].map(cpiw_dict)
    df['cpiw'] = df['cpiw'] / 117
    
    # Real wages
    df['rlwkwage'] = df['wkwage'] / df['cpiw']
    df['wkwage'] = df['wkwage'] / df['cpiw']
    
    # Clean wage outliers
    mask = (df['rlwkwage'] < 25) | (df['rlwkwage'] > 2000)
    df.loc[mask, 'lnwkwage'] = np.nan
    df.loc[mask, 'wkwage'] = np.nan
    
    # Federal benefits
    df['di'] = ((df['SS_VAL'] / (df['cpiw'] * 52)) > 75).astype(int)
    df['oas'] = ((df['SS_YN'] == 1) & (df['di'] == 0)).astype(int)
    df['ssi'] = (df['SSI_YN'] == 1).astype(int)
    df['ssiordi'] = ((df['ssi'] == 1) | (df['di'] == 1)).astype(int)
    df['oasdissi'] = ((df['SS_YN'] == 1) | (df['SSI_YN'] == 1)).astype(int)
    
    # Other disability
    df['otherdis'] = (df['DIS_YN'] == 1).astype(int)
    
    # VA benefits
    df['vetcomp'] = (df['VET_TYP1'] == 1).astype(int)
    df['vetsurv'] = (df['VET_TYP2'] == 1).astype(int)
    df['vetpens'] = (df['VET_TYP3'] == 1).astype(int)
    df['veteduc'] = (df['VET_TYP4'] == 1).astype(int)
    df['vetothr'] = (df['VET_TYP5'] == 1).astype(int)
    df['vetqva'] = (df['VET_QVA'] == 1).astype(int)
    df['anyva'] = (df['VET_YN'] == 1).astype(int)
    
    # Other federal benefits
    df['fgdi'] = ((df['DIS_SC1'] == 3) | (df['DIS_SC2'] == 3)).astype(int)
    df['mildi'] = ((df['DIS_SC1'] == 4) | (df['DIS_SC2'] == 4)).astype(int)
    df['usrrdi'] = ((df['DIS_SC1'] == 6) | (df['DIS_SC2'] == 6)).astype(int)
    df['afdc'] = 0
    df['otherfed'] = ((df['fgdi'] == 1) | (df['mildi'] == 1) | 
                      (df['usrrdi'] == 1) | (df['afdc'] == 1)).astype(int)
    
    # Classifications
    df['anyfed'] = ((df['oasdissi'] == 1) | (df['anyva'] == 1) | 
                    (df['otherfed'] == 1)).astype(int)
    df['meanstst'] = ((df['oasdissi'] == 1) | 
                      ((df['anyva'] == 1) & (df['vetqva'] == 1)) | 
                      (df['afdc'] == 1)).astype(int)
    
    # Instruments
    df['vetcomp2'] = ((df['vetcomp'] == 1) | 
                      ((df['fgdi'] == 1) | (df['mildi'] == 1) | 
                       (df['usrrdi'] == 1))).astype(int)
    df['vetcomp3'] = ((df['anyva'] == 1) & (df['vetqva'] == 0)).astype(int)
    
    # Demographics
    df['married'] = ((1 <= df['MARITAL']) & (df['MARITAL'] <= 3)).astype(int)
    df['widowed'] = (df['MARITAL'] == 4).astype(int)
    df['divsep'] = ((5 <= df['MARITAL']) & (df['MARITAL'] <= 6)).astype(int)
    df['veteran'] = ((1 <= df['VET']) & (df['VET'] <= 5)).astype(int)
    df['vietserv'] = (df['VET'] == 1).astype(int)
    df['koraserv'] = (df['VET'] == 2).astype(int)
    df['othrserv'] = ((3 <= df['VET']) & (df['VET'] <= 5)).astype(int)
    
    # Working data step
    df['trend'] = df['YEAR'] - 87
    df['trend2'] = df['trend'] ** 2
    
    # Year dummies
    for year in range(92, 98):
        df[f'dis_yr{year}'] = ((df['YEAR'] == year) * df['DISABL1']).astype(int)
    
    df['dyr_9497'] = (df['DISABL1'] * ((94 <= df['YEAR']) & (df['YEAR'] <= 97))).astype(int)
    
    # Year indicators
    for year in range(89, 98):
        df[f'yr{year}'] = (df['YEAR'] == year).astype(int)
    
    df['trend_d'] = df['trend'] * df['DISABL1']
    df['age2'] = df['AGE'] ** 2
    
    # Education
    df['posths'] = ((df['SOMECO'] == 1) | (df['COLGRAD'] == 1)).astype(int)
    
    # Region
    df['south'] = ((5 <= df['REGION']) & (df['REGION'] <= 7)).astype(int)
    df['west'] = ((8 <= df['REGION']) & (df['REGION'] <= 9)).astype(int)
    
    # Filter even years
    df = df[df['YEAR'] % 2 == 0]
    
    return df

def calculate_summary_stats(df):
    # Create separate tables for men and women
    tables = []
    
    for sex_value, sex_label in [(1, "A. Men Aged 21-39"), (2, "B. Women Aged 21-39")]:
        # Filter for age 21-39 and specific sex
        df_filtered = df[(df['AGE'] <= 39) & (df['AGE'] >= 21) & (df['SEX'] == sex_value)]
        
        # List of years to process
        years = [88, 90, 92, 94, 96]
        
        # Initialize lists to store results
        results = []
        
        for year in years:
            # Filter for specific year
            year_data = df_filtered[df_filtered['YEAR'] == year + 1900]
            
            # Calculate stats for disabled and nondisabled
            for disabled in [1, 0]:
                group_data = year_data[year_data['DISABL1'] == disabled]
                
                if len(group_data) > 0:
                    stats = {
                        'Year': year + 1900,
                        'Disabled': disabled,
                        'Age': np.average(group_data['AGE'], weights=group_data['FNLWGT2']).round(1),
                        'White': np.average(group_data['white'], weights=group_data['FNLWGT2']).round(2),
                        'Post-high school': np.average(group_data['posths'], weights=group_data['FNLWGT2']).round(2),
                        'Working': np.average(group_data['WORKING'], weights=group_data['FNLWGT2']).round(2),
                        'Weeks worked': np.average(group_data['WKSWORK'], weights=group_data['FNLWGT2']).round(1),
                        'Weekly wage': np.average(group_data['wkwage'], weights=group_data['FNLWGT2']).round(1),
                        'SSI or DI': np.average(group_data['ssiordi'], weights=group_data['FNLWGT2']).round(3),
                        'Observations': len(group_data)
                    }
                    results.append(stats)
        
        # Convert to DataFrame and format
        df_results = pd.DataFrame(results)
        
        # Pivot the data to match the desired format
        table = pd.pivot_table(
            df_results,
            index=['Year'],
            columns=['Disabled'],
            values=['Age', 'White', 'Post-high school', 'Working', 'Weeks worked', 
                   'Weekly wage', 'SSI or DI', 'Observations'],
            aggfunc='first'
        ).round(3)
        
        # Add section header
        table.insert(0, 'Section', sex_label)
        tables.append(table)
    
    # Combine tables
    final_table = pd.concat(tables)
    
    # Format the table
    final_table.columns = [f'{"Disabled" if col[1] == 1 else "Nondisabled"}' 
                          for col in final_table.columns]
    
    return final_table

def load_and_process_data(file_path):
    """
    Load data from file and process it
    
    Parameters:
    file_path (str): Path to the data file
    
    Returns:
    pd.DataFrame: Processed dataframe
    """
    try:
        # Try to determine file format and load accordingly
        if file_path.endswith('.csv'):
            df = pd.read_csv(file_path)
        elif file_path.endswith('.sas7bdat'):
            df = pd.read_sas(file_path)
        elif file_path.endswith('.dta'):
            df = pd.read_stata(file_path)
        else:
            raise ValueError(f"Unsupported file format: {file_path}")
        
        # Process the data
        processed_df = process_cps_data(df)
        return processed_df
    except Exception as e:
        print(f"Error loading or processing data: {e}")
        return None

# Example of how to use this module
if __name__ == "__main__":
    # Path to your data file
    file_path = "path/to/your/marcps_w.sas7bdat"  # Update this with your actual file path
    
    # Load and process the data
    processed_data = load_and_process_data(file_path)
    
    if processed_data is not None:
        # Calculate summary statistics
        summary_stats = calculate_summary_stats(processed_data)
        
        # Display the results
        print(summary_stats)
        
        # Optionally save to Excel or CSV
        # summary_stats.to_excel("table1_results.xlsx")
        # summary_stats.to_csv("table1_results.csv") 