//+------------------------------------------------------------------+
//|                                               Master10-Silver.mq4
//|                            Copyright 2017-2024, Robert C. Cochran
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                   DLL Interface Declarations                     |
//+------------------------------------------------------------------+

#import "FXBlueQuickChannel.dll"
  int QC_StartSenderW    (string);
  int QC_StartReceiverW  (string, int);
  int QC_GetMessages5W   (int, uchar&[], int);
  int QC_SendMessageW    (int, string&, int);
  int QC_ReleaseSender   (int);
  int QC_ReleaseReceiver (int);
#import

//+------------------------------------------------------------------+
//|                       Define Statements                          |
//+------------------------------------------------------------------+

#define QC_BUFFER_SIZE 10000

//+------------------------------------------------------------------+
//|                       External Variables                         |
//+------------------------------------------------------------------+

extern bool   KeepTrading       =   true;
extern bool   UseMinLots        =  false;
extern int    MaxTrades         =      1;
extern int    Slippage          =      3;
extern double MaxMarginToUse    =      1.0;  // Maximum percent of margin to commit to each trade.
extern int    HourToStop        =     16;    // Stop opening trades when this hours is reached
extern int    HourToClose       =     17;    // Close trades when this hour is reached
extern int    MiniSize          =  10000;
extern int    StdSize           = 100000;

extern double EURUSDentryGap    =      0.00015;
extern double USDJPYentryGap    =      0.015;
extern double EURJPYentryGap    =      0.015;
extern double GBPJPYentryGap    =      0.015;
extern double EURGBPentryGap    =      0.00015;
extern double EURCHFentryGap    =      0.00015;
extern double GBPCHFentryGap    =      0.00015;
extern double GBPUSDentryGap    =      0.00015;
extern double USDCHFentryGap    =      0.00015;
extern double CHFJPYentryGap    =      0.015;

extern double EURUSDexitGap     =      0.00018;
extern double USDJPYexitGap     =      0.018;
extern double EURJPYexitGap     =      0.018;
extern double GBPJPYexitGap     =      0.018;
extern double EURGBPexitGap     =      0.00018;
extern double EURCHFexitGap     =      0.00018;
extern double GBPCHFexitGap     =      0.00018;
extern double GBPUSDexitGap     =      0.00018;
extern double USDCHFexitGap     =      0.00018;
extern double CHFJPYexitGap     =      0.018;

extern int    MagicNumber       = 298374;

//+------------------------------------------------------------------+
//|                    Internal Global Variables                     |
//+------------------------------------------------------------------+

bool AccountIsMini      = false,
     ReturnVal          = false,
     SlaveIsFresh       = false,
     MasterIsFresh      = false,
     SlaveFreshFound    = false,
     MasterFreshFound   = false,
     arrSlaveAlive[20]  = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false },
     arrMasterAlive[20] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false };

int i              = 0,
    intResult      = 0,
    glbRatesHandle = 0,
    glbTradeHandle = 0,
    Leverage       = 0,
    AccountTypeVal = 0,
    TotalTrades    = 0,

    EURUSDbuys     = 0,
    EURUSDsells    = 0,
    USDJPYbuys     = 0,
    USDJPYsells    = 0,
    EURJPYbuys     = 0,
    EURJPYsells    = 0,
    GBPJPYbuys     = 0,
    GBPJPYsells    = 0,
    EURGBPbuys     = 0,
    EURGBPsells    = 0,
    EURCHFbuys     = 0,
    EURCHFsells    = 0,
    GBPCHFbuys     = 0,
    GBPCHFsells    = 0,
    GBPUSDbuys     = 0,
    GBPUSDsells    = 0,
    USDCHFbuys     = 0,
    USDCHFsells    = 0,
    CHFJPYbuys     = 0,
    CHFJPYsells    = 0;

double MaxLots = 0.0, MinLots = 0.0, LotStep = 0.0, UseLots = 0.0,
       Investment = 0.0,
       MasterPL = 0.0, SlavePL = 0.0,

       EURUSDbidThis = 0.0, EURUSDbidOther = 0.0,
       EURUSDaskThis = 0.0, EURUSDaskOther = 0.0,
       USDJPYbidThis = 0.0, USDJPYbidOther = 0.0,
       USDJPYaskThis = 0.0, USDJPYaskOther = 0.0,
       EURJPYbidThis = 0.0, EURJPYbidOther = 0.0,
       EURJPYaskThis = 0.0, EURJPYaskOther = 0.0,
       GBPJPYbidThis = 0.0, GBPJPYbidOther = 0.0,
       GBPJPYaskThis = 0.0, GBPJPYaskOther = 0.0,
       EURGBPbidThis = 0.0, EURGBPbidOther = 0.0,
       EURGBPaskThis = 0.0, EURGBPaskOther = 0.0,
       EURCHFbidThis = 0.0, EURCHFbidOther = 0.0,
       EURCHFaskThis = 0.0, EURCHFaskOther = 0.0,
       GBPCHFbidThis = 0.0, GBPCHFbidOther = 0.0,
       GBPCHFaskThis = 0.0, GBPCHFaskOther = 0.0,
       GBPUSDbidThis = 0.0, GBPUSDbidOther = 0.0,
       GBPUSDaskThis = 0.0, GBPUSDaskOther = 0.0,
       USDCHFbidThis = 0.0, USDCHFbidOther = 0.0,
       USDCHFaskThis = 0.0, USDCHFaskOther = 0.0,
       CHFJPYbidThis = 0.0, CHFJPYbidOther = 0.0,
       CHFJPYaskThis = 0.0, CHFJPYaskOther = 0.0,

       EURUSDspreadThis = 0.0, EURUSDspreadOther = 0.0,
       USDJPYspreadThis = 0.0, USDJPYspreadOther = 0.0,
       EURJPYspreadThis = 0.0, EURJPYspreadOther = 0.0,
       GBPJPYspreadThis = 0.0, GBPJPYspreadOther = 0.0,
       EURGBPspreadThis = 0.0, EURGBPspreadOther = 0.0,
       EURCHFspreadThis = 0.0, EURCHFspreadOther = 0.0,
       GBPCHFspreadThis = 0.0, GBPCHFspreadOther = 0.0,
       GBPUSDspreadThis = 0.0, GBPUSDspreadOther = 0.0,
       USDCHFspreadThis = 0.0, USDCHFspreadOther = 0.0,
       CHFJPYspreadThis = 0.0, CHFJPYspreadOther = 0.0,

       CurrSlaveSum     = 0.0,
       CurrMasterSum    = 0.0,
       PrevSlaveSum     = 0.0,
       PrevMasterSum    = 0.0,

       ArbDelta      = 0.0;

string AccountTypeString = "",

       strDayOfWeek      = "",

       EURUSDsym = "",
       USDJPYsym = "",
       EURJPYsym = "",
       GBPJPYsym = "",
       EURGBPsym = "",
       EURCHFsym = "",
       GBPCHFsym = "",
       GBPUSDsym = "",
       USDCHFsym = "",
       CHFJPYsym = "",

       ClosureFlag = "",

       RatesMsg  = "", // Contains Bid/Ask and PL from the Slave's terminal
       TradeMsg  = "",
       Suffix    = "",
       Sep       = "|",
       RatesPLArray[]; // Index-able exchange rates and PL from the Slave

