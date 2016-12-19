/*
 * OANDA Spreads Indicator (Sample)
 */
#include <fxlabsnet.mqh>

#property link        "http://www.oanda.com"
#property description "Historical Spreads"

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 Red
//--- buffers
double ExtMapBuffer1[];

// RangeBuffer is a hidden buffer used to ensure that MT4 plots the 
// ExtMapBuffer1 data properly, even when that buffer contains
// larger chunks of monotone data. 
double RangeBuffer[]; 

// the start time of the last bar that contained data returned by the fxlabs server
int lastts = 0;     

// the time of the last data point that was returned by the fxlabs server
int lastdatapt = 0; 

// the time of the last call out to the fxlabs server
int lastcall = 0; 

bool fatal_error = false; 

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
  init_fxlabs(); 
  fatal_error = false; 
  lastts = 0;    
  lastdatapt = 0;
  lastcall = 0; 
  
//---- indicators

   //SetIndexStyle(0,DRAW_HISTOGRAM, EMPTY, 5);
   SetIndexStyle(1,DRAW_NONE);
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(0,ExtMapBuffer1);
   SetIndexBuffer(1,RangeBuffer); 
   
   SetIndexLabel(0,"Spread Pips"); 
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
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
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   
//----
   if (fatal_error) return(0); 
   int counted_bars=IndicatorCounted();
   if (counted_bars > 0) counted_bars--; 
   
   int limit = Bars-counted_bars;    
   
   if (limit == 0) return(0);

   // the bounds of our fxlabs request   
   datetime timemin = Time[limit-1];
   datetime timemax = MathMin(Time[0] + Period()*60, TimeCurrent()); 
     
   int lastbar = 0;
   
   // we may need to update more bars than suggested by the 'limit' value
   // this is because the data returned by fxlabs isn't necessarily 
   // updated with every tick. 'lastts' is the timestamp of the last fxlabs 
   // data point that we processed. If it's not zero, then we need to 
   // update at least as many bars that go back to that timestamp. 
   if (lastts != 0)
   {
      // search backwards for the bar at which to start
      for (lastbar = 0; lastbar < Bars; lastbar++)
      {
         if (lastts >= Time[lastbar] && lastts < Time[lastbar]+Period()*60)
         {            
            break;
         }
      }
      // mt4 may sometimes tell us that there are more bars to be updated
      // than suggested by the lastts param. If this is the case, then 
      // we keep the limit and timemin values as they are, otherwise we 
      // update them below. 
      if (lastbar+1 > limit) 
      {        
         limit = lastbar+1; 
         timemin = lastts; 
      }      
   }  
         
   string symbol = Symbol(); 
   int pos = StringLen(symbol)-3; 
   symbol = StringConcatenate(StringSubstr(symbol, 0, pos), "_", StringSubstr(symbol, pos));

   int sz = 0;    

   // If we haven't requested new data recently, OR the length of the interval is large enough, 
   // then make the request to the fxlabs API. Otherwise, 
   // it's likely that the fxlabs server will return an empty data set. In this case, we skip making 
   // the request. (Making a large number of repeated requests can lead to the fxlabs server rate 
   // limiting us. If  no data is being returned by a request, we avoid making the request which 
   // would increase the chance of being rate limited.) 
   
   datetime curtime = TimeCurrent();   
   
   bool isLastCallOld = (curtime - lastcall) > 60; 
   bool isTimeToRefresh = (curtime - lastdatapt) > 60*FXLABS_UPDATE_INTERVAL_SPR;    
   bool isLargerRequest = (limit-1 - lastbar) > 1; 
   
   int ref = -1; 
   
   if ((isLastCallOld && isTimeToRefresh) || isLargerRequest)
   {         
   
      lastcall = TimeCurrent();    
      // get spread data      
      ref = spreads(symbol, timemax-timemin, true, true);      
   
      if (ref >= 0) {
         sz = spreads_avg_sz(ref);
         if (sz < 0) 
         {
            fatal_error = true; 
            Print("Error retrieving size of Spreads data"); 
            return(0); 
         }
      }
   }

   if (sz == 0) {   
   
      if (lastts != 0) {
      // there's no new data from fxLabs API but we need to update data for new candlesticks, 
      // so fill in the data from the latest buffer entries. 
         for (int k = limit-1; k >= 0; k--)
         {            
            ExtMapBuffer1[k] = ExtMapBuffer1[k+1];
            if (k%2 == 0) RangeBuffer[k] = ExtMapBuffer1[k];
            else RangeBuffer[k] = 0; 
         }   
      }
      return(0); 
   }
   
   int ts[];
   double spread[];

   // Resize the arrays to have enough entries to hold the returned data
   if(!checkArrayResize(ArrayResize(ts, sz), sz)) 
   {
      fatal_error = true; 
      return(0);
   }
   if(!checkArrayResize(ArrayResize(spread, sz), sz)) 
   {
      fatal_error = true; 
      return(0);
   }
   
   if (!spreads_avg(ref, ts, spread)) return(0);   
   
   convert_to_mt4_time_arr(ts);  
   lastdatapt = ts[sz-1]; 
   
   int j = 0; 
   bool lastts_updated = false; 
   for (int i = limit-1; i>=0 ; i--)
   {            
      datetime nexttime = Time[i]+Period()*60; 
      
      // calculate the average spread for the current bar, using all 
      // the spread data points that fall within the bar. 
      double total = 0; 
      int num = 0; 
      while(j < sz && ts[j] < nexttime)
      {         
         total += spread[j];
         num++; 
         j++; 
      }
      
      if (j >= sz && !lastts_updated) 
      {
         lastts_updated = true; 
         lastts = Time[i]; 
      }
      
      double avg = 0.0; 
      if (num > 0) {
         avg = total/num;               
      }
      else
      {
         // corner cases when there's no data for the current bar
         if (sz > 0 && j >= sz) {
            avg = spread[sz-1];              
         }
         else  {         
            if (i+1 < ArraySize(ExtMapBuffer1)) avg = ExtMapBuffer1[i+1];                         
         }
         
       
      }
   
      ExtMapBuffer1[i] = avg;  
          
      if (i % 2 == 0) RangeBuffer[i] = avg; 
      else RangeBuffer[i] = 0;       
   }
   spreads_free(ref); 
//----
   return(0);
  }
//+------------------------------------------------------------------+
