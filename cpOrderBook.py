
from shutil import copyfile

OANDA_DIR = 'C:\\Users\\Administrator\\AppData\\Roaming\\MetaQuotes\\Terminal\\3212703ED955F10C7534BE8497B221F4\\MQL4\\Files\\'
FXTF_DIR = 'C:\\Users\\Administrator\\AppData\\Roaming\\MetaQuotes\\Terminal\\3F58D636E9CFCB1149A0A8D4AE12E98D\\MQL4\\Files\\'
RAKUTEN_DIR = 'C:\\Users\\Administrator\\AppData\\Roaming\\MetaQuotes\\Terminal\\3212703ED955F10C7534BE8497B221F4\\MQL4\\Files\\'

pair = ['EURUSD', 'USDJPY', 'EURJPY', 'GBPUSD', 'GBPJPY', 'AUDJPY']


for c in pair:
    
    src = OANDA_DIR + 'OANDA_' + c + '.csv'

    dst = FXTF_DIR + c + '.csv'
    copyfile(src, dst)

#    dst = RAKUDEN_DIR + c + '.csv'
#    copyfile(src, dst)
