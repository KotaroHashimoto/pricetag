#!/usr/bin/env python3

import csv
import pybitflyer
from math import sqrt, floor
from json import load
from datetime import datetime
from threading import Thread
from time import sleep
from oandapy import API
import ssl
from sys import version_info, exit

import os
import sys
import requests
import hashlib
import hmac
import json
from hashlib import md5
import base64
import uuid
from QuoineApiSettings import Settings
from QuoineApiUtility import TimestampGMT, GetAPIKey

if version_info.major == 2 and version_info.minor == 7:
    from urllib2 import urlopen, Request
    from Tkinter import *
elif version_info.major == 3 and version_info.minor == 6:
    from urllib.request import urlopen, Request
    from tkinter import *
else:
    print('Please install python2.7.x or python3.6.x')
    exit(1)


class Arbitrage(Thread):

    BF_BID = 0
    BF_ASK = 0
    QN_ASK = 0
    QN_BID = 0
    SELL_BF_AMOUNT = 0
    BUY_BF_AMOUNT = 0
    SELL_QN_AMOUNT = 0
    BUY_QN_AMOUNT = 0

    BF_BUY = True
    BF_SELL = False
    MAXLOTS = 1.0
    LENGTH = 3600.0

    def __init__(self, root):
        Thread.__init__(self)

        self.sell_bf_ave = 0
        self.sell_bf_sig = 0
        self.buy_bf_ave = 0
        self.buy_bf_sig = 0
        self.max_index = 0
        self.profit = 0

        self.str = StringVar()
        self.str.set('')
        self.label = Label(root, textvariable = self.str, font = (Window.FONT, Window.FSIZE))
        self.label.pack()

        self.index = 0
        self.sellBFHist = []
        self.buyBFHist = []

        self.max_index = int(Arbitrage.LENGTH / Window.PERIOD)

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

    def trimQmount(a, b, m):

        t = a if a < b else b
        t = t if t < m else m
        t = floor(t * 100.0) / 100.0 # 0.01 BTC is the minumum lot
        return t if 0.0 < t else 0.0

    def orderQuoine(self, side, amount):

        order = {}
        order['order_type'] = 'market'
        order['product_id'] = 5 #BTCJPY
        order['side'] = side
        order['quantity'] = amount
        order['leverage_level'] = 10
        order['price'] = str(Arbitrage.QN_BID if side == 'sell' else Arbitrage.QN_ASK)
        order['order_direction'] = 'one_direction'
        order['currency_pair_code'] = 'BTCJPY'
        order['product_code'] = 'CASH'


        user_agent = Quoine.api.UserAgent
        data = str(order)
        ctype = Quoine.api.ContentType
        cMD5 = base64.b64encode(md5.new(data).digest())
        print("MD5 :" +  cMD5)

        nonce = str(uuid.uuid4()).upper().replace("-","")[0:32]
        print("Nonce : " + nonce + " " + str(len(nonce)))

        uri = Quoine.api.AddOrderURI
        theDate = TimestampGMT()
        cstr = "%s,,%s,%s,%s" % (ctype,uri,theDate,nonce)
        print("Canonical String :" + cstr)

        key = api.UserSecret
        print("API Secret : " + key)

        hash = hmac.new(bytes(key), bytes(cstr),hashlib.sha1).digest()
        print("B64 HASH : " + base64.encodestring(hash))

        auth_str = "%s %s:%s" % ('APIAuth', api.UserId, base64.b64encode(hash))
        print("Authorization : " + auth_str)

        Quoine.HDRS = {'User-Agent' : api.UserAgent,'NONCE': nonce,'Date': theDate, 'Content-Type': api.ContentType, 'Authorization': auth_str }

        Quoine.URL = api.BaseURL  + uri
        print("URL : ", Quoine.URL)



        request = {}
        request['order'] = order

        try:
            response = requests.post(Quoine.URL, data = json.dumps(request), headers = Quoine.HDRS)
            print(response.status_code)
            print(response.text)
            print(response.headers)

        except requests.exceptions.HTTPError as e: 
            print("Error: \n")
            print(e)

    def placeRealOrder(self, signal):

        positions = BitFlyer.api.getpositions(product_code = 'FX_BTC_JPY')
        totalPosLot = 0.0

        for pos in positions: # for close orders
            totalPosLot = totalPosLot + pos['size']

            if pos['side'] == 'BUY':
                if 'SELL' in signal:
                    a = self.trimAmount(Arbitrage.SELL_BF_AMOUNT, Arbitrage.BUY_QN_AMOUNT, pos['size'])
                    self.orderQuoine('buy', str(a))
                    BitFlyer.api.sendchildorder(product_code = 'FX_BTC_JPY', child_order_type = 'MARKET', side = 'SELL', size = a)

            elif pos['side'] == 'SELL':
                if 'BUY' in signal:
                    a = self.trimAmount(Arbitrage.BUY_BF_AMOUNT, Arbitrage.SELL_QN_AMOUNT, pos['size'])
                    self.orderQuoine('sell', str(a))
                    BitFlyer.api.sendchildorder(product_code = 'FX_BTC_JPY', child_order_type = 'MARKET', side = 'BUY', size = a)

        if 'STRONG BUY' in signal:
            a = self.trimAmount(Arbitrage.BUY_BF_AMOUNT, Arbitrage.SELL_QN_AMOUNT, Arbitrage.MAXLOTS - totalPosLot)
            if 0.0 < a:
                self.orderQuoine('sell', str(a))
                BitFlyer.api.sendchildorder(product_code = 'FX_BTC_JPY', child_order_type = 'MARKET', side = 'BUY', size = a)
        elif 'STRONG SELL' in signal:
            a = self.trimAmount(Arbitrage.SELL_BF_AMOUNT, Arbitrage.BUY_QN_AMOUNT, Arbitrage.MAXLOTS - totalPosLot)
            if 0.0 < a:
                self.orderQuoine('buy', str(a))
                BitFlyer.api.sendchildorder(product_code = 'FX_BTC_JPY', child_order_type = 'MARKET', side = 'SELL', size = a)


    def placeOrder(self, signal, bfSell, bfBuy):

        if self.posType == None:
            
            if 'STRONG BUY' in signal:
                self.entryPrice = bfBuy
                self.posType = Arbitrage.BF_BUY
            elif 'STRONG SELL' in signal:
                self.entryPrice = bfSell
                self.posType = Arbitrage.BF_SELL
                
        else:
            if self.posType == Arbitrage.BF_BUY:
                if 'SELL' in signal:
                    self.profit = self.profit + bfSell - self.entryPrice
                    self.entryPrice = 0
                    self.posType = None

            elif self.posType == Arbitrage.BF_SELL:
                if 'BUY' in signal:
                    self.profit = self.profit + self.entryPrice - bfBuy
                    self.entryPrice = 0
                    self.posType = None

        fProfit = 0
        pos = ''
        if self.posType == Arbitrage.BF_BUY:
            fProfit = bfSell - self.entryPrice
            pos = ' LONG'
        elif self.posType == Arbitrage.BF_SELL:
            fProfit = self.entryPrice - bfBuy
            pos = ' SHORT'
        
        self.strProfit.set('Profit:\t' + str(self.profit) + ' (' + str(fProfit) + ')\t' + pos)

    def signal(self):
       
        ret = 'STAY'

        if self.buy_bf_ave < self.sellBFHist[self.index]:
            ret = 'WEAK SELL BF'
            if self.buy_bf_ave + self.buy_bf_sig < self.sellBFHist[self.index]:
                ret = 'STRONG SELL BF'

        if self.buyBFHist[self.index] < self.sell_bf_ave:
            ret = 'WEAK BUY BF'
            if self.buyBFHist[self.index] < self.sell_bf_ave - self.sell_bf_sig:
                ret = 'STRONG BUY BF'

        self.strSignal.set(ret)
        return ret

    def calc(self):

        length = len(self.sellBFHist)
        self.sell_bf_ave = sum(self.sellBFHist) / length
        self.buy_bf_ave = sum(self.buyBFHist) / length

        self.sell_bf_sig = sqrt(sum([(self.sell_bf_ave - v) ** 2 for v in self.sellBFHist]) / length)
        self.buy_bf_sig = sqrt(sum([(self.buy_bf_ave - v) ** 2 for v in self.buyBFHist]) / length)

        self.strStat.set('Average:\t' + str(int(self.sell_bf_ave)) + ' (sig:' + str(int(self.sell_bf_sig)) + ')\t'  + str(int(self.buy_bf_ave)) + '  (sig:' + str(int(self.buy_bf_sig)) + ')')

    def run(self):

        while True:
            if Arbitrage.BF_BID == 0.0 or Arbitrage.BF_ASK == 0.0 or Arbitrage.QN_ASK == 0.0 or Arbitrage.QN_BID == 0.0:
                continue
                sleep(Window.PERIOD)
            else:                
                break

        while True:

            a = str(int(Arbitrage.BF_BID - Arbitrage.QN_ASK))
            b = str(round(Arbitrage.SELL_BF_AMOUNT, 3) if Arbitrage.SELL_BF_AMOUNT < Arbitrage.BUY_QN_AMOUNT else round(Arbitrage.BUY_QN_AMOUNT, 3))

            c = str(int(Arbitrage.BF_ASK - Arbitrage.QN_BID))
            d = str(round(Arbitrage.BUY_BF_AMOUNT, 3) if Arbitrage.BUY_BF_AMOUNT < Arbitrage.SELL_QN_AMOUNT else round(Arbitrage.SELL_QN_AMOUNT, 3))

            self.str.set('Market:\t' + a + ' (lot:' + b + ')\t' + c + ' (lot:' + d + ')')

            if len(self.sellBFHist) == self.max_index:
                self.sellBFHist[self.index] = Arbitrage.BF_BID - Arbitrage.QN_ASK
                self.buyBFHist[self.index] = Arbitrage.BF_ASK - Arbitrage.QN_BID
            else:
                self.sellBFHist.append(Arbitrage.BF_BID - Arbitrage.QN_ASK)
                self.buyBFHist.append(Arbitrage.BF_ASK - Arbitrage.QN_BID)

            self.calc()
            signal = self.signal()

            self.index = self.index + 1
            if self.index == self.max_index:
                self.index = 0

            if Arbitrage.LENGTH / 2.0 < len(self.sellBFHist) or True:
                self.placeOrder(signal, Arbitrage.BF_BID - Arbitrage.QN_ASK, Arbitrage.BF_ASK - Arbitrage.QN_BID)
