# -*- coding: utf-8 -*-
from bs4 import BeautifulSoup
import pandas as pd
import requests


def get_games(year, game_type='SHL'):
    url = 'http://www.shl.se/statistics/games/base/Time/{year}/{game_type}/All/All/All/All/true/All/inv'.format(year=year, game_type=game_type)
    res = requests.get(url, params={'count': 0, 'lang': 'en'})
    res.raise_for_status() 

    html = BeautifulSoup(res.text)
    stat_table = html.find('table', 'jx_stat_table')

    if not stat_table:
        raise Error('table.jx_stat_table not found')

    cols = [th.text.strip() for tr in stat_table.thead.find_all('tr') for th in tr.find_all('th')]

    if not len(cols):
        raise Error('no header rows found')
        
    rows = [[td.text.strip() for td in tr.find_all('td')] for tr in stat_table.tbody.find_all('tr')]

    if not len(rows):
        raise Error('no rows found')
        
    df = pd.DataFrame.from_records(rows, columns=cols)
    df[u'Season'] = len(rows) * [year]
    df[u'Game type'] = len(rows) * [game_type]
    return df


if __name__ == '__main__':
    import sys

    years = range(2006, 2016)
    game_types = ['SHL', 'SMSlutspel']

    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print('usage: python scraper.py [year [game_type]]')
        sys.exit(1)

    if len(sys.argv) == 3:
        game_types = [sys.argv.pop()]

    if len(sys.argv) == 2:
        years = [int(sys.argv.pop())]

    df = pd.concat(get_games(year, game_type) for game_type in game_types for year in years)
    df.to_csv(sys.stdout, index=False, encoding='utf-8')
