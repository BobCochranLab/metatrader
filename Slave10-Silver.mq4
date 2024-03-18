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

extern int    MaxTrades         =      1;
extern int    Slippage          =      3;
extern int    MiniSize          =  10000;
extern int    StdSize           = 100000;
extern int    MagicNumber       = 219283;

//+------------------------------------------------------------------+
//|                    Internal Global Variables                     |
//+------------------------------------------------------------------+

bool AccountIsMini  = false,
     ReturnVal      = false;

double OverallPL = 0.0,

       UseLots   = 0.0,

       EURUSDbid = 0.0, EURUSDask = 0.0,
       USDJPYbid = 0.0, USDJPYask = 0.0,
       EURJPYbid = 0.0, EURJPYask = 0.0,
       GBPJPYbid = 0.0, GBPJPYask = 0.0,
       EURGBPbid = 0.0, EURGBPask = 0.0,
       EURCHFbid = 0.0, EURCHFask = 0.0,
       GBPCHFbid = 0.0, GBPCHFask = 0.0,
       GBPUSDbid = 0.0, GBPUSDask = 0.0,
       USDCHFbid = 0.0, USDCHFask = 0.0,
       CHFJPYbid = 0.0, CHFJPYask = 0.0;

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

       RatesMsg  = "",
       TradeMsg  = "",
       Suffix    = "",
       Sep       = "|",

       TradeArray[];   // Buys/Sell/Close commands and related data from the Master

int i              = 0,
    AccountTypeVal = 0,
    glbRatesHandle = 0,
    glbTradeHandle = 0,
    intResult      = 0,
    TotalTrades    = 0;

ushort SepCode = 0;

uchar glbTradeBuffer[]; // Allocated on initialization


//+------------------------------------------------------------------+
//|                   Initialization Event Handler                   |
//+------------------------------------------------------------------+

