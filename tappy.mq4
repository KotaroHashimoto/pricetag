//+------------------------------------------------------------------+
//|                                                        tappy.mq4 |
//|                           Copyright 2017, Palawan Software, Ltd. |
//|                             https://coconala.com/services/204383 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Palawan Software, Ltd."
#property link      "https://coconala.com/services/204383"
#property description "Author: Kotaro Hashimoto <hasimoto.kotaro@gmail.com>"
#property version   "1.00"
#property strict

#property indicator_chart_window

extern int mailStart = 21;
extern int mailEnd = 24;

extern bool useFixedCandle = True;
extern double A = 0.0;
extern double B = 0.0;
extern double C = 0.0;
extern int X = 12;

double CrossUp[];
double CrossDown[];
int flagval1 = 0;
int flagval2 = 0;

bool ind01(bool buy) {

  double band0 = iBands(NULL, PERIOD_H1, 20, 2.0, 0, PRICE_WEIGHTED, buy ? 1 : 2, (int)useFixedCandle);
  double band1 = iBands(NULL, PERIOD_H1, 20, 2.0, 0, PRICE_WEIGHTED, buy ? 1 : 2, (int)useFixedCandle + 1);
  
  if(buy) {
    return band1 < band0;
  }
  else {
    return band1 > band0;
  }
}

bool ind02(bool buy) {
  
  bool rci0 = iCustom(NULL, PERIOD_H1, "RCI", 9, 0, (int)useFixedCandle);
  bool rci1 = iCustom(NULL, PERIOD_H1, "RCI", 9, 0, (int)useFixedCandle + 1);

  if(buy) {
    return rci1 < rci0 && -0.8 < rci0;
  }
  else {
    return rci1 > rci0 && rci0 < 0.8;
  }
}

bool ind03(bool buy) {
  
  bool rci0 = iCustom(NULL, PERIOD_H1, "RCI", 36, 0, (int)useFixedCandle);
  bool rci1 = iCustom(NULL, PERIOD_H1, "RCI", 36, 0, (int)useFixedCandle + 1);

  if(buy) {
    return rci1 < rci0 && -0.8 < rci0;
  }
  else {
    return rci1 > rci0 && rci0 < 0.8;
  }
}

bool ind04(bool buy) {

  double band0 = iBands(NULL, PERIOD_M5, 20, 2.0, 0, PRICE_WEIGHTED, buy ? 1 : 2, (int)useFixedCandle);
  double band1 = iBands(NULL, PERIOD_M5, 20, 2.0, 0, PRICE_WEIGHTED, buy ? 1 : 2, (int)useFixedCandle + 1);
  
  if(buy) {
    return band1 < band0;
  }
  else {
    return band1 > band0;
  }
}

bool ind05(bool buy) {
  
  bool rci0 = iCustom(NULL, PERIOD_M5, "RCI", 9, 0, (int)useFixedCandle);
  bool rci1 = iCustom(NULL, PERIOD_M5, "RCI", 9, 0, (int)useFixedCandle + 1);

  if(buy) {
    return rci1 < rci0 && -0.8 < rci0;
  }
  else {
    return rci1 > rci0 && rci0 < 0.8;
  }
}

bool ind06(bool buy) {
  
  bool rci0 = iCustom(NULL, PERIOD_M5, "RCI", 27, 0, (int)useFixedCandle);
  bool rci1 = iCustom(NULL, PERIOD_M5, "RCI", 27, 0, (int)useFixedCandle + 1);

  if(buy) {
    return rci1 < rci0 && -0.8 < rci0;
  }
  else {
    return rci1 > rci0 && rci0 < 0.8;
  }
}

bool ind07() {
  return A <= iATR(NULL, PERIOD_M5, 12, (int)useFixedCandle);
}

bool ind08(bool buy) {

  double atr12_0 = iATR(NULL, PERIOD_M5, 12, (int)useFixedCandle);
  double atr12_1 = iATR(NULL, PERIOD_M5, 12, (int)useFixedCandle + 1);

  double atr24_0 = iATR(NULL, PERIOD_M5, 24, (int)useFixedCandle);
  double atr24_1 = iATR(NULL, PERIOD_M5, 24, (int)useFixedCandle + 1);
  
  return atr12_1 < atr12_0 && atr24_1 < atr24_0 && B <= atr12_0;
}

bool ind09(bool buy) {
  
  bool rci0 = iCustom(NULL, PERIOD_M1, "RCI", 9, 0, (int)useFixedCandle);
  bool rci1 = iCustom(NULL, PERIOD_M1, "RCI", 9, 0, (int)useFixedCandle + 1);

  if(buy) {
    return rci1 < rci0;
  }
  else {
    return rci1 > rci0;
  }
}