#                self.placeRealOrder(signal)

            sleep(Window.PERIOD)

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

            except Exception as e:
                print(e)
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


class Quoine(Thread):

    api = None
    URL = None
    HDRS = None

    def __init__(self, root):
        Thread.__init__(self)
    
        self.name = 'Quoine'

        Quoine.api = Settings()

        self.str = StringVar()
        self.str.set('')
        self.label = Label(root, textvariable = self.str, font = (Window.FONT, Window.FSIZE))
        self.label.pack()

        self.last = 0
        self.update()

    def status(self):

        Arbitrage.QN_BID = self.bid
        Arbitrage.QN_ASK = self.ask
        Arbitrage.SELL_QN_AMOUNT = self.bid_size
        Arbitrage.BUY_QN_AMOUNT = self.ask_size

    def update(self):

        url = Quoine.api.BaseURL + Quoine.api.GetPriceLadderURI % '5'
        r = requests.get(url)
        if r.status_code == 200:
            if r.text == "null":
                print("No content returned for URL %s" % url)
            else:
                data = json.loads(r.text)

                self.ask = float(data['sell_price_levels'][0][0])
                self.ask_size = float(data['sell_price_levels'][0][1])

                self.bid = float(data['buy_price_levels'][0][0])
                self.bid_size = float(data['buy_price_levels'][0][1])

        else:
            print("\nError %s while calling URL %s:\n" % (r.status_code,url))

        self.status()


    def run(self):

        while True:
            try:
                self.update()
        
                up = self.bid
                self.label.configure(fg = ('black' if self.last == up else ('red' if self.last > up else 'green')))
                self.last = up
        
                a = str(int(self.ask))
                b = str(int(self.bid))
                d = str(int(self.ask - self.bid))

                self.str.set(self.name + (' ' * (20 - len(self.name))) + '\t' + a + ' -' + d + '- ' + b)
                sleep(Window.PERIOD)

            except Exception as e:
                print(e)
                self.label.configure(fg = 'gray')
                sleep(10)
                self.label.configure(fg = 'black')
                continue


