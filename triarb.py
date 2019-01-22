#!/usr/bin/env python3
# -*- coding: utf-8 -*-

Trex_Key = ''
Trex_Secret = ''
    
THRESHOLD = 0.005
INTERVAL = 3 #sec


from bittrex.bittrex import Bittrex
import sys, os
import time
import traceback

class Trex:

    public = None
    private = None

    def __init__(self):
        
        Trex.public = Bittrex('', '')
        Trex.private = Bittrex(Trex_Key, Trex_Secret)

    def getBalance(self, symbol):
        symbol += 'T' if symbol == 'USD' else ''
        ret = Trex.private.get_balance(symbol)['result']
        return (ret['Balance'] if ret['Balance'] else 0.0, ret['Available'] if ret['Available'] else 0.0)

    def symbol2pair(self, symbol):
        
        base = symbol[3:]
        base += 'T' if base == 'USD' else ''
        market = symbol[:3]

        return base + '-' + market

    def pair2symbol(self, pair):
        base = pair.split('-')[0][:3]
        market = pair.split('-')[1]
        return market + base

    def getOrder(self, symbol):
        
        pair = self.symbol2pair(symbol)
        res = Trex.private.get_open_orders(pair)['result']

        ot = {'LIMIT_SELL':'sell', 'LIMIT_BUY':'buy'}
        order = {'sell':None,'buy': None}
        for c in res:
            if c['Exchange'] == pair:
                order[ot[c['OrderType']]] = c['OrderUuid']
                if order['sell'] and order['buy']:
                    break

        return order

    def cancelOrder(self, uuid):    
        return Trex.private.cancel(uuid)['success']
            
    def getRate(self, symbol):

        pair = self.symbol2pair(symbol)
        res = Trex.public.get_market_summary(pair)['result'][0]
        return {'sell':res['Bid'], 'buy':res['Ask']}

    def sell(self, symbol, amount, rate):
        pair = self.symbol2pair(symbol)        
        return self.private.sell_limit(pair, round(amount, 8), round(rate, 8))

    def buy(self, symbol, amount, rate):
        pair = self.symbol2pair(symbol)        
        return self.private.buy_limit(pair, round(amount, 8), round(rate, 8))