ushort SepCode = 0;

uchar glbRatesBuffer[]; // Allocated on initialization


//+------------------------------------------------------------------+
//|                   Initialization Event Handler                   |
//+------------------------------------------------------------------+

void OnInit()
{
  GetAccountInfo();
  SetAccountType();
  SetSymbolStrings();
  SetLotSize();

  SepCode = StringGetCharacter (Sep, 0);

  glbTradeHandle = QC_StartSenderW ("TradeChannel");

  // Create handle and buffer if not already done (i.e. on first tick)

  if (!glbRatesHandle)
  {
    glbRatesHandle = QC_StartReceiverW ("RatesChannel", WindowHandle(Symbol(), Period()));
    ArrayResize (glbRatesBuffer, QC_BUFFER_SIZE);
  }
  
  if (glbRatesHandle) 
  {
    MainLoop();
  }
  else
  {
    Comment ("No handle");
  }

  return;
}

//+------------------------------------------------------------------+
//|                  De-initialization Event Handler                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
  QC_ReleaseSender (glbTradeHandle);

  if (glbRatesHandle) QC_ReleaseReceiver (glbRatesHandle);

  glbRatesHandle = 0;
  glbTradeHandle = 0;

  return;
}

//
// OnTick is not needed.  We want to check market data as frequently as possible,
// not only when there is a tick on one currency pair.
//
//void OnTick()
//{
//  return;
//}

///////////////////////
// Supporting functions
///////////////////////

//+------------------------------------------------------------------+
//|                 Set the traded symbol strings.                   |
//+------------------------------------------------------------------+

void SetSymbolStrings()
{
  if (StringLen(Symbol()) > 6) Suffix = StringSubstr (Symbol(), 6);

  EURUSDsym = "EURUSD" + Suffix;
  USDJPYsym = "USDJPY" + Suffix;
  EURJPYsym = "EURJPY" + Suffix;
  GBPJPYsym = "GBPJPY" + Suffix;
  EURGBPsym = "EURGBP" + Suffix;
  EURCHFsym = "EURCHF" + Suffix;
  GBPCHFsym = "GBPCHF" + Suffix;
  GBPUSDsym = "GBPUSD" + Suffix;
  USDCHFsym = "USDCHF" + Suffix;
  CHFJPYsym = "CHFJPY" + Suffix;

  return;
}

//+------------------------------------------------------------------+
//|  Watch for arb opportunities in opposite directions of opens,    |
//|  and close all trades if seen.                                   |
//+------------------------------------------------------------------+

