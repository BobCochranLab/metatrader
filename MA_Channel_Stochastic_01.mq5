//+------------------------------------------------------------------+
//|                                     MA_Channel_Stochastic_01.mq5
//|                              Copyright 2023, Automatic Forex LLC
//|                                             https://www.mql5.com
//|
//| This MQL5 Expert Advisor script automates the following strategy:
//|   1)  On a 4-hour chart, create two pairs of moving average
//|       indicators as follows:
//|       a)  72-period Simple Moving Average of the highs
//|       b)  72-period Simple Moving Average of the lows
//|       c)  12-period Exponential Moving Average of the highs
//|       d)  12-period Exponential Moving Average of the lows
//|
//|       This sets up two bands or channels.
//|
//|       When the 12-period moving average band sits above the
//|       72-period band, we consider the trend to be up.  When this
//|       condition holds true, we will only take long trades.
//|       
//|       When the 12-period moving average band sits below the
//|       72-period band, we consider the trend to be down.  When this
//|       condition holds true, we will only take short trades.
//|
//|       We do not open trades when any parts of the two bands are
//|       touching or overlapping.
//|
//|       The trade entry signal is the Stochastic indicator with
//|       a %K period of 14, a %D period of 3, and a smoothing value
//|       of 3.
//|
//|       For long trades, we look for the %K value to cross above
//|       the %D value after the %K value has dropped below the 65 level.
//|
//|       For short trades, we look for the %K line to cross below
//|       the %D value after the %K value has risen above the 35 level.
//|
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Automatic Forex LLC"
#property link      "https://www.mql5.com"
#property version   "1.00"

#define EXPERT_MAGIC 222   // MagicNumber of the expert
#define LONG_STOCHASTIC 65.0
#define SHORT_STOCHASTIC 35.0
#define VERY_HIGH_STOCHASTIC 93.0
#define VERY_LOW_STOCHASTIC 7.0
#define MAX_TRADES 4
#define CHIME_REPEATS 20
#define CHIME_DELAY 2000

//--- input parameters
input int K_Period = 14;  // Period for the %K line
input int D_Period = 3;   // Period for the %D line
input int Slowing = 3;    // Slowing parameter

datetime LastTrade = D'1980.07.19 12:30:27';
int i = 0;

