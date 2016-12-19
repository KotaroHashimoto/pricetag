//+------------------------------------------------------------------+
//|                                                    StopEater.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//#include <fxlabsnet.mqh>

#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- buffers
double ExtMapBuffer1[];
double ExtMapBuffer2[];


// the start time of the last bar that contained data returned by the fxlabs server
int lastts = 0;     

// the time of the last data point that was returned by the fxlabs server
int lastdatapt = 0; 

// the time of the last call out to the fxlabs server
int lastcall = 0; 

bool fatal_error = false; 

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
//  init_fxlabs(); 
  lastts = 0; 
  lastdatapt = 0; 
  lastcall = 0; 
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
  
bool checkArrayResize(int newsz, int sz)
{
   if (newsz != sz) 
   {
      Alert("ArrayResize failed"); 
      return(false); 
   }
   return(true); 
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   // the bounds of our fxlabs request   
//   datetime timemin = Time[limit-1];
//   datetime timemax = MathMin(Time[0] + Period()*60, TimeCurrent()); 
   
   Print("Time[0] = ", Time[0]);
   Print("Bars = ", Bars);
   Print("IndicatorCounted() = ", IndicatorCounted());
   Print("Period() = ", Period());
   Print("TimeCurrent() = ", TimeCurrent());
  }
//+------------------------------------------------------------------+
