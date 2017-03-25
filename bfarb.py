#!/usr/bin/env python3

import csv
import pybitflyer
from math import sqrt
from json import load
from datetime import datetime
from threading import Thread
from time import sleep
from oandapy import API
import ssl
from sys import version_info, exit

if version_info.major == 2 and version_info.minor == 7:
    from urllib2 import urlopen, Request
    from Tkinter import *
elif version_info.major == 3 and version_info.minor == 6:
    from urllib.request import urlopen, Request
    from tkinter import *
else:
    print('Please install python2.7.x or python3.6.x')
    exit(1)


class Window(Thread):

    PERIOD = 1.0
    FONT = 'Arial'
    FSIZE = 12

    def __init__(self, title):
        Thread.__init__(self)
    
        self.root = Tk()
        self.root.title(title)

        self.str = StringVar()
        self.str.set('')
        Label(self.root, textvariable = self.str, font = (Window.FONT, Window.FSIZE)).pack()

        Label(text = 'Exchange' + (' '*8) + '\tAsk\tBid', font = (Window.FONT, Window.FSIZE)).pack()
        
        self.root.bind('<MouseWheel>', self.onMouseWheel)
        self.root.bind('<Up>', self.expand)
        self.root.bind('<Right>', self.expand)
        self.root.bind('<Down>', self.shrink)
        self.root.bind('<Left>', self.shrink)

    def run(self):
    
        while True:
            try:
                self.str.set(datetime.now().strftime('%Y/%m/%d  %H:%M:%S'))
                sleep(Window.PERIOD)

            except:
                sleep(10)
                continue

    def update(self, delta):
    
        Window.FSIZE = Window.FSIZE + delta
    
        for widget in self.root.children.values():
            widget.configure(font = (Window.FONT, Window.FSIZE))

    def onMouseWheel(self, mouseEvent):
        self.update(1 if 0 < mouseEvent.delta else -1)

    def expand(self, keyEvent):
        self.update(1)

    def shrink(self, keyEvent):
        self.update(-1)


class Arbitrage(Thread):

    FX_BID = 0
    FX_ASK = 0
    ASK = 0
    BID = 0
    SELL_FX_AMOUNT = 0
    BUY_FX_AMOUNT = 0
    SELL_AMOUNT = 0
    BUY_AMOUNT = 0


    SELL_FX_AVE = 0
    SELL_FX_SIG = 0
    BUY_FX_AVE = 0
    BUY_FX_SIG = 0

    MAX_INDEX = 0

    FX_BUY = True
    FX_SELL = False
    PROFIT = 0

    MAXLOTS = 1.0

    LENGTH = 3600.0

    def __init__(self, root):
        Thread.__init__(self)

        self.str = StringVar()
        self.str.set('')
        self.label = Label(root, textvariable = self.str, font = (Window.FONT, Window.FSIZE))
        self.label.pack()

        self.index = 0
        self.sellFXHist = []
        self.buyFXHist = []

        Arbitrage.MAX_INDEX = int(Arbitrage.LENGTH / Window.PERIOD)

        self.strStat = StringVar()
        self.strStat.set('')
        self.labelStat = Label(root, textvariable = self.strStat, font = (Window.FONT, Window.FSIZE))
        self.labelStat.pack()

        self.strSignal = StringVar()
        self.strSignal.set('')
        self.labelSignal = Label(root, textvariable = self.strSignal, font = (Window.FONT, Window.FSIZE))
        self.labelSignal.pack()

        self.strProfit = StringVar()
        self.strProfit.set('')
        self.labelProfit = Label(root, textvariable = self.strProfit, font = (Window.FONT, Window.FSIZE))
        self.labelProfit.pack()

        self.entryPrice = 0
        self.posType = None

        Arbitrage.MAXLOTS = 1.0

    def placeRealOrder(self, signal):

        positions = self.api.getpositions(product_code = 'FX_BTC_JPY')
        totalPosLot = 0.0

        for pos in positions: # for close orders
            totalPosLot = totalPosLot + pos['size']

#            if pos['side'] == 'BUY':
#                if 'SELL' in signal:
#                    a = Arbitrage.SELL_FX_AMOUNT if Arbitrage.SELL_FX_AMOUNT < Arbitrage.BUY_AMOUNT else Arbitrage.BUY_AMOUNT
#                    a = a if a < pos['size'] else pos['size']
#                    self.api.sendchildorder(product_code = 'BTC_JPY', child_order_type = 'MARKET', side = 'BUY', size = a)
#                    self.api.sendchildorder(product_code = 'FX_BTC_JPY', child_order_type = 'MARKET', side = 'SELL', size = a)

