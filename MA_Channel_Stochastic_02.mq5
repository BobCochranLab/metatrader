//+------------------------------------------------------------------+
//|                                     MA_Channel_Stochastic_02.mq5
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

#define CHIME_REPEATS 5
#define CHIME_DELAY 2000

//Signal strings
string NoSignal = "No Signal";
string UptrendStochasticCross = "Uptrend Stochastic Cross";
string DowntrendStochasticCross = "Downtrend Stochastic Cross";
string ReversalLongStochasticCross = "Reversal Long Stochastic Cross";
string ReversalShortStochasticCross = "Reversal Short Stochastic Cross";
string ReversalLongConfirmation = "Reversal Long Confirmation";
string ReversalShortConfirmation = "Reversal Short Confirmation";
string VeryHighStochastic = "Very High Stochastic";
string VeryLowStochastic = "Very Low Stochastic";
string VeryHighStochasticCross = "Very High Stochastic Cross";
string VeryLowStochasticCross = "Very Low Stochastic Cross";
string CurrSignal = NoSignal;
string PrevSignal = NoSignal;

//--- input parameters
input int K_Period = 14;  // Period for the %K line
input int D_Period = 3;   // Period for the %D line
input int Slowing = 3;    // Slowing parameter

datetime LastSignal = D'1980.07.19 12:30:27';
int i = 0;

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
         PlaySound("alert2.wav");
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
      Comment(StringFormat("\nVERY LOW STOCHASTIC CROSS SEEN\nPrevious Signal:  %s\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f\n\nKValuePrevPrev is %.2f\nDValuePrevPrev is %.2f",
              PrevSignal, MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev, KValuePrevPrev, DValuePrevPrev));

      CurrSignal = VeryLowStochasticCross;
      if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

      PlayChimeForBar();
   }
   else
   if (KValueCurr < DValueCurr &&
       KValuePrevPrev > VERY_HIGH_STOCHASTIC &&
       KValuePrevPrev >= DValuePrevPrev && KValuePrev < DValuePrev)
   {
      Comment(StringFormat("\nVERY HIGH STOCHASTIC CROSS SEEN\nPrevious Signal:  %s\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f\n\nKValuePrevPrev is %.2f\nDValuePrevPrev is %.2f",
              PrevSignal, MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev, KValuePrevPrev, DValuePrevPrev));

      CurrSignal = VeryHighStochasticCross;
      if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

      PlayChimeForBar();
   }
   else
   // Alerts for possible reversal Stochastic crosses
   //
   if (DValuePrev < REVERSAL_LONG_STOCHASTIC &&
       KValuePrev <= DValuePrev && KValueCurr > DValueCurr)
   {
      Comment(StringFormat("\nREVERSAL LONG STOCHASTIC CROSS SEEN\nPrevious Signal:  %s\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f\n\nKValuePrevPrev is %.2f\nDValuePrevPrev is %.2f",
              PrevSignal, MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev, KValuePrevPrev, DValuePrevPrev));

      CurrSignal = ReversalLongStochasticCross;
      if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

      PlayChimeForBar();
   }
   else
   if (DValuePrev > REVERSAL_SHORT_STOCHASTIC &&
       KValuePrev >= DValuePrev && KValueCurr < DValueCurr)
   {
      Comment(StringFormat("\nREVERSAL SHORT STOCHASTIC CROSS SEEN\nPrevious Signal:  %s\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f\n\nKValuePrevPrev is %.2f\nDValuePrevPrev is %.2f",
              PrevSignal, MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev, KValuePrevPrev, DValuePrevPrev));

      CurrSignal = ReversalShortStochasticCross;
      if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

      PlayChimeForBar();
   }

   // Alerts for confirmation of reversal Stochastic crosses
   //
   if ((PrevSignal == ReversalLongStochasticCross || PrevSignal == VeryLowStochasticCross) &&
       DValuePrev <= CONFIRM_REVERSAL_LONG &&
       DValueCurr > CONFIRM_REVERSAL_LONG)
   {
      Comment(StringFormat("\n*** CONFIRMED *** REVERSAL LONG STOCHASTIC CROSS SEEN\nPrevious Signal:  %s\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f\n\nKValuePrevPrev is %.2f\nDValuePrevPrev is %.2f",
              PrevSignal, MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev, KValuePrevPrev, DValuePrevPrev));

      CurrSignal = ReversalLongConfirmation;
      if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

      PlayChimeForBar();
   }
   else
   if ((PrevSignal == ReversalShortStochasticCross || PrevSignal == VeryHighStochasticCross) &&
       DValuePrev >= CONFIRM_REVERSAL_SHORT &&
       DValueCurr < CONFIRM_REVERSAL_SHORT)
   {
      Comment(StringFormat("\n*** CONFIRMED *** REVERSAL SHORT STOCHASTIC CROSS SEEN\nPrevious Signal:  %s\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f\n\nKValuePrevPrev is %.2f\nDValuePrevPrev is %.2f",
              PrevSignal, MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev, KValuePrevPrev, DValuePrevPrev));

      CurrSignal = ReversalShortConfirmation;
      if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

      PlayChimeForBar();
   }
   else
   // Alerts for potential profit-taking
   //
   if (KValueCurr > DValueCurr &&
       DValueCurr >= VERY_HIGH_STOCHASTIC)
   {
      Comment(StringFormat("\nVERY HIGH STOCHASTIC, CLOSE LONG?\nPrevious Signal:  %s\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f\n\nKValuePrevPrev is %.2f\nDValuePrevPrev is %.2f",
              PrevSignal, MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev, KValuePrevPrev, DValuePrevPrev));

      CurrSignal = VeryHighStochastic;
      if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

      PlayChimeForBar();
   }
   else
   if (KValueCurr < DValueCurr &&
       DValueCurr <= VERY_LOW_STOCHASTIC)
   {
      Comment(StringFormat("\nVERY LOW STOCHASTIC, CLOSE SHORT?\nPrevious Signal:  %s\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f\n\nKValuePrevPrev is %.2f\nDValuePrevPrev is %.2f",
              PrevSignal, MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev, KValuePrevPrev, DValuePrevPrev));

      CurrSignal = VeryLowStochastic;
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
          KValuePrev > DValuePrev &&
          KValuePrevPrev < LONG_STOCHASTIC &&
          KValuePrevPrev <= DValuePrevPrev)
      {
         Comment(StringFormat("\nUPTREND, BUY SIGNAL!\nPrevious Signal:  %s\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f\n\nKValuePrevPrev is %.2f\nDValuePrevPrev is %.2f",
                 PrevSignal, MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
                 KValueCurr, DValueCurr, KValuePrev, DValuePrev, KValuePrevPrev, DValuePrevPrev));

         CurrSignal = UptrendStochasticCross;
         if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

         PlayChimeForBar();
      }
      else
      {
         Comment(StringFormat("\nUPTREND, No Buy Signal\nPrevious Signal:  %s\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f\n\nKValuePrevPrev is %.2f\nDValuePrevPrev is %.2f",
                 PrevSignal, MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
                 KValueCurr, DValueCurr, KValuePrev, DValuePrev, KValuePrevPrev, DValuePrevPrev));
      }
   }
   else if (MAFastHighCurr < MASlowLowCurr)
   {
      // We are in a downtrend.
      // Check for sell signal.
      if (KValueCurr < DValueCurr &&
          KValuePrev < DValuePrev &&
          KValuePrevPrev > SHORT_STOCHASTIC &&
          KValuePrevPrev >= DValuePrevPrev)
      {
         Comment(StringFormat("\nDOWNTREND, SELL SIGNAL!\nPrevious Signal:  %s\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f\n\nKValuePrevPrev is %.2f\nDValuePrevPrev is %.2f",
                 PrevSignal, MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
                 KValueCurr, DValueCurr, KValuePrev, DValuePrev, KValuePrevPrev, DValuePrevPrev));

         CurrSignal = DowntrendStochasticCross;
         if (CurrSignal != PrevSignal) PrevSignal = CurrSignal;

         PlayChimeForBar();
      }
      else
      {
         Comment(StringFormat("\nDOWNTREND, No Buy Signal\nPrevious Signal:  %s\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f\n\nKValuePrevPrev is %.2f\nDValuePrevPrev is %.2f",
                 PrevSignal, MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
                 KValueCurr, DValueCurr, KValuePrev, DValuePrev, KValuePrevPrev, DValuePrevPrev));
      }
   }
   else
   {
      Comment(StringFormat("\nNO TREND, No Trade Signal\nPrevious Signal:  %s\n\nMASlowHighCurr is %.6f\nMASlowLowCurr is %.6f\n\nMAFastHighCurr is %.6f\nMAFastLowCurr is %.6f\n\n\nKValueCurr is %.2f\nDValueCurr is %.2f\n\nKValuePrev is %.2f\nDValuePrev is %.2f\n\nKValuePrevPrev is %.2f\nDValuePrevPrev is %.2f",
              PrevSignal, MASlowHighCurr, MASlowLowCurr, MAFastHighCurr, MAFastLowCurr,
              KValueCurr, DValueCurr, KValuePrev, DValuePrev, KValuePrevPrev, DValuePrevPrev));
   }
}
//+------------------------------------------------------------------+
