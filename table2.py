import pandas as pd
import numpy as np
import statsmodels.formula.api as smf

def prepare_data(df):
    if df is None:
        return None
    
    # Filter by age
    df = df[(df['age'] >= 21) & (df['age'] <= 58)].copy()
    
    # Create sample variable
    df['sample'] = np.where(df['age'] < 40, 'young', 'old')
    
    # Calculate wage variables
    mask = (df['wkswork'] > 0) & (df['wsal_val'] > 0)
    df.loc[mask, 'lnwkwage'] = np.log(df.loc[mask, 'wsal_val'] / df.loc[mask, 'wkswork'])
    df.loc[mask, 'wkwage'] = df.loc[mask, 'wsal_val'] / df.loc[mask, 'wkswork']
    df['totwage'] = df['wsal_val']
    df['jobwage'] = df['ern_val']
    
    # Age group variables
    df['agegrp'] = 10 * (df['age'] // 10)
    df['age20'] = (df['agegrp'] == 20).astype(int)
    df['age30'] = (df['agegrp'] == 30).astype(int)
    df['age40'] = (df['agegrp'] == 40).astype(int)
    df['age50'] = (df['agegrp'] == 50).astype(int)
    
    # Race group
    df['racegrp'] = np.where(df['race'] >= 3, 3, df['race'])
    
    # Education group
    conditions = [
        df['lesshs'] == 1,
        df['hsgrad'] == 1,
        (df['someco'] == 1) | (df['colgrad'] == 1)
    ]
    choices = [1, 2, 3]
    df['educgrp'] = np.select(conditions, choices, default=np.nan)
    
    # Work status
    df['workly'] = (df['wkswork'] > 0).astype(int)
    
    # Labor force variables
    df['lfin1'] = np.where(df['wkswork'] == 0, df['working'], np.nan)
    df['lfin2'] = np.where(df['wkswork'] < 50, df['working'], np.nan)
    df['lfout1'] = np.where(df['wkswork'] >= 50, 1 - df['working'], np.nan)
    df['changer'] = np.where(df['wkswork'] == 0, np.nan, df['changer'])
    
    # Trend variables
    df['trend'] = df['year'] - 87
    df['trend2'] = df['trend'] ** 2
    
    # Disability interaction variables
    df['dis_trend'] = df['trend'] * df['disabl1']
    
    # Create disability year interaction variables
    for yr in range(89, 98):
        df[f'dis_yr{yr}'] = (df['year'] == yr) * df['disabl1']
    
    df['dyr_9497'] = ((df['year'] >= 94) & (df['year'] <= 97)) * df['disabl1']
    
    # CPI-W values
    cpiw_dict = {
        88: 117.0,
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
    
    df['cpiw'] = df['year'].map(cpiw_dict)
    df['cpiw88'] = df['cpiw'] / 117.0
    
    # Real wages
    df['rlwkwage'] = df['wkwage'] / df['cpiw88']
    
    # Filter wage outliers
    outlier_mask = (df['rlwkwage'] < 25) | (df['rlwkwage'] > 2000)
    df.loc[outlier_mask, 'lnwkwage'] = np.nan
    df.loc[outlier_mask, 'wkwage'] = np.nan
    
    # Keep only necessary columns (similar to keep statement in SAS)
    columns_to_keep = [
        'age', 'agegrp', 'year', 'sex', 'disabl1', 'totwage', 'jobwage', 'sample',
        'working', 'unempl', 'nilf', 'jobloser', 'wkswork', 'workly',
        'hsgrad', 'someco', 'colgrad', 'region', 'centralc', 'balmsa', 'trend',
        'dis_yr89', 'dis_yr90', 'dis_yr91', 'dis_yr92', 'dis_yr93', 'dis_yr94', 
        'dis_yr95', 'dis_yr96', 'dis_yr97', 'dyr_9497', 'fnlwgt',
        'age20', 'age30', 'age40', 'age50', 'noweeks', 'racegrp', 'lnwkwage', 
        'region', 'hg_st60', 'lesshs', 'hsgrad', 'someco', 'colgrad', 'dis_trend',
        'cpiw', 'cpiw88', 'rlwkwage', 'wkwage', 'fnlwgt2', 'educgrp'
    ]
    
    # Keep only columns that exist in the dataframe
    existing_columns = [col for col in columns_to_keep if col in df.columns]
    return df[existing_columns]

def analyze_data(df):
    if df is None:
        return
    
    # Descriptive statistics (equivalent to PROC MEANS)
    print('Descriptive Statistics:')
    print(df.describe())
    
    # Sort the data (equivalent to PROC SORT)
    df = df.sort_values(by=['sample', 'year', 'disabl1'], ascending=[True, False, False])
    
    # Create analysis functions for each group
    def run_analysis(data, sex_value, sample_value, use_trend=False):
        # Filter data
        filtered_data = data[(data['sex'] == sex_value) & (data['sample'] == sample_value)].copy()
        
        if filtered_data.empty:
            print(f"No data available for sex={sex_value}, sample={sample_value}")
            return
        
        gender = "men" if sex_value == 1 else "women"
        trend_text = "trend" if use_trend else "NO trend -- add 89-91 year dummies"
        print(f"\nOutcomes for -- {gender} -- {trend_text}")
        
        # Convert categorical variables to category type
        cat_vars = ['year', 'agegrp', 'racegrp', 'educgrp', 'region', 'disabl1']
        for var in cat_vars:
            if var in filtered_data.columns:
                filtered_data[var] = filtered_data[var].astype('category')
        
        # For each dependent variable (wkswork and lnwkwage)
        for dependent_var in ['wkswork', 'lnwkwage']:
            if dependent_var not in filtered_data.columns:
                print(f"Variable {dependent_var} not found in dataset")
                continue
                
            print(f"\nAnalysis for {dependent_var}:")
            
            try:
                # Build formula similar to PROC GLM
                formula_parts = [
                    "C(year)", "C(agegrp)", "C(racegrp)", "C(educgrp)", "C(region)",
                    "C(year):C(agegrp)", "C(year):C(racegrp)", "C(year):C(educgrp)", "C(year):C(region)",
                    "C(disabl1)"
                ]
                
                # Add interaction terms based on whether we're using trend or not
                if use_trend:
                    formula_parts.extend([
                        "C(dis_yr92)", "C(dis_yr93)", "C(dis_yr94)", "C(dis_yr95)", 
                        "C(dis_yr96)", "C(dis_yr97)", "dis_trend"
                    ])
                else:
                    formula_parts.extend([
                        "C(dis_yr89)", "C(dis_yr90)", "C(dis_yr91)", "C(dis_yr92)", 
                        "C(dis_yr93)", "C(dis_yr94)", "C(dis_yr95)", "C(dis_yr96)", "C(dis_yr97)"
                    ])
                
                formula = f"{dependent_var} ~ " + " + ".join(formula_parts)
                
                # Fit model using statsmodels
                model = smf.wls(
                    formula=formula,
                    data=filtered_data.dropna(subset=[dependent_var]),
                    weights=filtered_data['fnlwgt2']
                )
                results = model.fit()
                
                # Print results
                print(results.summary())
                
            except Exception as e:
                print(f"Error in analysis: {e}")
    
    # Run analyses for men and women, young and old, with and without trend
    for sex_value in [1, 2]:  # 1 for men, 2 for women
        for sample_value in ['young', 'old']:
            # Without trend
            run_analysis(df, sex_value, sample_value, use_trend=False)
            
            # With trend
            run_analysis(df, sex_value, sample_value, use_trend=True)