void CloseOnExitArbsOrTime()
{
  if (strDayOfWeek == "Friday" && Hour() >= HourToClose)
  {
    CloseAllTrades();
    Print ("Closing trades at specified time.");
  }
  else
  if (EURUSDsells > 0 && EURUSDaskThis != 0.0 && EURUSDbidOther != 0.0 && (EURUSDaskThis + EURUSDexitGap <= EURUSDbidOther))
  {
    CloseAllTrades();

    ArbDelta = 10000.0 * (EURUSDbidOther - EURUSDaskThis);

    Print   ("EURUSD: This Broker's Ask of " + DoubleToStr(EURUSDaskThis,  5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(EURUSDbidOther, 5) + ".");
  }
  else
  if (EURUSDbuys > 0 && EURUSDaskOther != 0.0 && EURUSDbidThis != 0.0 && (EURUSDaskOther + EURUSDexitGap <= EURUSDbidThis))
  {
    CloseAllTrades();

    ArbDelta = 10000.0 * (EURUSDbidThis - EURUSDaskOther);

    Print   ("EURUSD: Other Broker's Ask of " + DoubleToStr(EURUSDaskOther, 5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(EURUSDbidThis, 5) + ".");
  }
  else
  if (USDJPYsells > 0 && USDJPYaskThis != 0.0 && USDJPYbidOther != 0.0 && (USDJPYaskThis + USDJPYexitGap <= USDJPYbidOther))
  {
    CloseAllTrades();

    ArbDelta = 100.0 * (USDJPYbidOther - USDJPYaskThis);

    Print   ("USDJPY: This Broker's Ask of " + DoubleToStr(USDJPYaskThis,  3) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(USDJPYbidOther, 3) + ".");
  }
  else
  if (USDJPYbuys > 0 && USDJPYaskOther != 0.0 && USDJPYbidThis != 0.0 && (USDJPYaskOther + USDJPYexitGap <= USDJPYbidThis))
  {
    CloseAllTrades();

    ArbDelta = 100.0 * (USDJPYbidThis - USDJPYaskOther);

    Print   ("USDJPY: Other Broker's Ask of " + DoubleToStr(USDJPYaskOther, 3) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(USDJPYbidThis, 3) + ".");
  }
  else
  if (EURJPYsells > 0 && EURJPYaskThis != 0.0 && EURJPYbidOther != 0.0 && (EURJPYaskThis + EURJPYexitGap <= EURJPYbidOther))
  {
    CloseAllTrades();

    ArbDelta = 100.0 * (EURJPYbidOther - EURJPYaskThis);

    Print   ("EURJPY: This Broker's Ask of " + DoubleToStr(EURJPYaskThis,  3) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(EURJPYbidOther, 3) + ".");
  }
  else
  if (EURJPYbuys > 0 && EURJPYaskOther != 0.0 && EURJPYbidThis != 0.0 && (EURJPYaskOther + EURJPYexitGap <= EURJPYbidThis))
  {
    CloseAllTrades();

    ArbDelta = 100.0 * (EURJPYbidThis - EURJPYaskOther);

    Print   ("EURJPY: Other Broker's Ask of " + DoubleToStr(EURJPYaskOther, 3) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(EURJPYbidThis, 3) + ".");
  }
  else
  if (GBPJPYsells > 0 && GBPJPYaskThis != 0.0 && GBPJPYbidOther != 0.0 && (GBPJPYaskThis + GBPJPYexitGap <= GBPJPYbidOther))
  {
    CloseAllTrades();

    ArbDelta = 100.0 * (GBPJPYbidOther - GBPJPYaskThis);

    Print   ("GBPJPY: This Broker's Ask of " + DoubleToStr(GBPJPYaskThis,  3) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(GBPJPYbidOther, 3) + ".");
  }
  else
  if (GBPJPYbuys > 0 && GBPJPYaskOther != 0.0 && GBPJPYbidThis != 0.0 && (GBPJPYaskOther + GBPJPYexitGap <= GBPJPYbidThis))
  {
    CloseAllTrades();

    ArbDelta = 100.0 * (GBPJPYbidThis - GBPJPYaskOther);

    Print   ("GBPJPY: Other Broker's Ask of " + DoubleToStr(GBPJPYaskOther, 3) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(GBPJPYbidThis, 3) + ".");
  }
  else
  if (EURGBPsells > 0 && EURGBPaskThis != 0.0 && EURGBPbidOther != 0.0 && (EURGBPaskThis + EURGBPexitGap <= EURGBPbidOther))
  {
    CloseAllTrades();

    ArbDelta = 10000.0 * (EURGBPbidOther - EURGBPaskThis);

    Print   ("EURGBP: This Broker's Ask of " + DoubleToStr(EURGBPaskThis,  5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(EURGBPbidOther, 5) + ".");
  }
  else
  if (EURGBPbuys > 0 && EURGBPaskOther != 0.0 && EURGBPbidThis != 0.0 && (EURGBPaskOther + EURGBPexitGap <= EURGBPbidThis))
  {
    CloseAllTrades();

    ArbDelta = 10000.0 * (EURGBPbidThis - EURGBPaskOther);

    Print   ("EURGBP: Other Broker's Ask of " + DoubleToStr(EURGBPaskOther, 5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(EURGBPbidThis, 5) + ".");
  }
  else
  if (EURCHFsells > 0 && EURCHFaskThis != 0.0 && EURCHFbidOther != 0.0 && (EURCHFaskThis + EURCHFexitGap <= EURCHFbidOther))
  {
    CloseAllTrades();

    ArbDelta = 10000.0 * (EURCHFbidOther - EURCHFaskThis);

    Print   ("EURCHF: This Broker's Ask of " + DoubleToStr(EURCHFaskThis,  5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(EURCHFbidOther, 5) + ".");
  }
  else
  if (EURCHFbuys > 0 && EURCHFaskOther != 0.0 && EURCHFbidThis != 0.0 && (EURCHFaskOther + EURCHFexitGap <= EURCHFbidThis))
  {
    CloseAllTrades();

    ArbDelta = 10000.0 * (EURCHFbidThis - EURCHFaskOther);

    Print   ("EURCHF: Other Broker's Ask of " + DoubleToStr(EURCHFaskOther, 5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(EURCHFbidThis, 5) + ".");
  }
  else
  if (GBPCHFsells > 0 && GBPCHFaskThis != 0.0 && GBPCHFbidOther != 0.0 && (GBPCHFaskThis + GBPCHFexitGap <= GBPCHFbidOther))
  {
    CloseAllTrades();

    ArbDelta = 10000.0 * (GBPCHFbidOther - GBPCHFaskThis);

    Print   ("GBPCHF: This Broker's Ask of " + DoubleToStr(GBPCHFaskThis,  5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(GBPCHFbidOther, 5) + ".");
  }
  else
  if (GBPCHFbuys > 0 && GBPCHFaskOther != 0.0 && GBPCHFbidThis != 0.0 && (GBPCHFaskOther + GBPCHFexitGap <= GBPCHFbidThis))
  {
    CloseAllTrades();

    ArbDelta = 10000.0 * (GBPCHFbidThis - GBPCHFaskOther);

    Print   ("GBPCHF: Other Broker's Ask of " + DoubleToStr(GBPCHFaskOther, 5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(GBPCHFbidThis, 5) + ".");
  }
  else
  if (GBPUSDsells > 0 && GBPUSDaskThis != 0.0 && GBPUSDbidOther != 0.0 && (GBPUSDaskThis + GBPUSDexitGap <= GBPUSDbidOther))
  {
    CloseAllTrades();

    ArbDelta = 10000.0 * (GBPUSDbidOther - GBPUSDaskThis);

    Print   ("GBPUSD: This Broker's Ask of " + DoubleToStr(GBPUSDaskThis,  5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(GBPUSDbidOther, 5) + ".");
  }
  else
  if (GBPUSDbuys > 0 && GBPUSDaskOther != 0.0 && GBPUSDbidThis != 0.0 && (GBPUSDaskOther + GBPUSDexitGap <= GBPUSDbidThis))
  {
    CloseAllTrades();

    ArbDelta = 10000.0 * (GBPUSDbidThis - GBPUSDaskOther);

    Print   ("GBPUSD: Other Broker's Ask of " + DoubleToStr(GBPUSDaskOther, 5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(GBPUSDbidThis, 5) + ".");
  }
  else
  if (USDCHFsells > 0 && USDCHFaskThis != 0.0 && USDCHFbidOther != 0.0 && (USDCHFaskThis + USDCHFexitGap <= USDCHFbidOther))
  {
    CloseAllTrades();

    ArbDelta = 10000.0 * (USDCHFbidOther - USDCHFaskThis);

    Print   ("USDCHF: This Broker's Ask of " + DoubleToStr(USDCHFaskThis,  5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(USDCHFbidOther, 5) + ".");
  }
  else
  if (USDCHFbuys > 0 && USDCHFaskOther != 0.0 && USDCHFbidThis != 0.0 && (USDCHFaskOther + USDCHFexitGap <= USDCHFbidThis))
  {
    CloseAllTrades();

    ArbDelta = 10000.0 * (USDCHFbidThis - USDCHFaskOther);

    Print   ("USDCHF: Other Broker's Ask of " + DoubleToStr(USDCHFaskOther, 5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(USDCHFbidThis, 5) + ".");
  }
  else
  if (CHFJPYsells > 0 && CHFJPYaskThis != 0.0 && CHFJPYbidOther != 0.0 && (CHFJPYaskThis + CHFJPYexitGap <= CHFJPYbidOther))
  {
    CloseAllTrades();

    ArbDelta = 100.0 * (CHFJPYbidOther - CHFJPYaskThis);

    Print   ("CHFJPY: This Broker's Ask of " + DoubleToStr(CHFJPYaskThis,  3) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(CHFJPYbidOther, 3) + ".");
  }
  else
  if (CHFJPYbuys > 0 && CHFJPYaskOther != 0.0 && CHFJPYbidThis != 0.0 && (CHFJPYaskOther + CHFJPYexitGap <= CHFJPYbidThis))
  {
    CloseAllTrades();

    ArbDelta = 100.0 * (CHFJPYbidThis - CHFJPYaskOther);

    Print   ("CHFJPY: Other Broker's Ask of " + DoubleToStr(CHFJPYaskOther, 3) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(CHFJPYbidThis, 3) + ".");
  }

  return;
}

//+------------------------------------------------------------------+
//|  Watch for arb opportunities and open trades if seen.            |
//+------------------------------------------------------------------+

void OpenOnEntryArbs()
{
  if (EURUSDaskThis != 0.0 && EURUSDbidOther != 0.0 && (EURUSDaskThis + EURUSDentryGap <= EURUSDbidOther))
  {
    BuyHereSellThere("EURUSD", EURUSDsym, EURUSDaskThis);

    ArbDelta = 10000.0 * (EURUSDbidOther - EURUSDaskThis);

    Print   ("EURUSD: This Broker's Ask of " + DoubleToStr(EURUSDaskThis,  5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(EURUSDbidOther, 5) + ".");
  }
  else
  if (EURUSDaskOther != 0.0 && EURUSDbidThis != 0.0 && (EURUSDaskOther + EURUSDentryGap <= EURUSDbidThis))
  {
    BuyThereSellHere("EURUSD", EURUSDsym, EURUSDbidThis);

    ArbDelta = 10000.0 * (EURUSDbidThis - EURUSDaskOther);

    Print   ("EURUSD: Other Broker's Ask of " + DoubleToStr(EURUSDaskOther, 5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(EURUSDbidThis, 5) + ".");
  }
  else
  if (USDJPYaskThis != 0.0 && USDJPYbidOther != 0.0 && (USDJPYaskThis + USDJPYentryGap <= USDJPYbidOther))
  {
    BuyHereSellThere("USDJPY", USDJPYsym, USDJPYaskThis);

    ArbDelta = 100.0 * (USDJPYbidOther - USDJPYaskThis);

    Print   ("USDJPY: This Broker's Ask of " + DoubleToStr(USDJPYaskThis,  3) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(USDJPYbidOther, 3) + ".");
  }
  else
  if (USDJPYaskOther != 0.0 && USDJPYbidThis != 0.0 && (USDJPYaskOther + USDJPYentryGap <= USDJPYbidThis))
  {
    BuyThereSellHere("USDJPY", USDJPYsym, USDJPYbidThis);

    ArbDelta = 100.0 * (USDJPYbidThis - USDJPYaskOther);

    Print   ("USDJPY: Other Broker's Ask of " + DoubleToStr(USDJPYaskOther, 3) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(USDJPYbidThis, 3) + ".");
  }
  else
  if (EURJPYaskThis != 0.0 && EURJPYbidOther != 0.0 && (EURJPYaskThis + EURJPYentryGap <= EURJPYbidOther))
  {
    BuyHereSellThere("EURJPY", EURJPYsym, EURJPYaskThis);

    ArbDelta = 100.0 * (EURJPYbidOther - EURJPYaskThis);

    Print   ("EURJPY: This Broker's Ask of " + DoubleToStr(EURJPYaskThis,  3) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(EURJPYbidOther, 3) + ".");
  }
  else
  if (EURJPYaskOther != 0.0 && EURJPYbidThis != 0.0 && (EURJPYaskOther + EURJPYentryGap <= EURJPYbidThis))
  {
    BuyThereSellHere("EURJPY", EURJPYsym, EURJPYbidThis);

    ArbDelta = 100.0 * (EURJPYbidThis - EURJPYaskOther);

    Print   ("EURJPY: Other Broker's Ask of " + DoubleToStr(EURJPYaskOther, 3) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(EURJPYbidThis, 3) + ".");
  }
  else
  if (GBPJPYaskThis != 0.0 && GBPJPYbidOther != 0.0 && (GBPJPYaskThis + GBPJPYentryGap <= GBPJPYbidOther))
  {
    BuyHereSellThere("GBPJPY", GBPJPYsym, GBPJPYaskThis);

    ArbDelta = 100.0 * (GBPJPYbidOther - GBPJPYaskThis);

    Print   ("GBPJPY: This Broker's Ask of " + DoubleToStr(GBPJPYaskThis,  3) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(GBPJPYbidOther, 3) + ".");
  }
  else
  if (GBPJPYaskOther != 0.0 && GBPJPYbidThis != 0.0 && (GBPJPYaskOther + GBPJPYentryGap <= GBPJPYbidThis))
  {
    BuyThereSellHere("GBPJPY", GBPJPYsym, GBPJPYbidThis);

    ArbDelta = 100.0 * (GBPJPYbidThis - GBPJPYaskOther);

    Print   ("GBPJPY: Other Broker's Ask of " + DoubleToStr(GBPJPYaskOther, 3) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(GBPJPYbidThis, 3) + ".");
  }
  else
  if (EURGBPaskThis != 0.0 && EURGBPbidOther != 0.0 && (EURGBPaskThis + EURGBPentryGap <= EURGBPbidOther))
  {
    BuyHereSellThere("EURGBP", EURGBPsym, EURGBPaskThis);

    ArbDelta = 10000.0 * (EURGBPbidOther - EURGBPaskThis);

    Print   ("EURGBP: This Broker's Ask of " + DoubleToStr(EURGBPaskThis,  5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(EURGBPbidOther, 5) + ".");
  }
  else
  if (EURGBPaskOther != 0.0 && EURGBPbidThis != 0.0 && (EURGBPaskOther + EURGBPentryGap <= EURGBPbidThis))
  {
    BuyThereSellHere("EURGBP", EURGBPsym, EURGBPbidThis);

    ArbDelta = 10000.0 * (EURGBPbidThis - EURGBPaskOther);

    Print   ("EURGBP: Other Broker's Ask of " + DoubleToStr(EURGBPaskOther, 5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(EURGBPbidThis, 5) + ".");
  }
  else
  if (EURCHFaskThis != 0.0 && EURCHFbidOther != 0.0 && (EURCHFaskThis + EURCHFentryGap <= EURCHFbidOther))
  {
    BuyHereSellThere("EURCHF", EURCHFsym, EURCHFaskThis);

    ArbDelta = 10000.0 * (EURCHFbidOther - EURCHFaskThis);

    Print   ("EURCHF: This Broker's Ask of " + DoubleToStr(EURCHFaskThis,  5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(EURCHFbidOther, 5) + ".");
  }
  else
  if (EURCHFaskOther != 0.0 && EURCHFbidThis != 0.0 && (EURCHFaskOther + EURCHFentryGap <= EURCHFbidThis))
  {
    BuyThereSellHere("EURCHF", EURCHFsym, EURCHFbidThis);

    ArbDelta = 10000.0 * (EURCHFbidThis - EURCHFaskOther);

    Print   ("EURCHF: Other Broker's Ask of " + DoubleToStr(EURCHFaskOther, 5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(EURCHFbidThis, 5) + ".");
  }
  else
  if (GBPCHFaskThis != 0.0 && GBPCHFbidOther != 0.0 && (GBPCHFaskThis + GBPCHFentryGap <= GBPCHFbidOther))
  {
    BuyHereSellThere("GBPCHF", GBPCHFsym, GBPCHFaskThis);

    ArbDelta = 10000.0 * (GBPCHFbidOther - GBPCHFaskThis);

    Print   ("GBPCHF: This Broker's Ask of " + DoubleToStr(GBPCHFaskThis,  5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(GBPCHFbidOther, 5) + ".");
  }
  else
  if (GBPCHFaskOther != 0.0 && GBPCHFbidThis != 0.0 && (GBPCHFaskOther + GBPCHFentryGap <= GBPCHFbidThis))
  {
    BuyThereSellHere("GBPCHF", GBPCHFsym, GBPCHFbidThis);

    ArbDelta = 10000.0 * (GBPCHFbidThis - GBPCHFaskOther);

    Print   ("GBPCHF: Other Broker's Ask of " + DoubleToStr(GBPCHFaskOther, 5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(GBPCHFbidThis, 5) + ".");
  }
  else
  if (GBPUSDaskThis != 0.0 && GBPUSDbidOther != 0.0 && (GBPUSDaskThis + GBPUSDentryGap <= GBPUSDbidOther))
  {
    BuyHereSellThere("GBPUSD", GBPUSDsym, GBPUSDaskThis);

    ArbDelta = 10000.0 * (GBPUSDbidOther - GBPUSDaskThis);

    Print   ("GBPUSD: This Broker's Ask of " + DoubleToStr(GBPUSDaskThis,  5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(GBPUSDbidOther, 5) + ".");
  }
  else
  if (GBPUSDaskOther != 0.0 && GBPUSDbidThis != 0.0 && (GBPUSDaskOther + GBPUSDentryGap <= GBPUSDbidThis))
  {
    BuyThereSellHere("GBPUSD", GBPUSDsym, GBPUSDbidThis);

    ArbDelta = 10000.0 * (GBPUSDbidThis - GBPUSDaskOther);

    Print   ("GBPUSD: Other Broker's Ask of " + DoubleToStr(GBPUSDaskOther, 5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(GBPUSDbidThis, 5) + ".");
  }
  else
  if (USDCHFaskThis != 0.0 && USDCHFbidOther != 0.0 && (USDCHFaskThis + USDCHFentryGap <= USDCHFbidOther))
  {
    BuyHereSellThere("USDCHF", USDCHFsym, USDCHFaskThis);

    ArbDelta = 10000.0 * (USDCHFbidOther - USDCHFaskThis);

    Print   ("USDCHF: This Broker's Ask of " + DoubleToStr(USDCHFaskThis,  5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(USDCHFbidOther, 5) + ".");
  }
  else
  if (USDCHFaskOther != 0.0 && USDCHFbidThis != 0.0 && (USDCHFaskOther + USDCHFentryGap <= USDCHFbidThis))
  {
    BuyThereSellHere("USDCHF", USDCHFsym, USDCHFbidThis);

    ArbDelta = 10000.0 * (USDCHFbidThis - USDCHFaskOther);

    Print   ("USDCHF: Other Broker's Ask of " + DoubleToStr(USDCHFaskOther, 5) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(USDCHFbidThis, 5) + ".");
  }
  else
  if (CHFJPYaskThis != 0.0 && CHFJPYbidOther != 0.0 && (CHFJPYaskThis + CHFJPYentryGap <= CHFJPYbidOther))
  {
    BuyHereSellThere("CHFJPY", CHFJPYsym, CHFJPYaskThis);

    ArbDelta = 100.0 * (CHFJPYbidOther - CHFJPYaskThis);

    Print   ("CHFJPY: This Broker's Ask of " + DoubleToStr(CHFJPYaskThis,  3) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below Other Broker's Bid of " + DoubleToStr(CHFJPYbidOther, 3) + ".");
  }
  else
  if (CHFJPYaskOther != 0.0 && CHFJPYbidThis != 0.0 && (CHFJPYaskOther + CHFJPYentryGap <= CHFJPYbidThis))
  {
    BuyThereSellHere("CHFJPY", CHFJPYsym, CHFJPYbidThis);

    ArbDelta = 100.0 * (CHFJPYbidThis - CHFJPYaskOther);

    Print   ("CHFJPY: Other Broker's Ask of " + DoubleToStr(CHFJPYaskOther, 3) + " was " +
              DoubleToStr(ArbDelta, 1) + " pips below This Broker's Bid of " + DoubleToStr(CHFJPYbidThis, 3) + ".");
  }

  return;
}

//+------------------------------------------------------------------+
//| Main Loop, substituting for the OnTick event handler.  We want   |
//| to check exchange rate data and execute trade operations faster  |
//| than ticks occur on a single currency pair.                      |
//+------------------------------------------------------------------+

void MainLoop()
{
  while (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
  {
    switch (DayOfWeek())
    {
      case 0:
        strDayOfWeek = "Sunday";
        break;
      case 1:
        strDayOfWeek = "Monday";
        break;
      case 2:
        strDayOfWeek = "Tuesday";
        break;
      case 3:
        strDayOfWeek = "Wednesday";
        break;
      case 4:
        strDayOfWeek = "Thursday";
        break;
      case 5:
        strDayOfWeek = "Friday";
        break;
      case 6:
        strDayOfWeek = "Saturday";
        break;
      default:
        break;
    }

    Count_PL_Trades();

    intResult = QC_GetMessages5W (glbRatesHandle, glbRatesBuffer, QC_BUFFER_SIZE);

    if (intResult > 0)
    {
      EURUSDbidOther = 0.0; EURUSDaskOther = 0.0;
      USDJPYbidOther = 0.0; USDJPYaskOther = 0.0;
      EURJPYbidOther = 0.0; EURJPYaskOther = 0.0;
      GBPJPYbidOther = 0.0; GBPJPYaskOther = 0.0;
      EURGBPbidOther = 0.0; EURGBPaskOther = 0.0;
      EURCHFbidOther = 0.0; EURCHFaskOther = 0.0;
      GBPCHFbidOther = 0.0; GBPCHFaskOther = 0.0;
      GBPUSDbidOther = 0.0; GBPUSDaskOther = 0.0;
      USDCHFbidOther = 0.0; USDCHFaskOther = 0.0;
      CHFJPYbidOther = 0.0; CHFJPYaskOther = 0.0;

      EURUSDbidThis  = 0.0; EURUSDaskThis  = 0.0;
      USDJPYbidThis  = 0.0; USDJPYaskThis  = 0.0;
      EURJPYbidThis  = 0.0; EURJPYaskThis  = 0.0;
      GBPJPYbidThis  = 0.0; GBPJPYaskThis  = 0.0;
      EURGBPbidThis  = 0.0; EURGBPaskThis  = 0.0;
      EURCHFbidThis  = 0.0; EURCHFaskThis  = 0.0;
      GBPCHFbidThis  = 0.0; GBPCHFaskThis  = 0.0;
      GBPUSDbidThis  = 0.0; GBPUSDaskThis  = 0.0;
      USDCHFbidThis  = 0.0; USDCHFaskThis  = 0.0;
      CHFJPYbidThis  = 0.0; CHFJPYaskThis  = 0.0;

      RatesMsg = "";

      RatesMsg = CharArrayToString (glbRatesBuffer, 0, intResult);

      if (RatesMsg != "")
      {
        // Unpack the "|" delimited string into RatesPLArray.

        intResult = StringSplit (RatesMsg, SepCode, RatesPLArray);

        EURUSDbidOther = StringToDouble(RatesPLArray[0]);   EURUSDaskOther = StringToDouble(RatesPLArray[1]);
        USDJPYbidOther = StringToDouble(RatesPLArray[2]);   USDJPYaskOther = StringToDouble(RatesPLArray[3]);
        EURJPYbidOther = StringToDouble(RatesPLArray[4]);   EURJPYaskOther = StringToDouble(RatesPLArray[5]);
        GBPJPYbidOther = StringToDouble(RatesPLArray[6]);   GBPJPYaskOther = StringToDouble(RatesPLArray[7]);
        EURGBPbidOther = StringToDouble(RatesPLArray[8]);   EURGBPaskOther = StringToDouble(RatesPLArray[9]);
        EURCHFbidOther = StringToDouble(RatesPLArray[10]);  EURCHFaskOther = StringToDouble(RatesPLArray[11]);
        GBPCHFbidOther = StringToDouble(RatesPLArray[12]);  GBPCHFaskOther = StringToDouble(RatesPLArray[13]);
        GBPUSDbidOther = StringToDouble(RatesPLArray[14]);  GBPUSDaskOther = StringToDouble(RatesPLArray[15]);
        USDCHFbidOther = StringToDouble(RatesPLArray[16]);  USDCHFaskOther = StringToDouble(RatesPLArray[17]);
        CHFJPYbidOther = StringToDouble(RatesPLArray[18]);  CHFJPYaskOther = StringToDouble(RatesPLArray[19]);

        SlavePL = StringToDouble (RatesPLArray[20]);

        EURUSDbidThis  = MarketInfo(EURUSDsym, MODE_BID); EURUSDaskThis  = MarketInfo(EURUSDsym, MODE_ASK);
        USDJPYbidThis  = MarketInfo(USDJPYsym, MODE_BID); USDJPYaskThis  = MarketInfo(USDJPYsym, MODE_ASK);
        EURJPYbidThis  = MarketInfo(EURJPYsym, MODE_BID); EURJPYaskThis  = MarketInfo(EURJPYsym, MODE_ASK);
        GBPJPYbidThis  = MarketInfo(GBPJPYsym, MODE_BID); GBPJPYaskThis  = MarketInfo(GBPJPYsym, MODE_ASK);
        EURGBPbidThis  = MarketInfo(EURGBPsym, MODE_BID); EURGBPaskThis  = MarketInfo(EURGBPsym, MODE_ASK);
        EURCHFbidThis  = MarketInfo(EURCHFsym, MODE_BID); EURCHFaskThis  = MarketInfo(EURCHFsym, MODE_ASK);
        GBPCHFbidThis  = MarketInfo(GBPCHFsym, MODE_BID); GBPCHFaskThis  = MarketInfo(GBPCHFsym, MODE_ASK);
        GBPUSDbidThis  = MarketInfo(GBPUSDsym, MODE_BID); GBPUSDaskThis  = MarketInfo(GBPUSDsym, MODE_ASK);
        USDCHFbidThis  = MarketInfo(USDCHFsym, MODE_BID); USDCHFaskThis  = MarketInfo(USDCHFsym, MODE_ASK);
        CHFJPYbidThis  = MarketInfo(CHFJPYsym, MODE_BID); CHFJPYaskThis  = MarketInfo(CHFJPYsym, MODE_ASK);

        CurrSlaveSum = EURUSDbidOther + USDJPYbidOther + EURJPYbidOther + GBPJPYbidOther + EURGBPbidOther +
                       EURCHFbidOther + GBPCHFbidOther + GBPUSDbidOther + USDCHFbidOther + CHFJPYbidOther +
                       EURUSDaskOther + USDJPYaskOther + EURJPYaskOther + GBPJPYaskOther + EURGBPaskOther +
                       EURCHFaskOther + GBPCHFaskOther + GBPUSDaskOther + USDCHFaskOther + CHFJPYaskOther;

        CurrMasterSum = EURUSDbidThis + USDJPYbidThis + EURJPYbidThis + GBPJPYbidThis + EURGBPbidThis +
                        EURCHFbidThis + GBPCHFbidThis + GBPUSDbidThis + USDCHFbidThis + CHFJPYbidThis +
                        EURUSDaskThis + USDJPYaskThis + EURJPYaskThis + GBPJPYaskThis + EURGBPaskThis +
                        EURCHFaskThis + GBPCHFaskThis + GBPUSDaskThis + USDCHFaskThis + CHFJPYaskThis;

        SlaveIsFresh  = (PrevSlaveSum  != 0.0 && CurrSlaveSum  != 0.0 && PrevSlaveSum  != CurrSlaveSum);
        MasterIsFresh = (PrevMasterSum != 0.0 && CurrMasterSum != 0.0 && PrevMasterSum != CurrMasterSum);

        PrevSlaveSum  = CurrSlaveSum;
        PrevMasterSum = CurrMasterSum;
        
        RollAliveArrays();

        TradeMsg = "NULL";

        if (WeAreAlive() && (MasterIsFresh || SlaveIsFresh))
        {
          if (TotalTrades > 0)
          {
            CloseOnExitArbsOrTime();
          }
          else // TotalTrades == 0
          if (KeepTrading                                         &&
              !(strDayOfWeek == "Friday" && Hour() >= HourToStop) &&
                strDayOfWeek != "Saturday"                        &&
                strDayOfWeek != "Sunday")
          {
            OpenOnEntryArbs();
          }

          EURUSDspreadOther = 10000.0 * (EURUSDaskOther - EURUSDbidOther);
          USDJPYspreadOther = 100.0   * (USDJPYaskOther - USDJPYbidOther);
          EURJPYspreadOther = 100.0   * (EURJPYaskOther - EURJPYbidOther);
          GBPJPYspreadOther = 100.0   * (GBPJPYaskOther - GBPJPYbidOther);
          EURGBPspreadOther = 10000.0 * (EURGBPaskOther - EURGBPbidOther);
          EURCHFspreadOther = 10000.0 * (EURCHFaskOther - EURCHFbidOther);
          GBPCHFspreadOther = 10000.0 * (GBPCHFaskOther - GBPCHFbidOther);
          GBPUSDspreadOther = 10000.0 * (GBPUSDaskOther - GBPUSDbidOther);
          USDCHFspreadOther = 10000.0 * (USDCHFaskOther - USDCHFbidOther);
          CHFJPYspreadOther = 100.0   * (CHFJPYaskOther - CHFJPYbidOther);

          EURUSDspreadThis = 10000.0  * (EURUSDaskThis - EURUSDbidThis);
          USDJPYspreadThis = 100.0    * (USDJPYaskThis - USDJPYbidThis);
          EURJPYspreadThis = 100.0    * (EURJPYaskThis - EURJPYbidThis);
          GBPJPYspreadThis = 100.0    * (GBPJPYaskThis - GBPJPYbidThis);
          EURGBPspreadThis = 10000.0  * (EURGBPaskThis - EURGBPbidThis);
          EURCHFspreadThis = 10000.0  * (EURCHFaskThis - EURCHFbidThis);
          GBPCHFspreadThis = 10000.0  * (GBPCHFaskThis - GBPCHFbidThis);
          GBPUSDspreadThis = 10000.0  * (GBPUSDaskThis - GBPUSDbidThis);
          USDCHFspreadThis = 10000.0  * (USDCHFaskThis - USDCHFbidThis);
          CHFJPYspreadThis = 100.0    * (CHFJPYaskThis - CHFJPYbidThis);

          Comment (strDayOfWeek + ", Hour " + Hour() +
               "\nLeverage: " + Leverage + ":1, Account Type: " + AccountTypeString +
               ", Master Fresh: " + MasterIsFresh + ", Slave Fresh: " + SlaveIsFresh +
               ", Lot Size: " + UseLots + ", Overall PL: $" + DoubleToStr(MasterPL + SlavePL,  2) +

             "\n\nThis  Broker EURUSD Bid: " + DoubleToStr(EURUSDbidThis,  5) +                 
               "\nThis  Broker EURUSD Ask: " + DoubleToStr(EURUSDaskThis,  5) + ", Spread: " + DoubleToStr(EURUSDspreadThis,  1) +
             "\n\nOther Broker EURUSD Bid: " + DoubleToStr(EURUSDbidOther, 5) +
               "\nOther Broker EURUSD Ask: " + DoubleToStr(EURUSDaskOther, 5) + ", Spread: " + DoubleToStr(EURUSDspreadOther, 1) +

               "\n----------------------------------------" +

               "\nThis  Broker USDJPY Bid: " + DoubleToStr(USDJPYbidThis,  3) +
               "\nThis  Broker USDJPY Ask: " + DoubleToStr(USDJPYaskThis,  3) + ", Spread: " + DoubleToStr(USDJPYspreadThis,  1) +
             "\n\nOther Broker USDJPY Bid: " + DoubleToStr(USDJPYbidOther, 3) +
               "\nOther Broker USDJPY Ask: " + DoubleToStr(USDJPYaskOther, 3) + ", Spread: " + DoubleToStr(USDJPYspreadOther, 1) +

               "\n----------------------------------------" +

               "\nThis  Broker EURJPY Bid: " + DoubleToStr(EURJPYbidThis,  3) +
               "\nThis  Broker EURJPY Ask: " + DoubleToStr(EURJPYaskThis,  3) + ", Spread: " + DoubleToStr(EURJPYspreadThis,  1) +
             "\n\nOther Broker EURJPY Bid: " + DoubleToStr(EURJPYbidOther, 3) +
               "\nOther Broker EURJPY Ask: " + DoubleToStr(EURJPYaskOther, 3) + ", Spread: " + DoubleToStr(EURJPYspreadOther, 1) +

               "\n----------------------------------------" +

               "\nThis  Broker GBPJPY Bid: " + DoubleToStr(GBPJPYbidThis,  3) +
               "\nThis  Broker GBPJPY Ask: " + DoubleToStr(GBPJPYaskThis,  3) + ", Spread: " + DoubleToStr(GBPJPYspreadThis,  1) +
             "\n\nOther Broker GBPJPY Bid: " + DoubleToStr(GBPJPYbidOther, 3) +
               "\nOther Broker GBPJPY Ask: " + DoubleToStr(GBPJPYaskOther, 3) + ", Spread: " + DoubleToStr(GBPJPYspreadOther, 1) +

               "\n----------------------------------------" +

               "\nThis  Broker EURGBP Bid: " + DoubleToStr(EURGBPbidThis,  5) +
               "\nThis  Broker EURGBP Ask: " + DoubleToStr(EURGBPaskThis,  5) + ", Spread: " + DoubleToStr(EURGBPspreadThis,  1) +
             "\n\nOther Broker EURGBP Bid: " + DoubleToStr(EURGBPbidOther, 5) +
               "\nOther Broker EURGBP Ask: " + DoubleToStr(EURGBPaskOther, 5) + ", Spread: " + DoubleToStr(EURGBPspreadOther, 1) +

               "\n----------------------------------------" +

               "\nThis  Broker EURCHF Bid: " + DoubleToStr(EURCHFbidThis,  5) +
               "\nThis  Broker EURCHF Ask: " + DoubleToStr(EURCHFaskThis,  5) + ", Spread: " + DoubleToStr(EURCHFspreadThis,  1) +
             "\n\nOther Broker EURCHF Bid: " + DoubleToStr(EURCHFbidOther, 5) +
               "\nOther Broker EURCHF Ask: " + DoubleToStr(EURCHFaskOther, 5) + ", Spread: " + DoubleToStr(EURCHFspreadOther, 1) +

               "\n----------------------------------------" +

               "\nThis  Broker GBPCHF Bid: " + DoubleToStr(GBPCHFbidThis,  5) +
               "\nThis  Broker GBPCHF Ask: " + DoubleToStr(GBPCHFaskThis,  5) + ", Spread: " + DoubleToStr(GBPCHFspreadThis,  1) +
             "\n\nOther Broker GBPCHF Bid: " + DoubleToStr(GBPCHFbidOther, 5) +
               "\nOther Broker GBPCHF Ask: " + DoubleToStr(GBPCHFaskOther, 5) + ", Spread: " + DoubleToStr(GBPCHFspreadOther, 1) +

               "\n----------------------------------------" +

               "\nThis  Broker GBPUSD Bid: " + DoubleToStr(GBPUSDbidThis,  5) +
               "\nThis  Broker GBPUSD Ask: " + DoubleToStr(GBPUSDaskThis,  5) + ", Spread: " + DoubleToStr(GBPUSDspreadThis,  1) +
             "\n\nOther Broker GBPUSD Bid: " + DoubleToStr(GBPUSDbidOther, 5) +
               "\nOther Broker GBPUSD Ask: " + DoubleToStr(GBPUSDaskOther, 5) + ", Spread: " + DoubleToStr(GBPUSDspreadOther, 1) +

               "\n----------------------------------------" +

               "\nThis  Broker USDCHF Bid: " + DoubleToStr(USDCHFbidThis,  5) +
               "\nThis  Broker USDCHF Ask: " + DoubleToStr(USDCHFaskThis,  5) + ", Spread: " + DoubleToStr(USDCHFspreadThis,  1) +
             "\n\nOther Broker USDCHF Bid: " + DoubleToStr(USDCHFbidOther, 5) +
               "\nOther Broker USDCHF Ask: " + DoubleToStr(USDCHFaskOther, 5) + ", Spread: " + DoubleToStr(USDCHFspreadOther, 1) +

               "\n----------------------------------------" +

               "\nThis  Broker CHFJPY Bid: " + DoubleToStr(CHFJPYbidThis,  3) +
               "\nThis  Broker CHFJPY Ask: " + DoubleToStr(CHFJPYaskThis,  3) + ", Spread: " + DoubleToStr(CHFJPYspreadThis,  1) +
             "\n\nOther Broker CHFJPY Bid: " + DoubleToStr(CHFJPYbidOther, 3) +
               "\nOther Broker CHFJPY Ask: " + DoubleToStr(CHFJPYaskOther, 3) + ", Spread: " + DoubleToStr(CHFJPYspreadOther, 1));
        }
      }
    }
    
    Sleep(50);
  }

  return;
}

//+------------------------------------------------------------------+
//| Move all values to the next index, last value being overwritten. |
//| The first value (index 0) becomes the latest freshness boolean.  |
//+------------------------------------------------------------------+

void RollAliveArrays()
{
  for (i = 19; i >= 1; i--)
  {
    arrSlaveAlive[i]  = arrSlaveAlive[i-1];
    arrMasterAlive[i] = arrMasterAlive[i-1];
  }

  arrSlaveAlive[0]  = SlaveIsFresh;
  arrMasterAlive[0] = MasterIsFresh;

  return;
}

//+------------------------------------------------------------------+
//| Determine if there is a true fresh value in both the master      |
//| and slave arrays and return the result.                          |
//+------------------------------------------------------------------+

bool WeAreAlive()
{
  SlaveFreshFound  = false;
  MasterFreshFound = false;

  for (i = 0; i <= 19; i++)
  {
    if (arrSlaveAlive[i]) { SlaveFreshFound = true; break; }
  }

  for (i = 0; i <= 19; i++)
  {
    if (arrMasterAlive[i]) { MasterFreshFound = true; break; }
  }
  
  return (SlaveFreshFound && MasterFreshFound);
}

//+------------------------------------------------------------------+
//| Get account parameters that affect how the lot size will be set. |
//+------------------------------------------------------------------+

void GetAccountInfo()
{
  // Get account leverage, account type.
  Leverage       = AccountLeverage();

  AccountTypeVal = MarketInfo(Symbol(), MODE_LOTSIZE);
  MaxLots        = MarketInfo(Symbol(), MODE_MAXLOT);
  MinLots        = MarketInfo(Symbol(), MODE_MINLOT);
  LotStep        = MarketInfo(Symbol(), MODE_LOTSTEP);

  return;
}

//+------------------------------------------------------------------+
//|                       Set the account type.                      |
//+------------------------------------------------------------------+

void SetAccountType()
{
  if (AccountTypeVal == MiniSize || StringLen(Symbol()) == 7)
  {
    AccountIsMini     = true;
    AccountTypeString = "MINI";
  }
  else if (AccountTypeVal == StdSize || StringLen(Symbol()) == 6)
  {
    AccountIsMini     = false;
    AccountTypeString = "STANDARD";
  }

  return;
}

//+------------------------------------------------------------------+
//|                          Open trades.                            |
//+------------------------------------------------------------------+

void OpenBuy(string BuySymbol, double BuyLotSize, double TheAsk)
{
  if (TotalTrades < MaxTrades)
  {
    ReturnVal = OrderSend (BuySymbol, OP_BUY, BuyLotSize, TheAsk,
                           Slippage, 0, 0, BuySymbol + " BOUGHT", MagicNumber, Blue);

    Print ("Long " + BuySymbol + ".");
    Sleep (1000);
  }
  return;
}

void OpenSell(string SellSymbol, double SellLotSize, double TheBid)
{
  if (TotalTrades < MaxTrades)
  {
    ReturnVal = OrderSend (SellSymbol, OP_SELL, SellLotSize, TheBid,
                           Slippage, 0, 0, SellSymbol + " SOLD", MagicNumber, Red);

    Print ("Short " + SellSymbol + ".");
    Sleep (1000);
  }
  return;
}

void BuyHereSellThere(string RawSymbol, string FullSymbol, double TheAsk)
{
  TradeMsg = "Sell" + RawSymbol + Sep + DoubleToStr(UseLots, 2);

  if (!QC_SendMessageW (glbTradeHandle, TradeMsg , 3))
  {
    Print ("Message failed");
  }
  else
  {
    OpenBuy (FullSymbol, UseLots, TheAsk);
  }

  return;
}

void BuyThereSellHere(string RawSymbol, string FullSymbol, double TheBid)
{
  TradeMsg = "Buy" + RawSymbol + Sep + DoubleToStr(UseLots, 2);

  if (!QC_SendMessageW (glbTradeHandle, TradeMsg , 3))
  {
    Print ("Message failed");
  }
  else
  {
    OpenSell (FullSymbol, UseLots, TheBid);
  }

  return;
}

//+------------------------------------------------------------------+
//|   Close all open trades.                                         |
//+------------------------------------------------------------------+

void CloseAllTrades()
{
  TradeMsg = "CloseAll" + Sep + DoubleToStr(UseLots, 2);

  if (!QC_SendMessageW (glbTradeHandle, TradeMsg , 3))
  {
    Print ("Message failed, CLOSE MANUALLY if closure is desired.");
  }
  else
  {
    for (i = 0; i < OrdersTotal(); i++)
    {
      ReturnVal = OrderSelect (i, SELECT_BY_POS, MODE_TRADES);

      if (ReturnVal && OrderMagicNumber() == MagicNumber)
      {
        if (OrderType() == OP_BUY)
        {
          ReturnVal = OrderClose (OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), Slippage, White);

          Print ("Closing a ", OrderSymbol(), " buy trade...");
          Sleep (1000);
        }    
        else
        if (OrderType() == OP_SELL)
        {
          ReturnVal = OrderClose (OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), Slippage, White);

          Print ("Closing a ", OrderSymbol(), " sell trade...");
          Sleep (1000);
        }
      }
    }
  }
  
  return;
}

//+------------------------------------------------------------------+
//|                   Format the lot size value.                     |
//+------------------------------------------------------------------+

double FormatLotSize(double RawLots)
{
  RawLots = StrToDouble (DoubleToStr (RawLots / LotStep, 0)) * LotStep;

  if (RawLots < MinLots || UseMinLots) RawLots = MinLots;

  return (StrToDouble (DoubleToStr (RawLots, 2)));
}

//+------------------------------------------------------------------+
//|                       Set the lot size.                          |
//+------------------------------------------------------------------+

void SetLotSize()
{
  Investment = MaxMarginToUse / 100.0;

  // The symbol the EA is attached to is used for the purpose of MODE_LOTSIZE

  UseLots = FormatLotSize(AccountBalance() * Investment * (Leverage / MarketInfo(Symbol(), MODE_LOTSIZE)));

  return;
}

//+------------------------------------------------------------------+
//|  Do accounting of profit/loss and the number of open trades.     |
//+------------------------------------------------------------------+

void Count_PL_Trades()
{
  MasterPL    = 0.0;
  TotalTrades = 0;
  EURUSDbuys  = 0;
  EURUSDsells = 0;
  USDJPYbuys  = 0;
  USDJPYsells = 0;
  EURJPYbuys  = 0;
  EURJPYsells = 0;
  GBPJPYbuys  = 0;
  GBPJPYsells = 0;
  EURGBPbuys  = 0;
  EURGBPsells = 0;
  EURCHFbuys  = 0;
  EURCHFsells = 0;
  GBPCHFbuys  = 0;
  GBPCHFsells = 0;
  GBPUSDbuys  = 0;
  GBPUSDsells = 0;
  USDCHFbuys  = 0;
  USDCHFsells = 0;
  CHFJPYbuys  = 0;

  for (i = 0; i < OrdersTotal(); i++)
  {
    ReturnVal = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);

    if (ReturnVal && OrderMagicNumber() == MagicNumber)
    {
      MasterPL += OrderProfit() + OrderSwap() + OrderCommission();
      TotalTrades++;

      if (OrderType() == OP_BUY)
      {
        if (OrderSymbol() == EURUSDsym) EURUSDbuys++;
        else
        if (OrderSymbol() == USDJPYsym) USDJPYbuys++;
        else
        if (OrderSymbol() == EURJPYsym) EURJPYbuys++;
        else
        if (OrderSymbol() == GBPJPYsym) GBPJPYbuys++;
        else
        if (OrderSymbol() == EURGBPsym) EURGBPbuys++;
        else
        if (OrderSymbol() == EURCHFsym) EURCHFbuys++;
        else
        if (OrderSymbol() == GBPCHFsym) GBPCHFbuys++;
        else
        if (OrderSymbol() == GBPUSDsym) GBPUSDbuys++;
        else
        if (OrderSymbol() == USDCHFsym) USDCHFbuys++;
        else
        if (OrderSymbol() == CHFJPYsym) CHFJPYbuys++;
      }

      if (OrderType() == OP_SELL)
      {
        if (OrderSymbol() == EURUSDsym) EURUSDsells++;
        else
        if (OrderSymbol() == USDJPYsym) USDJPYsells++;
        else
        if (OrderSymbol() == EURJPYsym) EURJPYsells++;
        else
        if (OrderSymbol() == GBPJPYsym) GBPJPYsells++;
        else
        if (OrderSymbol() == EURGBPsym) EURGBPsells++;
        else
        if (OrderSymbol() == EURCHFsym) EURCHFsells++;
        else
        if (OrderSymbol() == GBPCHFsym) GBPCHFsells++;
        else
        if (OrderSymbol() == GBPUSDsym) GBPUSDsells++;
        else
        if (OrderSymbol() == USDCHFsym) USDCHFsells++;
        else
        if (OrderSymbol() == CHFJPYsym) CHFJPYsells++;
      }
    }
  }

  return;
}