void OnInit()
{
  SetSymbolStrings();
  SetAccountType();

  SepCode = StringGetCharacter (Sep, 0);

  glbRatesHandle = QC_StartSenderW ("RatesChannel");

  // Create handle and buffer if not already done (i.e. on first tick)

  if (!glbTradeHandle)
  {
    glbTradeHandle = QC_StartReceiverW ("TradeChannel", WindowHandle(Symbol(), Period()));
    ArrayResize (glbTradeBuffer, QC_BUFFER_SIZE);
  }
  
  if (glbTradeHandle) 
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
  QC_ReleaseSender (glbRatesHandle);

  if (glbTradeHandle) QC_ReleaseReceiver (glbTradeHandle);

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

    intResult = QC_GetMessages5W (glbTradeHandle, glbTradeBuffer, QC_BUFFER_SIZE);

    TradeMsg      = "";
    TradeArray[0] = "";
    TradeArray[1] = "";
    UseLots       = 0.0;

    if (intResult > 0)
    {
      TradeMsg = CharArrayToString (glbTradeBuffer, 0, intResult);

      // Unpack the "|" delimited string into TradeArray.

      intResult = StringSplit(TradeMsg, SepCode, TradeArray);

      if (intResult) UseLots = StringToDouble(TradeArray[1]);
    }

    if (TradeMsg != "" && TradeArray[0] != "" && TradeArray[1] != "" && UseLots != 0.0)
    {
      if (TradeArray[0] == "CloseAll")
      {
        CloseAllTrades();
      }
      else
      if (TradeArray[0] == "BuyEURUSD")
      {
        OpenBuy(EURUSDsym, UseLots);
      }
      else
      if (TradeArray[0] == "SellEURUSD")
      {
        OpenSell(EURUSDsym, UseLots);
      }
      else
      if (TradeArray[0] == "BuyUSDJPY")
      {
        OpenBuy(USDJPYsym, UseLots);
      }
      else
      if (TradeArray[0] == "SellUSDJPY")
      {
        OpenSell(USDJPYsym, UseLots);
      }
      else
      if (TradeArray[0] == "BuyEURJPY")
      {
        OpenBuy(EURJPYsym, UseLots);
      }
      else
      if (TradeArray[0] == "SellEURJPY")
      {
        OpenSell(EURJPYsym, UseLots);
      }
      else
      if (TradeArray[0] == "BuyGBPJPY")
      {
        OpenBuy(GBPJPYsym, UseLots);
      }
      else
      if (TradeArray[0] == "SellGBPJPY")
      {
        OpenSell(GBPJPYsym, UseLots);
      }
      else
      if (TradeArray[0] == "BuyEURGBP")
      {
        OpenBuy(EURGBPsym, UseLots);
      }
      else
      if (TradeArray[0] == "SellEURGBP")
      {
        OpenSell(EURGBPsym, UseLots);
      }
      else
      if (TradeArray[0] == "BuyEURCHF")
      {
        OpenBuy(EURCHFsym, UseLots);
      }
      else
      if (TradeArray[0] == "SellEURCHF")
      {
        OpenSell(EURCHFsym, UseLots);
      }
      else
      if (TradeArray[0] == "BuyGBPCHF")
      {
        OpenBuy(GBPCHFsym, UseLots);
      }
      else
      if (TradeArray[0] == "SellGBPCHF")
      {
        OpenSell(GBPCHFsym, UseLots);
      }
      else
      if (TradeArray[0] == "BuyGBPUSD")
      {
        OpenBuy(GBPUSDsym, UseLots);
      }
      else
      if (TradeArray[0] == "SellGBPUSD")
      {
        OpenSell(GBPUSDsym, UseLots);
      }
      else
      if (TradeArray[0] == "BuyUSDCHF")
      {
        OpenBuy(USDCHFsym, UseLots);
      }
      else
      if (TradeArray[0] == "SellUSDCHF")
      {
        OpenSell(USDCHFsym, UseLots);
      }
      else
      if (TradeArray[0] == "BuyCHFJPY")
      {
        OpenBuy(CHFJPYsym, UseLots);
      }
      else
      if (TradeArray[0] == "SellCHFJPY")
      {
        OpenSell(CHFJPYsym, UseLots);
      }
    }

    EURUSDbid = 0.0; EURUSDask = 0.0;
    USDJPYbid = 0.0; USDJPYask = 0.0;
    EURJPYbid = 0.0; EURJPYask = 0.0;
    GBPJPYbid = 0.0; GBPJPYask = 0.0;
    EURGBPbid = 0.0; EURGBPask = 0.0;
    EURCHFbid = 0.0; EURCHFask = 0.0;
    GBPCHFbid = 0.0; GBPCHFask = 0.0;
    GBPUSDbid = 0.0; GBPUSDask = 0.0;
    USDCHFbid = 0.0; USDCHFask = 0.0;
    CHFJPYbid = 0.0; CHFJPYask = 0.0;

    EURUSDbid = MarketInfo (EURUSDsym, MODE_BID); EURUSDask = MarketInfo (EURUSDsym, MODE_ASK);
    USDJPYbid = MarketInfo (USDJPYsym, MODE_BID); USDJPYask = MarketInfo (USDJPYsym, MODE_ASK);
    EURJPYbid = MarketInfo (EURJPYsym, MODE_BID); EURJPYask = MarketInfo (EURJPYsym, MODE_ASK);
    GBPJPYbid = MarketInfo (GBPJPYsym, MODE_BID); GBPJPYask = MarketInfo (GBPJPYsym, MODE_ASK);
    EURGBPbid = MarketInfo (EURGBPsym, MODE_BID); EURGBPask = MarketInfo (EURGBPsym, MODE_ASK);
    EURCHFbid = MarketInfo (EURCHFsym, MODE_BID); EURCHFask = MarketInfo (EURCHFsym, MODE_ASK);
    GBPCHFbid = MarketInfo (GBPCHFsym, MODE_BID); GBPCHFask = MarketInfo (GBPCHFsym, MODE_ASK);
    GBPUSDbid = MarketInfo (GBPUSDsym, MODE_BID); GBPUSDask = MarketInfo (GBPUSDsym, MODE_ASK);
    USDCHFbid = MarketInfo (USDCHFsym, MODE_BID); USDCHFask = MarketInfo (USDCHFsym, MODE_ASK);
    CHFJPYbid = MarketInfo (CHFJPYsym, MODE_BID); CHFJPYask = MarketInfo (CHFJPYsym, MODE_ASK);

    // Build the "|" delimited bid/ask message to send to the other terminal.

    RatesMsg = DoubleToStr (EURUSDbid, 5) + Sep + DoubleToStr(EURUSDask, 5) + Sep +
               DoubleToStr (USDJPYbid, 3) + Sep + DoubleToStr(USDJPYask, 3) + Sep +
               DoubleToStr (EURJPYbid, 3) + Sep + DoubleToStr(EURJPYask, 3) + Sep +
               DoubleToStr (GBPJPYbid, 3) + Sep + DoubleToStr(GBPJPYask, 3) + Sep +
               DoubleToStr (EURGBPbid, 5) + Sep + DoubleToStr(EURGBPask, 5) + Sep +
               DoubleToStr (EURCHFbid, 5) + Sep + DoubleToStr(EURCHFask, 5) + Sep +
               DoubleToStr (GBPCHFbid, 5) + Sep + DoubleToStr(GBPCHFask, 5) + Sep +
               DoubleToStr (GBPUSDbid, 5) + Sep + DoubleToStr(GBPUSDask, 5) + Sep +
               DoubleToStr (USDCHFbid, 5) + Sep + DoubleToStr(USDCHFask, 5) + Sep +
               DoubleToStr (CHFJPYbid, 3) + Sep + DoubleToStr(CHFJPYask, 3) + Sep +
               DoubleToStr (OverallPL, 2);

    // Send the message.

    if (!QC_SendMessageW (glbRatesHandle, RatesMsg , 3))
    {
      Print ("Message failed");
    }

    Comment (strDayOfWeek + ", Hour " + Hour() + ", Account Type: " + AccountTypeString + ", Lot Size: " + UseLots);
               
    Sleep(50);
  }

  return;
}

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