class Control():

    entryAt = None
    entryTH = None

    BTCUSD = None
    ETHUSD = None
    XRPUSD = None
    
    BTC = None
    ETH = None
    XRP = None
    USD = None
    index = None
        
    def __init__(self, bittrex):

        self.bittrex = bittrex

        Control.entryAt = {}
        
        for s in ('ETHBTC', 'BTCUSD', 'XRPBTC'):
            Control.entryAt[s] = {'sell':None,'buy': None}
        
        Control.entryTH = THRESHOLD

        Control.index = 0
        self.report(True, self.getAmount()[0])

    def report(self, init, amount):

        btcusd = self.bittrex.getRate('BTCUSD')['sell']
        ethusd = self.bittrex.getRate('ETHUSD')['sell']
        xrpusd = self.bittrex.getRate('XRPUSD')['sell']

        pIndex = Control.index
        if init:
            r = range(int(24 * 3600 / INTERVAL))
            Control.BTCUSD = [btcusd for a in r]
            Control.ETHUSD = [ethusd for a in r]
            Control.XRPUSD = [xrpusd for a in r]
            Control.BTC = [amount['BTC'] for a in r]
            Control.ETH = [amount['ETH'] for a in r]
            Control.XRP = [amount['XRP'] for a in r]
            Control.USD = [amount['USD'] for a in r]
            
        else:
            Control.index = (Control.index + 1) % len(Control.BTC)
            Control.BTCUSD[Control.index] = btcusd
            Control.ETHUSD[Control.index] = ethusd
            Control.XRPUSD[Control.index] = xrpusd
            Control.BTC[Control.index] = amount['BTC']
            Control.ETH[Control.index] = amount['ETH']
            Control.XRP[Control.index] = amount['XRP']
            Control.USD[Control.index] = amount['USD']

        r = 100.0 * (1.0 - Control.BTCUSD[Control.index] / Control.BTCUSD[pIndex])
        rBTC = 'BTC = ' + str(round(btcusd, 1)) + ' USD(' + ('+' if 0 <= r else '') + str(round(r, 2)) + '%), '
        s = Control.BTC[Control.index] - Control.BTC[pIndex]
        rBTC += str(Control.BTC[Control.index]) + ' BTC(' + ('+' if 0 <= s else '') + str(s) + '); '
                                           
        r = 100.0 * (1.0 - Control.ETHUSD[Control.index] / Control.ETHUSD[pIndex])
        rETH = 'ETH = ' + str(round(ethusd, 3)) + ' USD(' + ('+' if 0 <= r else '') + str(round(r, 2)) + '%), '
        s = Control.ETH[Control.index] - Control.ETH[pIndex]
        rETH += str(Control.ETH[Control.index]) + ' ETH(' + ('+' if 0 <= s else '') + str(s) + '); '

        r = 100.0 * (1.0 - Control.XRPUSD[Control.index] / Control.XRPUSD[pIndex])
        rXRP = 'XRP = ' + str(round(xrpusd, 5)) + ' USD(' + ('+' if 0 <= r else '') + str(round(r, 2)) + '%), '
        s = Control.XRP[Control.index] - Control.XRP[pIndex]
        rXRP += str(Control.XRP[Control.index]) + ' XRP(' + ('+' if 0 <= s else '') + str(s) + '); '

        s = Control.USD[Control.index] - Control.USD[pIndex]
        rUSD = str(Control.USD[Control.index]) + ' USD(' + ('+' if 0 <= s else '') + str(s) + '); '
        
        net = (Control.BTC[Control.index] * Control.BTCUSD[Control.index]) + (Control.ETH[Control.index] * Control.ETHUSD[Control.index]) + (Control.XRP[Control.index] * Control.XRPUSD[Control.index]) + Control.USD[Control.index]
        pNet = (Control.BTC[pIndex] * Control.BTCUSD[pIndex]) + (Control.ETH[pIndex] * Control.ETHUSD[pIndex]) + (Control.XRP[pIndex] * Control.XRPUSD[pIndex]) + Control.USD[pIndex]
        vNet = (Control.BTC[pIndex] * Control.BTCUSD[Control.index]) + (Control.ETH[pIndex] * Control.ETHUSD[Control.index]) + (Control.XRP[pIndex] * Control.XRPUSD[Control.index]) + Control.USD[pIndex]

        pBTC = 100.0 * Control.BTC[Control.index] * Control.BTCUSD[Control.index] / net
        pETH = 100.0 * Control.ETH[Control.index] * Control.ETHUSD[Control.index] / net
        pXRP = 100.0 * Control.XRP[Control.index] * Control.XRPUSD[Control.index] / net
        pUSD = 100.0 * Control.USD[Control.index] / net

        vr = 100.0 * (1.0 - net / vNet)
        r = 100.0 * (1.0 - net / pNet)
        rNet = str(round(net, 1)) + ' USD (r:' + ('+' if 0 <= vr else '') + str(round(vr, 2)) + '%, a:' + ('+' if 0 <= r else '') + str(round(r, 2)) + '%)'
        pNet = 'BTC(' + str(round(pBTC, 1)) + '):' + 'ETH(' + str(round(pETH, 1)) + '):' + 'XRP(' + str(round(pXRP, 1)) + '):' + 'USD(' + str(round(pUSD, 1)) + '), '

        return rNet, (pNet + rBTC + rETH + rXRP + rUSD)

    def getRate(self):

        rates = {}        
        for s in ('ETHBTC', 'BTCUSD', 'XRPBTC'):
            rates[s] = self.bittrex.getRate(s)

        return rates

    def getAmount(self):

        amount = {}
        avail = {}
        for s in ('BTC', 'ETH', 'XRP', 'USD'):
            b, a = self.bittrex.getBalance(s)
            amount[s] = b
            avail[s] = a
                    
        return amount, avail

    def getOrders(self):

        orders = {}
        for s in ('ETHBTC', 'BTCUSD', 'XRPBTC'):
            orders[s] = self.bittrex.getOrder(s)

            for t in ('sell', 'buy'):
                if not orders[s][t]:
                    Control.entryAt[s][t] = None

        rStr = ''
        for symbol, order in orders.items():
            rStr += ' ' + symbol + ':'
            for t, p in order.items():
                if p:
                    rStr += t + ','
                        
        return orders, rStr

    def cancelOrder(self, rates, orders):

        cancelled = False
        
        for s in ('ETHBTC', 'BTCUSD', 'XRPBTC'):
            for t in ('sell', 'buy'):
                if orders[s][t] and Control.entryAt[s][t] and rates[s][t]:
                    if 1.5 * Control.entryTH * Control.entryAt[s][t] < abs(rates[s][t] - Control.entryAt[s][t]):

                        ret = self.bittrex.cancelOrder(orders[s][t])
                        if ret:
                            Control.entryAt[s][t] = None
                            cancelled = True

                        print('Cancel', s, t, 'success' if ret else 'failed')

        return cancelled

    def sbl(self, s, t):

        if t == 'buy':
            return s[3:]
        elif t == 'sell':
            return s[0:3]
            
    def placeOrders(self, rates, amount, orders):

        placed = False

        for s in ('ETHBTC', 'BTCUSD', 'XRPBTC'):
            for t in ('sell', 'buy'):

                if orders[s][t]:
                    Control.entryAt[s][t] = rates[s][t] + (Control.entryTH * rates[s][t] * (1.0 if t == 'sell' else -1.0))
                    continue

                price =  rates[s][t] + (Control.entryTH * rates[s][t] * (1.0 if t == 'sell' else -1.0))
                lot = 0.001 * (1.0 if s[3:] == 'USD' else 1.0 / price)
                required = lot * (1.0 if t == 'sell' else price)
                
                if (not Control.entryAt[s][t]) and (required < amount[self.sbl(s, t)]) and rates[s][t]:

                    if Control.entryTH <= abs(rates[s]['buy'] - rates[s]['sell']) / ((rates[s]['buy'] + rates[s]['sell']) / 2.0):
                        print(s + ' spread wider than 1%(' + abs(rates[s]['buy'] - rates[s]['sell']) / ((rates[s]['buy'] + rates[s]['sell']) / 2.0) * 100.0 + '%), skip placing orders.')
                        continue

                    if t == 'sell':
                        ret = self.bittrex.sell(s, lot, price)
                    elif t == 'buy':
                        ret = self.bittrex.buy(s, lot, price)

                    if ret['success']:
                        Control.entryAt[s][t] = price                        
                        placed = True

                    print(s, t, lot, price)
                    print(ret)

        return placed

    
if __name__ == '__main__':

    ctrl = Control(Trex())

    counter = -1

    while True:

        try:
            rates = ctrl.getRate()
            amount, available = ctrl.getAmount()

            orders, rStr = ctrl.getOrders()
            ctrl.cancelOrder(rates, orders)
            time.sleep(INTERVAL)
            
            ctrl.placeOrders(rates, available, orders)            
            time.sleep(INTERVAL)

            counter += 1
            if counter % 20 == 0:
                subject, text = ctrl.report(False, amount)
                os.system('py mail.py  \"yahoo\" \"hasimoto.kotaro@gmail.com\" \"' + subject + '\" \"' + text + rStr + '\"')                                

        except Exception as e:
            counter = -1
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            print(exc_type, fname, exc_tb.tb_lineno)

            traceback.print_exc()
            print(e)
            time.sleep(10 * INTERVAL)


            