double Karray[];
double Darray[];
double MASlowHigharray[];
double MASlowLowarray[];
double MAFastHigharray[];
double MAFastLowarray[];

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   ArraySetAsSeries(Karray, true);
   ArraySetAsSeries(Darray, true);
   ArraySetAsSeries(MASlowHigharray, true);
   ArraySetAsSeries(MASlowLowarray, true);
   ArraySetAsSeries(MAFastHigharray, true);
   ArraySetAsSeries(MAFastLowarray, true);
   
   int StochDef = iStochastic(_Symbol,_Period,K_Period,D_Period,Slowing,MODE_SMA,STO_LOWHIGH);
   int MASlowHighDef = iMA(_Symbol, _Period, 72, 0, MODE_SMA, PRICE_HIGH);
   int MASlowLowDef = iMA(_Symbol, _Period, 72, 0, MODE_SMA, PRICE_LOW);
   int MAFastHighDef = iMA(_Symbol, _Period, 12, 0, MODE_EMA, PRICE_HIGH);
   int MAFastLowDef = iMA(_Symbol, _Period, 12, 0, MODE_EMA, PRICE_LOW);

   CopyBuffer(StochDef,0,0,3,Karray);
   CopyBuffer(StochDef,1,0,3,Darray);
   CopyBuffer(MASlowHighDef,0,0,1,MASlowHigharray);
   CopyBuffer(MASlowLowDef,0,0,1,MASlowLowarray);
   CopyBuffer(MAFastHighDef,0,0,1,MAFastHigharray);
   CopyBuffer(MAFastLowDef,0,0,1,MAFastLowarray);
   
   double KValueCurr = Karray[0];
   double DValueCurr = Darray[0];
   double KValuePrev = Karray[1]; // Make the index 2 to look at two bars ago.
   double DValuePrev = Darray[1]; // Make the index 2 to look at two bars ago.
   double MASlowHighCurr = MASlowHigharray[0];
   double MASlowLowCurr = MASlowLowarray[0];
   double MAFastHighCurr = MAFastHigharray[0];
   double MAFastLowCurr = MAFastLowarray[0];

   if (KValueCurr >= VERY_HIGH_STOCHASTIC && DValueCurr >= VERY_HIGH_STOCHASTIC)
   {
      Comment(StringFormat("\nVERY HIGH STOCHASTIC, LONG CLOSE?\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
              MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev));

      if (PositionsTotal() < MAX_TRADES &&
          LastSignal != iTime(_Symbol,_Period,0))
      {
         LastSignal = iTime(_Symbol,_Period,0);
         
         for (i = 1; i <= CHIME_REPEATS; i++)
         {
            PlaySound("alert.wav");
            Sleep(CHIME_DELAY);
         }
      }
      else
      {
         PlaySound(NULL);
      }
   }
   else
   if (KValueCurr <= VERY_LOW_STOCHASTIC && DValueCurr <= VERY_LOW_STOCHASTIC)
   {
      Comment(StringFormat("\nVERY LOW STOCHASTIC, LONG SHORT CLOSE?\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
              MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev));

      if (PositionsTotal() < MAX_TRADES &&
          LastSignal != iTime(_Symbol,_Period,0))
      {
         LastSignal = iTime(_Symbol,_Period,0);
         
         for (i = 1; i <= CHIME_REPEATS; i++)
         {
            PlaySound("alert.wav");
            Sleep(CHIME_DELAY);
         }
      }
      else
      {
         PlaySound(NULL);
      }
   }
   else
   if (MAFastLowCurr > MASlowHighCurr)
   {
      // We are in an uptrend.
      // Check for buy signal.
      if (KValuePrev < LONG_STOCHASTIC &&
          KValuePrev < DValuePrev && KValueCurr > DValueCurr)
      {
         Comment(StringFormat("\nUPTREND, BUY SIGNAL!\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
                 MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
                 KValueCurr, DValueCurr, KValuePrev, DValuePrev));

         if (PositionsTotal() < MAX_TRADES &&
             LastTrade != iTime(_Symbol,_Period,0))
         {
            LastTrade = iTime(_Symbol,_Period,0);
            
            for (i = 1; i <= CHIME_REPEATS; i++)
            {
               PlaySound("alert.wav");
               Sleep(CHIME_DELAY);
            }
         }
         else
         {
            PlaySound(NULL);
         }
      }
      else
      {
         Comment(StringFormat("\nUPTREND, No Buy Signal\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
                 MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
                 KValueCurr, DValueCurr, KValuePrev, DValuePrev));
      }
   }
   else if (MAFastHighCurr < MASlowLowCurr)
   {
      // We are in a downtrend.
      // Check for sell signal.
      if (KValuePrev > SHORT_STOCHASTIC &&
          KValuePrev > DValuePrev && KValueCurr < DValueCurr)
      {
         Comment(StringFormat("\nDOWNTREND, SELL SIGNAL!\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
                 MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
                 KValueCurr, DValueCurr, KValuePrev, DValuePrev));

         if (PositionsTotal() < MAX_TRADES &&
             LastTrade != iTime(_Symbol,_Period,0))
         {
            LastTrade = iTime(_Symbol,_Period,0);
            
            for (i = 1; i <= CHIME_REPEATS; i++)
            {
               PlaySound("alert.wav");
               Sleep(CHIME_DELAY);
            }
         }
         else
         {
            PlaySound(NULL);
         }
      }
      else
      {
         Comment(StringFormat("\nDOWNTREND, No Buy Signal\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
                 MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
                 KValueCurr, DValueCurr, KValuePrev, DValuePrev));
      }
   }
   else
   {
      Comment(StringFormat("\nNO TREND, No Trade Signal\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
              MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev));
   }
}
//+------------------------------------------------------------------+
