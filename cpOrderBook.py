
from shutil import copyfile


def hasUpdated(currency, orderbook):

    f = open(orderbook)
    ts = f.readline()
    
    if currency in latest:
        if latest[currency] == ts:
            return False
    
    n = int(f.readline().split(',')[-1])
    
    while True:
        if not f.readline():
            break
        n = n - 1

    if n == 1:
        latest[currency] = ts
        return True

    return False



OANDA_DIR = 'C:\\Users\\Administrator\\AppData\\Roaming\\MetaQuotes\\Terminal\\3212703ED955F10C7534BE8497B221F4\\MQL4\\Files\\'
FXTF_DIR = 'C:\\Users\\Administrator\\AppData\\Roaming\\MetaQuotes\\Terminal\\3F58D636E9CFCB1149A0A8D4AE12E98D\\MQL4\\Files\\'
RAKUTEN_DIR = 'C:\\Users\\Administrator\\AppData\\Roaming\\MetaQuotes\\Terminal\\3212703ED955F10C7534BE8497B221F4\\MQL4\\Files\\'

pair = ['EURUSD', 'USDJPY', 'EURJPY', 'GBPUSD', 'GBPJPY', 'AUDJPY']
latest = {}

for c in pair:
    
    src = OANDA_DIR + 'OANDA_' + c + '.csv'

    if(hasUpdated(c, src)):
        dst = FXTF_DIR + c + '.csv'
        copyfile(src, dst)