#            elif pos['side'] == 'SELL':
            if pos['side'] == 'SELL':
                if 'BUY' in signal:
                    a = Arbitrage.BUY_FX_AMOUNT if Arbitrage.BUY_FX_AMOUNT < Arbitrage.SELL_AMOUNT else Arbitrage.SELL_AMOUNT
                    a = pos['size'] if pos['size'] < a else a
                    self.api.sendchildorder(product_code = 'BTC_JPY', child_order_type = 'MARKET', side = 'SELL', size = a)
                    self.api.sendchildorder(product_code = 'FX_BTC_JPY', child_order_type = 'MARKET', side = 'BUY', size = a)

#        if 'STRONG BUY' in signal:
#            a = Arbitrage.BUY_FX_AMOUNT if Arbitrage.BUY_FX_AMOUNT < Arbitrage.SELL_AMOUNT else Arbitrage.SELL_AMOUNT
#            if a + totalPosLot < Arbitrage.MAXLOTS:
#                self.api.sendchildorder(product_code = 'BTC_JPY', child_order_type = 'MARKET', side = 'SELL', size = a)
#                self.api.sendchildorder(product_code = 'FX_BTC_JPY', child_order_type = 'MARKET', side = 'BUY', size = a)
#        elif 'STRONG SELL' in signal:
        if 'STRONG SELL' in signal:
            a = Arbitrage.SELL_FX_AMOUNT if Arbitrage.SELL_FX_AMOUNT < Arbitrage.BUY_AMOUNT else Arbitrage.BUY_AMOUNT
            if a + totalPosLot < Arbitrage.MAXLOTS:
                self.api.sendchildorder(product_code = 'BTC_JPY', child_order_type = 'MARKET', side = 'BUY', size = a)
                self.api.sendchildorder(product_code = 'FX_BTC_JPY', child_order_type = 'MARKET', side = 'SELL', size = a)


    def placeOrder(self, signal, fxSell, fxBuy):

        if self.posType == None:
            
            if 'STRONG BUY' in signal:
                self.entryPrice = fxBuy
                self.posType = Arbitrage.FX_BUY
            elif 'STRONG SELL' in signal:
                self.entryPrice = fxSell
                self.posType = Arbitrage.FX_SELL
                
        else:
            
            if self.posType == Arbitrage.FX_BUY:
                if 'SELL' in signal:
                    Arbitrage.PROFIT = Arbitrage.PROFIT + fxSell - self.entryPrice
                    self.entryPrice = 0
                    self.posType = None

            elif self.posType == Arbitrage.FX_SELL:
                if 'BUY' in signal:
                    Arbitrage.PROFIT = Arbitrage.PROFIT + self.entryPrice - fxBuy
                    self.entryPrice = 0
                    self.posType = None

        fProfit = 0
        pos = ''
        if self.posType == Arbitrage.FX_BUY:
            fProfit = fxSell - self.entryPrice
            pos = ' LONG'
        elif self.posType == Arbitrage.FX_SELL:
            fProfit = self.entryPrice - fxBuy
            pos = ' SHORT'
        
        self.strProfit.set('Profit:\t' + str(Arbitrage.PROFIT) + ' (' + str(fProfit) + ')\t' + pos)

    def signal(self):
       
        ret = 'STAY'

        b1 = Arbitrage.BUY_FX_AVE < self.sellFXHist[self.index]
        b2 = Arbitrage.BUY_FX_AVE + Arbitrage.BUY_FX_SIG < self.sellFXHist[self.index]
 
        if b1:
            ret = 'WEAK SELL FX'
            if b2:
                ret = 'STRONG SELL FX'

        s1 = self.buyFXHist[self.index] < Arbitrage.SELL_FX_AVE
        s2 = self.buyFXHist[self.index] < Arbitrage.SELL_FX_AVE - Arbitrage.SELL_FX_SIG

        if s1:
            ret = 'WEAK BUY FX'
            if s2:
                ret = 'STRONG BUY FX'

        self.index = self.index + 1
        if self.index == Arbitrage.MAX_INDEX:
            self.index = 0

        self.strSignal.set(ret)
        return ret

    def calc(self):

        length = len(self.sellFXHist)
        Arbitrage.SELL_FX_AVE = sum(self.sellFXHist) / length
        Arbitrage.BUY_FX_AVE = sum(self.buyFXHist) / length

        Arbitrage.SELL_FX_SIG = sqrt(sum([(Arbitrage.SELL_FX_AVE - v) ** 2 for v in self.sellFXHist]) / length)
        Arbitrage.BUY_FX_SIG = sqrt(sum([(Arbitrage.BUY_FX_AVE - v) ** 2 for v in self.buyFXHist]) / length)

        self.strStat.set('Average:\t' + str(int(Arbitrage.SELL_FX_AVE)) + ' (sig:' + str(int(Arbitrage.SELL_FX_SIG)) + ')\t'  + str(int(Arbitrage.BUY_FX_AVE)) + '  (sig:' + str(int(Arbitrage.BUY_FX_SIG)) + ')')

    def run(self):

        while True:
            if Arbitrage.FX_BID == 0.0 or Arbitrage.FX_ASK == 0.0 or Arbitrage.ASK == 0.0 or Arbitrage.BID == 0.0:
                continue
                sleep(Window.PERIOD)
            else:                
                break

        while True:

            a = str(int(Arbitrage.FX_BID - Arbitrage.ASK))
            b = str(round(Arbitrage.SELL_FX_AMOUNT, 3) if Arbitrage.SELL_FX_AMOUNT < Arbitrage.BUY_AMOUNT else round(Arbitrage.BUY_AMOUNT, 3))

            c = str(int(Arbitrage.FX_ASK - Arbitrage.BID))
            d = str(round(Arbitrage.BUY_FX_AMOUNT, 3) if Arbitrage.BUY_FX_AMOUNT < Arbitrage.SELL_AMOUNT else round(Arbitrage.SELL_AMOUNT, 3))

            self.str.set('Market:\t' + a + ' (lot:' + b + ')\t' + c + ' (lot:' + d + ')')

            if len(self.sellFXHist) == Arbitrage.MAX_INDEX:
                self.sellFXHist[self.index] = Arbitrage.FX_BID - Arbitrage.ASK
                self.buyFXHist[self.index] = Arbitrage.FX_ASK - Arbitrage.BID
            else:
                self.sellFXHist.append(Arbitrage.FX_BID - Arbitrage.ASK)
                self.buyFXHist.append(Arbitrage.FX_ASK - Arbitrage.BID)

            self.calc()
            signal = self.signal()

            if Arbitrage.LENGTH / 2.0 < len(self.sellFXHist):