class BitFlyer(Thread):

    api = None

    def __init__(self, root):
        Thread.__init__(self)
    
        self.name = 'biyFlyer'
        BitFlyer.api = pybitflyer.API(api_key = 'YQq4YXRj8WiRNouoeBVMiV', api_secret = 'u9/y4Nd+Pf4cR6Z/uitAYVo8b/uPzqrLTfbT0vXALN4=')
        self.pcode = 'FX_BTC_JPY'

        self.str = StringVar()
        self.str.set('')
        self.label = Label(root, textvariable = self.str, font = (Window.FONT, Window.FSIZE))
        self.label.pack()

        self.last = 0
        self.update()

    def status(self):

        Arbitrage.BF_BID = self.bid
        Arbitrage.BF_ASK = self.ask
        Arbitrage.SELL_BF_AMOUNT = self.bid_size
        Arbitrage.BUY_BF_AMOUNT = self.ask_size

    def update(self):

        self.ticker = BitFlyer.api.ticker(product_code = self.pcode)

        self.ask = self.ticker['best_ask']
        self.bid = self.ticker['best_bid']
        self.ask_size = self.ticker['best_ask_size']
        self.bid_size = self.ticker['best_bid_size']

        self.status()

    def run(self):

        while True:
            try:
                self.update()
        
                up = self.ticker['ltp']
                self.label.configure(fg = ('black' if self.last == up else ('red' if self.last > up else 'green')))
                self.last = up
        
                a = str(int(self.ask))
                b = str(int(self.bid))
                d = str(int(self.ask - self.bid))

                self.str.set(self.name + (' ' * (20 - len(self.name))) + '\t' + a + ' -' + d + '- ' + b)
                sleep(Window.PERIOD)

            except Exception as e:
                print(e)
                self.label.configure(fg = 'gray')
                sleep(10)
                self.label.configure(fg = 'black')
                continue


if __name__ == '__main__':

    ssl._create_default_https_context = ssl._create_unverified_context
    window = Window('bitFlyer - Quoine Arbitrager')

    exchangeList = tuple([ \
        window, \
        BitFlyer(window.root), \
        Quoine(window.root), \
        Arbitrage(window.root)
        ]
    )

    for e in exchangeList:
        e.setDaemon(True)
        e.start()

    window.root.mainloop()