bool ind10(bool buy) {

  double allig = iAlligator(NULL, PERIOD_M1, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_WEIGHTED, 1, (int)useFixedCandle);
  double rate = (Ask + Bid) / 2.0;
  
  if(buy) {
    return allig <= rate;
  }
  else {
    return rate <= allig;
  }
}

bool ind11(bool buy) {

  double rate = (Ask + Bid) / 2.0;

  if(buy) {
    return rate - Low[iLowest(NULL, PERIOD_M1, MODE_LOW, X, (int)useFixedCandle)] + C <= 2 * iATR(NULL, PERIOD_M5, 12, (int)useFixedCandle);
  }
  else {
    return High[iHighest(NULL, PERIOD_M1, MODE_HIGH, X, (int)useFixedCandle)] - rate + C <= 2 * iATR(NULL, PERIOD_M5, 12, (int)useFixedCandle);
  }
}


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexStyle(0, DRAW_ARROW, EMPTY);
   SetIndexArrow(0, 233);
   SetIndexBuffer(0, CrossUp);
   SetIndexStyle(1, DRAW_ARROW, EMPTY);
   SetIndexArrow(1, 234);
   SetIndexBuffer(1, CrossDown);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---

   int i, counter;
   double Range, AvgRange;
   int counted_bars = IndicatorCounted();

   if(counted_bars < 0)
     return(-1);
   else if(counted_bars > 0)
     counted_bars--;

   for(i = (int)useFixedCandle; i < Bars - counted_bars; i++) {
   
     for(AvgRange = 0.0, counter = (int)useFixedCandle; counter < i+9; counter++) {
       AvgRange = AvgRange + MathAbs(High[counter] - Low[counter]);
     }
     
     Range = AvgRange / 10.0;

     Print("okure ", i);
//     CrossDown[i] = 0;
     CrossUp[i] = 0;
     
     bool ind[12];
     ind[1] = ind01(True);
     ind[2] = ind02(True);
     ind[3] = ind03(True);
     ind[4] = ind04(True);
     ind[5] = ind05(True);
     ind[6] = ind06(True);
     ind[7] = ind07();
     ind[8] = ind08(True);
     ind[9] = ind09(True);
     ind[10] = ind10(True);
     ind[11] = ind11(True);

     if((ind[1] && ind[2] && ind[4] && ind[5] && (ind[7] || ind[8]) && ind[9] && ind[10] && ind[11])
     || (ind[2] && ind[3] && ind[4] && ind[5] && (ind[7] || ind[8]) && ind[9] && ind[10] && ind[11])) {
     
       CrossUp[i] = High[i] + Range * 0.75;
       if (i == 1 && flagval1 == 0) {
         flagval1 = 1;
         flagval2 = 0;
         
         int h = TimeHour(TimeLocal());
         if(mailStart < h && h < mailEnd % 24) {
           bool mail = SendMail("Buy " + Symbol(), "Buy " + Symbol() + " at " + DoubleToStr(Ask));
           Print("Buy " + Symbol() + " at " + DoubleToStr(Ask));
         }
       }
     }
     
     for(int j = 1; j < 13; i++) {
       Print("Buy " + IntegerToString(j) + ": " + DoubleToString(ind[j]));
     }
     
     ind[1] = ind01(False);
     ind[2] = ind02(False);
     ind[3] = ind03(False);
     ind[4] = ind04(False);
     ind[5] = ind05(False);
     ind[6] = ind06(False);
     ind[7] = ind07();
     ind[8] = ind08(False);
     ind[9] = ind09(False);
     ind[10] = ind10(False);
     ind[11] = ind11(False);
     
     if((ind[1] && ind[2] && ind[4] && ind[5] && (ind[7] || ind[8]) && ind[9] && ind[10] && ind[11])
     || (ind[2] && ind[3] && ind[4] && ind[5] && (ind[7] || ind[8]) && ind[9] && ind[10] && ind[11])) {
       CrossDown[i] = Low[i] - Range * 0.75;
     
       if(i == 1 && flagval2 == 0) {
         flagval2 = 1;
         flagval1 = 0;
         
         int h = TimeHour(TimeLocal());
         if(mailStart < h && h < mailEnd % 24) {
           bool mail = SendMail("Sell " + Symbol(), "Sell " + Symbol() + " at " + DoubleToStr(Bid));
           Print("Sell " + Symbol() + " at " + DoubleToStr(Bid));
         }
       }     
     }
     
     for(int j = 1; j < 13; i++) {
       Print("Buy " + IntegerToString(j) + ": " + DoubleToString(ind[j]));
     }
   }
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
