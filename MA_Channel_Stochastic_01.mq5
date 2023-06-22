//+------------------------------------------------------------------+
//|                                     MA_Channel_Stochastic_01.mq5
//|                              Copyright 2023, Automatic Forex LLC
//|                                             https://www.mql5.com
//|
//| This MQL5 Expert Advisor script automates alerts for 
//| the following strategy:
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

#define MAX_TRADES 4
#define EXPERT_MAGIC 222   // MagicNumber of the expert

#define LONG_STOCHASTIC 65.0
#define SHORT_STOCHASTIC 35.0
#define VERY_HIGH_STOCHASTIC 90.0
#define VERY_LOW_STOCHASTIC 10.0
#define REVERSAL_LONG_STOCHASTIC 15.0
#define REVERSAL_SHORT_STOCHASTIC 85.0
#define CONFIRM_REVERSAL_LONG 25.0
#define CONFIRM_REVERSAL_SHORT 75.0

#define CHIME_REPEATS 20
#define CHIME_DELAY 2000

// Signal names
#define NO_SIGNAL 0
#define UPTREND_STOCH_CROSS 1
#define DOWNTREND_STOCH_CROSS 2
#define REVERSAL_LONG_CROSS 3
#define REVERSAL_SHORT_CROSS 4
#define REVERSAL_LONG_CONFIRM 5
#define REVERSAL_SHORT_CONFIRM 6
#define VERY_HIGH_STOCH 7
#define VERY_LOW_STOCH 8
#define VERY_HIGH_CROSS 9
#define VERY_LOW_CROSS 10

//--- input parameters
input int K_Period = 14;  // Period for the %K line
input int D_Period = 3;   // Period for the %D line
input int Slowing = 3;    // Slowing parameter

datetime LastSignal = D'1980.07.19 12:30:27';
int i = 0;
int CurrSignal = NO_SIGNAL;
int PrevSignal = NO_SIGNAL;

double Karray[];
double Darray[];
double MASlowHigharray[];
double MASlowLowarray[];
double MAFastHigharray[];
double MAFastLowarray[];

void PlayChimeForBar()
{
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
   double KValuePrev = Karray[1];
   double DValuePrev = Darray[1];
   double KValuePrevPrev = Karray[2]; // Index 2 looks at two bars ago.
   double DValuePrevPrev = Darray[2]; // Index 2 looks at two bars ago.
   double MASlowHighCurr = MASlowHigharray[0];
   double MASlowLowCurr = MASlowLowarray[0];
   double MAFastHighCurr = MAFastHigharray[0];
   double MAFastLowCurr = MAFastLowarray[0];

   PlaySound(NULL);

   // Alerts for very low and very high Stochastic crosses
   //
   if (KValueCurr > DValueCurr &&
       KValuePrevPrev < VERY_LOW_STOCHASTIC &&
       KValuePrevPrev <= DValuePrevPrev && KValuePrev > DValuePrev)
   {
      Comment(StringFormat("\nVERY LOW CROSS, BUY SIGNAL!\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
              MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev));

      CurrSignal = VERY_LOW_CROSS;
      if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

      PlayChimeForBar();
   }
   else
   if (KValueCurr < DValueCurr &&
       KValuePrevPrev > VERY_HIGH_STOCHASTIC &&
       KValuePrevPrev >= DValuePrevPrev && KValuePrev < DValuePrev)
   {
      Comment(StringFormat("\nVERY HIGH CROSS, SELL SIGNAL!\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
              MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev));

      CurrSignal = VERY_HIGH_CROSS;
      if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

      PlayChimeForBar();
   }
   else
   // Alerts for possible reversal Stochastic crosses
   //
   if (DValuePrev < REVERSAL_LONG_STOCHASTIC &&
       KValuePrev <= DValuePrev && KValueCurr > DValueCurr)
   {
      Comment(StringFormat("\nREVERSAL LONG STOCHASTIC CROSS SEEN\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
              MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev));

      CurrSignal = REVERSAL_LONG_CROSS;
      if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

      PlayChimeForBar();
   }
   else
   if (DValuePrev > REVERSAL_SHORT_STOCHASTIC &&
       KValuePrev >= DValuePrev && KValueCurr < DValueCurr)
   {
      Comment(StringFormat("\nREVERSAL SHORT STOCHASTIC CROSS SEEN\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
              MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev));

      CurrSignal = REVERSAL_SHORT_CROSS;
      if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

      PlayChimeForBar();
   }

   // Alerts for confirmation of reversal Stochastic crosses
   //
   if (PrevSignal == REVERSAL_LONG_CROSS &&
       DValuePrev <= CONFIRM_REVERSAL_LONG &&
       DValueCurr > CONFIRM_REVERSAL_LONG)
   {
      Comment(StringFormat("\n*** CONFIRMED *** REVERSAL LONG STOCHASTIC CROSS SEEN\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
              MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev));

      CurrSignal = REVERSAL_LONG_CONFIRM;
      if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

      PlayChimeForBar();
   }
   else
   if (PrevSignal == REVERSAL_SHORT_CROSS &&
       DValuePrev >= CONFIRM_REVERSAL_SHORT &&
       DValueCurr < CONFIRM_REVERSAL_SHORT)
   {
      Comment(StringFormat("\n*** CONFIRMED *** REVERSAL SHORT STOCHASTIC CROSS SEEN\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
              MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev));

      CurrSignal = REVERSAL_SHORT_CONFIRM;
      if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

      PlayChimeForBar();
   }
   else
   // Alerts for potential profit-taking
   //
   if (KValueCurr > DValueCurr &&
       DValueCurr >= VERY_HIGH_STOCHASTIC)
   {
      Comment(StringFormat("\nVERY HIGH STOCHASTIC, CLOSE LONG?\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
              MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev));

      CurrSignal = VERY_HIGH_STOCH;
      if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

      PlayChimeForBar();
   }
   else
   if (KValueCurr < DValueCurr &&
       DValueCurr <= VERY_LOW_STOCHASTIC)
   {
      Comment(StringFormat("\nVERY LOW STOCHASTIC, CLOSE SHORT?\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
              MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev));

      CurrSignal = VERY_LOW_STOCH;
      if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

      PlayChimeForBar();
   }
   else
   // Alerts for trend following
   //
   if (MAFastLowCurr > MASlowHighCurr)
   {
      // We are in an uptrend.
      // Check for buy signal.
      if (KValueCurr > DValueCurr &&
          KValuePrevPrev < LONG_STOCHASTIC &&
          KValuePrevPrev <= DValuePrevPrev && KValuePrev > DValuePrev)
      {
         Comment(StringFormat("\nUPTREND, BUY SIGNAL!\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
                 MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
                 KValueCurr, DValueCurr, KValuePrev, DValuePrev));

         CurrSignal = UPTREND_STOCH_CROSS;
         if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

         PlayChimeForBar();
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
      if (KValueCurr < DValueCurr &&
          KValuePrevPrev > SHORT_STOCHASTIC &&
          KValuePrevPrev >= DValuePrevPrev && KValuePrev < DValuePrev)
      {
         Comment(StringFormat("\nDOWNTREND, SELL SIGNAL!\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f",
                 MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
                 KValueCurr, DValueCurr, KValuePrev, DValuePrev));

         CurrSignal = DOWNTREND_STOCH_CROSS;
         if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

         PlayChimeForBar();
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