#                self.placeOrder(signal, Arbitrage.FX_BID - Arbitrage.ASK, Arbitrage.FX_ASK - Arbitrage.BID)
                self.placeRealOrder(signal)

            sleep(Window.PERIOD)


class Exchange(Thread):

    def __init__(self, root, api, name, pcode):
        Thread.__init__(self)
    
        self.name = name
        self.api = api
        self.pcode = pcode

        self.str = StringVar()
        self.str.set('')
        self.label = Label(root, textvariable = self.str, font = (Window.FONT, Window.FSIZE))
        self.label.pack()

        self.last = 0
        self.update()

    def status(self):

        if self.pcode == 'BTC_JPY':
            Arbitrage.ASK = self.ask
            Arbitrage.BID = self.bid
            Arbitrage.SELL_AMOUNT = self.bid_size
            Arbitrage.BUY_AMOUNT = self.ask_size
        else:
            Arbitrage.FX_BID = self.bid
            Arbitrage.FX_ASK = self.ask
            Arbitrage.SELL_FX_AMOUNT = self.bid_size
            Arbitrage.BUY_FX_AMOUNT = self.ask_size

    def update(self):

        self.ticker = self.api.ticker(product_code = self.pcode)

        self.ask = self.ticker['best_ask']
        self.bid = self.ticker['best_bid']
        self.ask_size = self.ticker['best_ask_size']
        self.bid_size = self.ticker['best_bid_size']

    def run(self):

        while True:
            try:
                self.update()
                self.status()
        
                up = self.ticker['ltp']
                self.label.configure(fg = ('black' if self.last == up else ('red' if self.last > up else 'green')))
                self.last = up
        
                a = str(int(self.ask))
                b = str(int(self.bid))
                d = str(int(self.ask - self.bid))

                self.str.set(self.name + (' ' * (20 - len(self.name))) + '\t' + a + ' -' + d + '- ' + b)
                sleep(Window.PERIOD)

            except:
                self.label.configure(fg = 'gray')
                sleep(10)
                self.label.configure(fg = 'black')
                continue


if __name__ == '__main__':

    ssl._create_default_https_context = ssl._create_unverified_context
    window = Window('bitFlyer Arbitrager')

    api = pybitflyer.API(api_key = 'YQq4YXRj8WiRNouoeBVMiV', api_secret = 'u9/y4Nd+Pf4cR6Z/uitAYVo8b/uPzqrLTfbT0vXALN4=')

    exchangeList = tuple([ \
        window, \
        Exchange(window.root, api, 'bitFlyerFX', 'FX_BTC_JPY'), \
        Exchange(window.root, api, 'bitFlyer', 'BTC_JPY'), \
        Arbitrage(window.root)
        ]
    )

    for e in exchangeList:
        e.setDaemon(True)
        e.start()

    window.root.mainloop()
