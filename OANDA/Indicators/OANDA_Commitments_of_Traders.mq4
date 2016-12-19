/**
 * OANDA Commitments of Traders Indicator. (Sample)
 * 
 * Only works with the following instruments:
 * 
 * USD_CAD, AUD_USD, GBP_USD, EUR_USD, USD_JPY, USD_MXN, NZD_USD, USD_CHF, XAU_USD, XAG_USD 
 *
 * Units returned for USD_CAD is "Contracts of CAD 100,000"
 * Units returned for AUD_USD is "Contracts of AUD 100,000"
 * Units returned for EUR_USD is "Contracts Of EUR 125,000"
 * Units returned for GBP_USD is "Contracts of GBP 62,500"
 * Units returned for USD_JPY is "Contracts of JPY 12,500,00"
 * Units returned for USD_MXN is "Contracts of MXN 500,000"
 * Units returned for NZD_USD is "Contracts of NZD 100,000"
 * Units returned for USD_CHF is "Contract of CHF 125,000"
 * Units returned for XAU_USD is "Contracts of 100 Troy Ounces"
 * Units returned for XAG_USD is "Contracts of 5,000 Troy Ounces"
 */ 

#include <fxlabsnet.mqh>

#property link        "http://www.oanda.com"
#property description "This is essentially CFTC's Non-Commercial order book. Indicator updates weekly."

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 Orange
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
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(0,ExtMapBuffer1);
   SetIndexLabel(0,"Contracts"); 
   SetIndexStyle(1,DRAW_NONE);
   SetIndexBuffer(1,RangeBuffer); 
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

   // Limit the number of calls to COT fxlabs API. (Commitments of traders data is only updated once
   // every Friday, so refreshing this data can be done infrequently.) In particular, only make
   // a call out to the fxlabs api if no call has been made in the last 24 hours, OR if the range
   // of data that MT4 expects spans more than two months (63 days in the condition below). 
   
   // When MT4 first initialzies an indicator, it will usually populate a range of data larger than
   // two months. However, it appears MT4 sometimes "re-initializes" the indicator once or twice when it 
   // first starts up (erroneously) and all data needs to be repopulated. If we only rely on the condition
   // that a call is made once every 24 hours, we will end up with no indicator data if an erroneous 
   // "re-initialization" occurs.  For this reason we rely also on the second condition. 
   // 
   int sz = 0;    

   datetime curtime = TimeCurrent();   

   bool isLastCallOld = (curtime - lastcall) > 60; 
   bool isTimeToRefresh = (curtime - lastdatapt) > 60*FXLABS_UPDATE_INTERVAL_COT;    
   bool isLargerRequest = (limit-1 - lastbar) > 1; 
   
   int ref = -1; 
   if ( (isLastCallOld && isTimeToRefresh) || isLargerRequest)
   {
      // get COT data     
      lastcall = TimeCurrent(); 
      ref = commitments(symbol); 

      if (ref >= 0) {
         sz = commitments_sz(ref);
         if (sz < 0) 
         {
            fatal_error = true; 
            Print("Error retrieving size of COT data"); 
            return(0); 
         }
      }
   }
   else 
   {
      return(0); 
   }
   

    
   int ts[];
   int ncl[]; 
   int ncs[];
   int oi[]; 
   double price[]; 

   // Resize the arrays to have enough entries to hold the returned data
   if(!checkArrayResize(ArrayResize(ts, sz), sz)) 
   {
      fatal_error = true; 
      return(0);
   }
   
   // we should check if resize worked, but
   // for brevity in this sample the check is omitted. 
   ArrayResize(ncl, sz); 
   ArrayResize(ncs, sz); 
   ArrayResize(oi, sz); 
   ArrayResize(price, sz); 

   
   if (!commitments_data(ref, ts, ncl, ncs, oi, price)) return(0);   
   
   convert_to_mt4_time_arr(ts);  
   lastdatapt = ts[sz-1]; 
   
   int j = 0; 
   while(j < sz && ts[j] < Time[limit-1])
   {
      // since we can't specify the range of data in the call to 
      // commitments(), we need to skip past the data points
      // that aren't relevant. 
      j++; 
   }
   
   
   bool lastts_updated = false; 
   for (int i = limit-1; i>=0 ; i--)
   {            
      datetime nexttime = Time[i]+Period()*60; 
      
      // calculate the average ncl for the current bar, using all 
      // the data points that fall within the bar. 
      double total = 0; 
      int num = 0; 
      
      while(j < sz && ts[j] < nexttime)
      {         
         total += ncl[j] - ncs[j];
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
            avg = ncl[sz-1] - ncs[sz-1];              
         }
         else  {         
            if (i+1 < ArraySize(ExtMapBuffer1)) avg = ExtMapBuffer1[i+1];                         
         }
         
       
      }
   
      ExtMapBuffer1[i] = avg;  
          
      if (i % 2 == 0) RangeBuffer[i] = avg; 
      else RangeBuffer[i] = 0;       
   }   
   
   commitments_free(ref); 

   return(0);
  }
//+------------------------------------------------------------------+
