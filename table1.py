import numpy as np
import pandas as pd

def process_data(d):
    df = d.copy()

    df.columns = df.columns.str.lower()
    # Filter by age
    df = df[(df['age'] >= 21) & (df['age'] <= 58)]

    # Compute wages
    df['lnwkwage'] = np.where(
        (df['wkswork'] > 0) & (df['wsal_val'] > 0),
        np.log(df['wsal_val'] / df['wkswork']),
        np.nan
    )
    df['wkwage'] = np.where(df['wkswork'] > 0, df['wsal_val'] / df['wkswork'], np.nan)
    df['totwage'] = df['wsal_val']
    df['jobwage'] = df['ern_val']

    # Adjust weights
    df['fnlwgt'] /= 100
    df['marsupwt'] /= 100
    df['fnlwgt2'] /= 100

    # Age groups
    df['agegrp'] = 10 * (df['age'] // 10)
    df['age20'] = df['agegrp'] == 20
    df['age30'] = df['agegrp'] == 30
    df['age40'] = df['agegrp'] == 40
    df['age50'] = df['agegrp'] == 50
    df['sample'] = np.where(df['age'] < 40, 'young', 'old')

    # Race groups
    df['racegrp'] = np.where(df['race'] >= 3, 3, df['race'])
    df['white'] = df['race'] == 1
    df['black'] = df['race'] == 2
    df['other'] = df['race'] == 3

    # CPI-W coding
    cpi_map = {
        88: 117, 89: 122.6, 90: 129.0, 91: 134.3, 92: 138.2,
        93: 142.1, 94: 145.6, 95: 149.8, 96: 154.1, 97: 157.6
    }
    df['cpiw'] = df['year'].map(cpi_map)
    df['cpiw'] = df['cpiw'] / 117

    # Real wages and filters
    df['rlwkwage'] = df['wkwage'] / df['cpiw']
    df['wkwage'] = df['wkwage'] / df['cpiw']
    df.loc[(df['rlwkwage'] < 25) | (df['rlwkwage'] > 2000), ['lnwkwage', 'wkwage']] = np.nan

    # Federal benefits
    df['di'] = (df['ss_val'] / (df['cpiw'] * 52)) > 75
    df['oas'] = (df['ss_yn'] == 1) & (~df['di'])
    df['ssi'] = df['ssi_yn'] == 1
    df['ssiordi'] = df['ssi'] | df['di']
    df['oasdissi'] = (df['ss_yn'] == 1) | (df['ssi_yn'] == 1)
    df['otherdis'] = df['dis_yn'] == 1

    # VA and other federal benefits
    df['vetcomp'] = df['vet_typ1'] == 1
    df['vetsurv'] = df['vet_typ2'] == 1
    df['vetpens'] = df['vet_typ3'] == 1
    df['veteduc'] = df['vet_typ4'] == 1
    df['vetothr'] = df['vet_typ5'] == 1
    df['vetqva'] = df['vet_qva'] == 1
    df['anyva'] = df['vet_yn'] == 1

    df['fgdi'] = (df['dis_sc1'] == 3) | (df['dis_sc2'] == 3)
    df['mildi'] = (df['dis_sc1'] == 4) | (df['dis_sc2'] == 4)
    df['usrrdi'] = (df['dis_sc1'] == 6) | (df['dis_sc2'] == 6)
    df['afdc'] = 0
    df['otherfed'] = df[['fgdi', 'mildi', 'usrrdi']].any(axis=1)
    df['anyfed'] = df[['oasdissi', 'anyva', 'otherfed']].any(axis=1)
    df['meanstst'] = df['oasdissi'] | ((df['anyva']) & (df['vetqva'])) | (df['afdc'])

    # Instruments
    df['vetcomp2'] = df['vetcomp'] | df[['fgdi', 'mildi', 'usrrdi']].any(axis=1)
    df['vetcomp3'] = df['anyva'] & (~df['vetqva'])

    # Demographics
    df['married'] = df['marital'].between(1, 3)
    df['widowed'] = df['marital'] == 4
    df['divsep'] = df['marital'].between(5, 6)

    df['veteran'] = df['vet'].between(1, 5)
    df['vietserv'] = df['vet'] == 1
    df['koraserv'] = df['vet'] == 2
    df['othrserv'] = df['vet'].between(3, 5)

    # Time trends and indicators
    df['trend'] = df['year'] - 87
    df['trend2'] = df['trend'] ** 2
    for y in range(92, 98):
        df[f'dis_yr{y}'] = (df['year'] == y) * df['disabl1']
    df['dyr_9497'] = df['disabl1'] * df['year'].between(94, 97).astype(int)
    for y in range(89, 98):
        df[f'yr{y}'] = df['year'] == y
    df['trend_d'] = df['trend'] * df['disabl1']

    # Extra vars
    df['age2'] = df['age'] ** 2
    df['posths'] = (df['someco'] == 1) | (df['colgrad'] == 1)
    df['south'] = df['region'].between(5, 7)
    df['west'] = df['region'].between(8, 9)

    # Filter even years only
    df = df[df['year'] % 2 == 0]

    return df


def compute_summary(df):
    # Columns to group by
    group_cols = ['disabl1', 'sex', 'sample', 'year']
    
    # Columns to compute weighted means on
    summary_vars = ['age', 'white', 'posths', 'working', 'wkswork', 'wkwage', 'ssiordi']
    
    # Drop rows with missing weights or grouping values
    df = df.dropna(subset=['fnlwgt2'] + group_cols)

    # Define weighted mean function
    def weighted_mean(x, weights):
        return np.sum(x * weights) / np.sum(weights) if np.sum(weights) > 0 else np.nan

    # Group and aggregate
    summary = (
        df.groupby(group_cols)
          .apply(lambda g: pd.Series({
              var: weighted_mean(g[var], g['fnlwgt2']) for var in summary_vars
          }))
          .reset_index()
          .sort_values(by=['disabl1', 'sex', 'sample', 'year'], ascending=[False, True, False, True])
    )

    return summary