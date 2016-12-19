/*
 * OANDA Orderbook Indicator (Sample)
 *
 * Graphs two bars, the top one which is the percentage of long orders with trigger prices above the high price 
 * of the candle, and the lower bar which is the percentage of short orders with trigger prices below the low 
 * price of the candle. This is intended to give an idea of how strong market sentiment is that the instrument's 
 * price will increase or decrease. 
 * 
 * (This indicator sample only uses a subset of the data available through the orderbook API.) 
 */ 
#include <fxlabsnet.mqh>

#property link        "http://www.oanda.com"
#property description "OANDA's Orderbook Sample"

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 GreenYellow
#property indicator_color2 SlateBlue
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
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
  init_fxlabs(); 
  lastts = 0; 
  lastdatapt = 0; 
  lastcall = 0; 
  
//---- indicators
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(0,ExtMapBuffer1);
   SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexBuffer(1,ExtMapBuffer2);
   
   SetIndexLabel(0, "Percentage Long > Max"); 
   SetIndexLabel(1, "Percentage Short < Min"); 
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
   bool isTimeToRefresh = (curtime - lastdatapt) > 60*FXLABS_UPDATE_INTERVAL_HPR;    
   bool isLargerRequest = (limit-1 - lastbar) > 1; 
   int ref = -1; 
   if ((isLastCallOld && isTimeToRefresh) || isLargerRequest)
   {      
      // get orderbook data
      lastcall = TimeCurrent(); 
      
      ref = orderbook(symbol, timemax-timemin);
      Print("timemax = ", timemax);
      Print("timemin = ", timemin);
      Print("ref = ", ref);

      if (ref >= 0)
      {
         sz = orderbook_sz(ref);
         Print("sz = ", sz);

         if (sz < 0) 
         {
            fatal_error = true; 
            Print("Error retrieving size of Orderbook data"); 
            return(0); 
         }
      }
   }
     
   if (sz == 0)
   {
      // no data was found for the specified period, but we've already done some processing, 
      // so we can fill in data (at least for now) based on previously calculated data
      if (lastts != 0)
      {
         for (int k = limit-1; k >= 0; k--)
         {            
            ExtMapBuffer1[k] = ExtMapBuffer1[k+1];
            ExtMapBuffer2[k] = ExtMapBuffer2[k+1]; 
         }   
      }
      return(0);
   }
   
   
   int ts[];   
   int fxlabs_ts[]; 
      
   if(!checkArrayResize(ArrayResize(ts, sz), sz)) 
   {
      fatal_error = true; 
      return(0);
   }
   if(!checkArrayResize(ArrayResize(fxlabs_ts, sz), sz)) 
   {
      fatal_error = true; 
      return(0);
   }

   
   if (!orderbook_timestamps(ref, fxlabs_ts)) return(0);   

   ArrayCopy(ts, fxlabs_ts);    

   convert_to_mt4_time_arr(ts);
   lastdatapt = ts[sz-1];

   // we need to use values in the converted timestamp array (ts) when dealing with timestamps in MQL4, 
   // but need to use the original timestamps (fxlabs_ts) when calling the fxlabs interface
   
   int j = 0; 
   bool lastts_updated = false; 
   for (int i = limit-1; i>=0 ; i--)
   {            
      datetime nexttime = Time[i]+Period()*60; 
      
      // calculate the average number of orders to trigger above max price of candle, 
      // using all orderbook entries that fall within the current bar.  
      double total_high = 0.0; 
      double total_low = 0.0; 
      int num_high = 0; 
      int num_low = 0; 
      bool data_points_in_bar = false;      
      
      while(j < sz && ts[j] < nexttime)
      { 
         double old_total_high = total_high; 
         double old_total_low = total_low; 
         if (!total_at_ts(ref, fxlabs_ts[j], High[i], Low[i], total_high, total_low)) 
         {
            fatal_error = true; 
            return(0); 
         }
         
         data_points_in_bar = true; 
         if (total_high > old_total_high) num_high += 1; 
         if (total_low > old_total_low) num_low += 1;          
         j++; 
      }
      
      if (j >= sz && !lastts_updated) 
      {
         lastts_updated = true; 
         lastts = Time[i]; 
      }
      
      double avg_high = 0.0; 
      double avg_low = 0.0; 
      if (num_high > 0) avg_high = total_high/num_high; 
      if (num_low > 0) avg_low = total_low/num_low; 
      
      if (!data_points_in_bar)
      {
         // corner cases when there's no data for the current bar
         if (j == 0) 
         {              
            avg_high = 0.0; //total_high; 
            avg_low = 0.0; //total_low; 
            
         }
         else 
         {
            if (i+1 < ArraySize(ExtMapBuffer1)) avg_high = ExtMapBuffer1[i+1];                  
            if (i+1 < ArraySize(ExtMapBuffer2)) avg_low = -1*ExtMapBuffer2[i+1]; 
         }
      }
      
      
      ExtMapBuffer1[i] = avg_high;
      ExtMapBuffer2[i] = -1*avg_low; 
   }
   orderbook_free(ref); 
   
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+


bool total_at_ts(int ref, int fxlabs_ts, double high_mark, double low_mark, double& total_high, double& total_low)
{
   int pp_sz = orderbook_price_points_sz(ref, fxlabs_ts);
   double pricepoints[];
   double ps[]; 
   double pl[]; 
   double os[]; 
   double ol[]; 
         
   // we should verify ArrayResize worked, but for sake
   // of brevity we omit this from the sample code
   ArrayResize(pricepoints, pp_sz);
   ArrayResize(ps, pp_sz); 
   ArrayResize(pl, pp_sz); 
   ArrayResize(os, pp_sz); 
   ArrayResize(ol, pp_sz); 
         
   if (!orderbook_price_points(ref, fxlabs_ts, pricepoints, ps, pl, os, ol)) {
      return(false); 
   }  
                  
   for (int pp_idx = 0; pp_idx < pp_sz; pp_idx++) 
   {
      if (pricepoints[pp_idx] > high_mark) 
      {
         total_high += ol[pp_idx];               
      }
      if (pricepoints[pp_idx] < low_mark) 
      {
         total_low += os[pp_idx];                
      }               
   }
   return(true);          
}
