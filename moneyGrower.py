#!/usr/local/bin/python3

import sys, time
from yahoo_finance import Currency
from random import choice

Long = True
Short = False

def coloredPrint(message, color = 'white', formatting = 'bold'):

    formatCode = {'bold': 1,
                  'bright': 1,
                  'dim': 2,
                  'underline': 4,
                  'reverse': 7,
                  'inverted': 7}

    colorCode = {'gray': 90,
                 'red': 91,
                 'green': 92,
                 'yellow': 93,
                 'blue': 94,
                 'magenta': 95,
                 'cyan': 96,
                 'white': 97}

    formatting = formatting.lower()
    color = color.lower()

    attributes = '\033[' + str(formatCode[formatting] if formatting in formatCode else 0) + ';' + \
                 str(colorCode[color] if color in colorCode else 97) + 'm'
    reset = '\033[0m'

    print(attributes + message + reset, end = '')


class Position:
    CurrencyPair = 'EURUSD'
    currency = Currency(CurrencyPair)
    price2pips = 10000
    spread = 0.4
    margin = spread * 10

#    CurrencyPair = 'GBPJPY'
#    currency = Currency(CurrencyPair)
#    price2pips = 100
#    spread = 1.0
#    margin = spread * 20

#    CurrencyPair = 'EURJPY'
#    currency = Currency(CurrencyPair)
#    price2pips = 100
#    spread = 1.1
#    margin = spread * 20

#    CurrencyPair = 'USDJPY'
#    currency = Currency(CurrencyPair)
#    price2pips = 100
#    spread = 0.3
#    margin = spread * 20

#    CurrencyPair = 'GBPUSD'
#    currency = Currency(CurrencyPair)
#    price2pips = 10000
#    spread = 1.0
#    margin = spread * 20

    integratedGain = 0.0

    def __init__(self, position, units = 10000):
        Position.currency.refresh()
        self.entryTime = Position.currency.get_trade_datetime().split(' UTC')[0]
        self.entryPrice = self.getRate()

        self.position = position
        self.exitPrice = round(self.entryPrice + (self.sign() * Position.margin / Position.price2pips), 4)

        self.units = units
        self.gain = round(-1 * Position.spread, 1)
        self.margin = Position.margin - Position.spread

        self.displayInfo()

    def sign(self):
        return -1 if self.position == Long else (1 if self.position == Short else 0)

    def getRate(self, type = 'float'):
        price = Position.currency.get_rate()
        return float(price) if type == 'float' else price

    def refresh(self):
        Position.currency.refresh()
        self.gain = round(self.sign() * Position.price2pips * (self.entryPrice - self.getRate()) - Position.spread, 1)
        self.margin = (self.exitPrice - self.getRate()) * Position.price2pips * self.sign() - Position.spread

        if Position.margin < self.margin:
            self.exitPrice = round(self.getRate() + (self.sign() * Position.margin / Position.price2pips), 4)

        if self.margin < 0:
            Position.integratedGain = round(Position.integratedGain + self.gain, 1)
            self.displayInfo()
            self.cut()
            return True
        else:
            self.displayInfo()
            return False        

    def cut(self):
        print()

    def displayInfo(self):
        print(128 * '\b')

        if self.position == Long:
            coloredPrint('LONG : ', 'magenta')
        else:
            coloredPrint('SHORT: ', 'cyan')

        coloredPrint(format(self.entryPrice, '.4f'))
        coloredPrint(' (' + self.entryTime + ') -> ', 'white', '')
        coloredPrint(self.getRate('str'), 'yellow')
        coloredPrint(' (LC = ' + format(self.exitPrice, '.4f') + ')', 'white', '')

        if 0 < self.gain:
            coloredPrint('\t+' + str(self.gain) + 'pips', 'green')
        else:
            coloredPrint('\t' + str(self.gain) + 'pips', 'red')

        if Position.integratedGain < 0:
            coloredPrint('\ttotal = ' + str(Position.integratedGain) + 'pips', 'red')
        else:
            coloredPrint('\ttotal = +' + str(Position.integratedGain) + 'pips', 'green')


def nextPosition(previousPrice, price, previousPosition, previousGain):

    if previousGain == 0 or previousPosition == None:
        if previousPrice < price:
            return Long
        else:
            return Short
    else:
        return previousPosition if 0 < previousGain else not previousPosition


if __name__ == '__main__':

    previousPrice = float(Position.currency.get_rate())
    previousPosition = None
    previousGain = 0
    positionObj = None
    
    while not time.sleep(1):
        Position.currency.refresh()

        if positionObj == None:
            positionObj = Position(nextPosition(previousPrice, float(Position.currency.get_rate()), previousPosition, previousGain))
            continue

        elif positionObj.refresh():
            previousGain = positionObj.gain
            previousPosition = positionObj.position
            previousPrice = float(Position.currency.get_rate())
            positionObj = None