void OpenBuy(string BuySymbol, double BuyLotSize)
{
  if (TotalTrades < MaxTrades)
  {
    ReturnVal = OrderSend (BuySymbol, OP_BUY, BuyLotSize, MarketInfo(BuySymbol, MODE_ASK),
                           Slippage, 0, 0, BuySymbol + " BOUGHT", MagicNumber, Blue);

    Print ("Long " + BuySymbol + ".");
    Sleep (1000);
  }
  return;
}

void OpenSell(string SellSymbol, double SellLotSize)
{
  if (TotalTrades < MaxTrades)
  {
    ReturnVal = OrderSend (SellSymbol, OP_SELL, SellLotSize, MarketInfo(SellSymbol, MODE_BID),
                           Slippage, 0, 0, SellSymbol + " SOLD", MagicNumber, Red);

    Print ("Short " + SellSymbol + ".");
    Sleep (1000);
  }
  return;
}

//+------------------------------------------------------------------+
//|   Close all open trades.                                         |
//+------------------------------------------------------------------+

void CloseAllTrades()
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
  
  return;
}

//+------------------------------------------------------------------+
//|  Do accounting of profit/loss and the number of open trades.     |
//+------------------------------------------------------------------+

void Count_PL_Trades()
{
  OverallPL   = 0.0;
  TotalTrades = 0;

  for (i = 0; i < OrdersTotal(); i++)
  {
    ReturnVal = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);

    if (ReturnVal && OrderMagicNumber() == MagicNumber)
    {
      OverallPL += OrderProfit() + OrderSwap() + OrderCommission();
      TotalTrades++;
    }
  }

  return;
}
