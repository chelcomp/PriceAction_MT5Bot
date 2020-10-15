//+------------------------------------------------------------------+
//|                                                      PriceAction |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  PROPERTIES                                                      |
//+------------------------------------------------------------------+
#property version "100.001"
#property description "Price Action Bot ( Mimic SmartBot PriceAction Bot )"
#property script_show_inputs
//---
#property indicator_applied_price PRICE_CLOSE
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   1
#property indicator_type1   DRAW_CANDLES
#property indicator_width1  3
#property indicator_label1  "C open;C high;C low;C close"



//+------------------------------------------------------------------+
//| INCLUDE SECTION                                                  |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
#include <Trade/AccountInfo.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/OrderInfo.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Expert/ExpertBase.mqh>


#include "Enums/AllowedTimeFrame.mqh"
#include "Enums/CloseOrderType.mqh"
#include "Enums/FilterDxDyMode.mqh"
#include "Enums/OperationDirection.mqh"
#include "Enums/OperationDirectionEnum.mqh"
#include "Enums/OperationDisruption.mqh"
#include "Enums/OperationMode.mqh"
#include "Enums/OrderSendType.mqh"
#include "Enums/TimeInterval.mqh"
#include "Inputs/Global.mqh"
#include "DateTime/DateTimeHelper.mqh"
#include "OnTradeFunction.mqh"


//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                 |
//+------------------------------------------------------------------+
CTrade Trade;
CAccountInfo AccountInfo;
CPositionInfo PositionInfo;
COrderInfo OrderInfo;
CSymbolInfo *SymbolInfo;
CExpertBase ExpertBase;

MqlRates SelectedRates[];
static MqlRates lastProcessedBar;
datetime CurrentDateTime;
datetime CurrentTime;
datetime PreviousDateTime;
datetime PreviousTime;
bool     IsNewCandle;
//double   PositionPriceOpen;
//double   PositionPriceCurrent;
//double   PositionPriceDifference;

ENUM_TIMEFRAMES SelectedTimeframe;

static double DayTradeProfit;
static bool CloseAllDailyPositions;
static double PreviousDayAcumulatedProfit;
static int CountDayTrades;

static int PositionVolume;
static datetime DailyBeginTime;
static datetime Window1BeginTime;
static datetime Window1EndTime;
static datetime Window2BeginTime;
static datetime Window2EndTime;
static datetime DailyEndTime;
static datetime DailyCloseTime;

static int DX;
static int DY;

static int StopGainQuantity;
static double StopGain1; // Stop Gain 1
static double StopGain2; // Stop Gain 2
static double StopGain3; // Stop Gain 3
static double StopGain4; // Stop Gain 4
static double StopGain5; // Stop Gain 5
static int StopGain1Volume; // Stop Gain 1
static int StopGain2Volume; // Stop Gain 2
static int StopGain3Volume; // Stop Gain 3
static int StopGain4Volume; // Stop Gain 4
static int StopGain5Volume; // Stop Gain 5
static bool StopGain1Avaliable; // Stop Gain 1 Is Avaliable
static bool StopGain2Avaliable; // Stop Gain 2 Is Avaliable
static bool StopGain3Avaliable; // Stop Gain 3 Is Avaliable
static bool StopGain4Avaliable; // Stop Gain 4 Is Avaliable
static bool StopGain5Avaliable; // Stop Gain 5 Is Avaliable
static bool StopGainBreakEven;
static bool StopGainBreakEvenActivated;

static double StopLoss;
static double TrailingStopActivation;
static double TrailingStopDistance;
static bool TrailingStopActivated;
static double TrailingStopWatherMark;

static int StopAfterXTrades;

static bool DailyBreakEvanActivated;
static double DailyBreakevenActivationMoney;
static double DailyBreakevenMaxDrownDownMoney;
static double DailyBreakevenWatherMark;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
   {
//+------------------------------------------------------------------+
//| Global Variable initialization                                   |
//+------------------------------------------------------------------+
    SelectedTimeframe = AllowedTimeFrame2TimeFrame(input_TimeFrame);
    ExpertBase.EveryTick(true);

    SymbolInfo = new CSymbolInfo;
    SymbolInfo.Name(_Symbol);
    SymbolInfo.Select(true);
//ExpertBase.Init(SymbolInfo, SelectedTimeframe, 0);



    PositionVolume  = input_positionVolume > 0 ? input_positionVolume : 1;

    DailyBeginTime   = TimeIntervalToTime(input_DailyBeginTime);
    Window1BeginTime = TimeIntervalToTime(input_Window1BeginTime);
    Window1EndTime   = TimeIntervalToTime(input_Window1EndTime);
    Window2BeginTime = TimeIntervalToTime(input_Window2BeginTime);
    Window2EndTime   = TimeIntervalToTime(input_Window2EndTime);
    DailyEndTime     = TimeIntervalToTime(input_DailyEndTime);
    DailyCloseTime   = TimeIntervalToTime(input_DailyCloseTime);

    datetime minDateTime = TimeIntervalToTime(t0000);
    datetime maxDateTime = TimeIntervalToTime(t1900);

    if(
        (DailyCloseTime > minDateTime
         && (
             DailyCloseTime < MathMax(MathMax(MathMax(MathMax(MathMax(MathMax(DailyEndTime, DailyEndTime), Window2EndTime), Window2BeginTime), Window1EndTime), Window1BeginTime), DailyBeginTime)
         ))
        || (DailyEndTime > minDateTime
            && (
                DailyEndTime < MathMax(MathMax(MathMax(MathMax(MathMax(DailyEndTime, Window2EndTime), Window2BeginTime), Window1EndTime), Window1BeginTime), DailyBeginTime)
            ))
        || (Window2EndTime > minDateTime
            && (
                Window2EndTime < Window2BeginTime
                || Window2EndTime < MathMax(MathMax(MathMax(Window2BeginTime, Window1EndTime), Window1BeginTime), DailyBeginTime)
                || Window2BeginTime == minDateTime
            ))
        || (Window2BeginTime > minDateTime
            && (
                Window2BeginTime < MathMax(MathMax(Window1EndTime, Window1BeginTime), DailyBeginTime)
            ))

        || (Window1EndTime > minDateTime
            && (
                Window1EndTime < Window1BeginTime
                || Window1EndTime < MathMax(Window1BeginTime, DailyBeginTime)
                || Window1BeginTime == minDateTime
            ))
        || (Window1BeginTime > minDateTime
            && (
                Window1BeginTime < DailyBeginTime
            ))
    )
       {
        Print("Please check the window dates parameters.");
        return(INIT_PARAMETERS_INCORRECT);
       }

    DailyEndTime = DailyEndTime == minDateTime ? maxDateTime : DailyEndTime;

    DX = input_filterDxDyMode == fDX ? (int)filterDxDy : 0 ;
    DY = input_filterDxDyMode == fDY ? (int)filterDxDy : 0;

    ArraySetAsSeries(SelectedRates, true);

//+------------------------------------------------------------------+
//|  Partial Gain Validation                                         |
//+------------------------------------------------------------------+
    StopGain1 = input_StopGain1;
    StopGain2 = input_StopGain2;
    StopGain3 = input_StopGain3;
    StopGain4 = input_StopGain4;
    StopGain5 = input_StopGain5;

    ResetStopGainAvaliability();

    if((StopGain5Avaliable && PositionVolume < 5)
       || (StopGain4Avaliable && PositionVolume < 4)
       || (StopGain3Avaliable && PositionVolume < 3)
       || (StopGain2Avaliable && PositionVolume < 2)
       || (StopGain1Avaliable && PositionVolume < 1)

       || (StopGain2Avaliable && StopGain1 >= StopGain2)
       || (StopGain3Avaliable && StopGain2 >= StopGain3)
       || (StopGain4Avaliable && StopGain3 >= StopGain4)
       || (StopGain5Avaliable && StopGain4 >= StopGain5))
       {
        Print("Please check the StopGain parameters.");
        return(INIT_PARAMETERS_INCORRECT);
       }

//+------------------------------------------------------------------+
//| Stop Gain Setting                                                |
//+------------------------------------------------------------------+
    StopGainQuantity = 0;
    StopGainQuantity += StopGain1Avaliable ? 1 : 0;
    StopGainQuantity += StopGain2Avaliable ? 1 : 0;
    StopGainQuantity += StopGain3Avaliable ? 1 : 0;
    StopGainQuantity += StopGain4Avaliable ? 1 : 0;
    StopGainQuantity += StopGain5Avaliable ? 1 : 0;

    StopGain1Volume = StopGain1Avaliable ? (int)(PositionVolume) / (StopGainQuantity) : 0;
    StopGain2Volume = StopGain2Avaliable ? (int)(PositionVolume - StopGain1Volume) / (StopGainQuantity - 1) : 0;
    StopGain3Volume = StopGain3Avaliable ? (int)(PositionVolume - StopGain1Volume - StopGain2Volume) / (StopGainQuantity - 2) : 0;
    StopGain4Volume = StopGain4Avaliable ? (int)(PositionVolume - StopGain1Volume - StopGain2Volume - StopGain3Volume) / (StopGainQuantity - 3) : 0;
    StopGain5Volume = StopGain5Avaliable ? (int)(PositionVolume - StopGain1Volume - StopGain2Volume - StopGain3Volume - StopGain4Volume) / (StopGainQuantity - 4) : 0;

    StopGainBreakEven = StopGain1Avaliable ? Input_StopGainBreakEven : false;

    StopLoss = input_StopLoss > 0 ? input_StopLoss : 0;
    TrailingStopActivation = input_TrailingStopActivation > 0 ? input_TrailingStopActivation : 0;
    TrailingStopDistance = input_TrailingStopDistance > 0 ? input_TrailingStopDistance : 0;
    TrailingStopActivated = false;
    TrailingStopWatherMark = 0;

    if((TrailingStopActivation == 0 && TrailingStopActivation > 0)
       || (TrailingStopActivation > 0 && TrailingStopActivation == 0))
       {
        Print("Please check the Traling Stop parameters.");
        return(INIT_PARAMETERS_INCORRECT);
       }

    if(StopGain1 > 0 && TrailingStopActivation >= MathMax(MathMax(MathMax(MathMax(StopGain1, StopGain2), StopGain3), StopGain4), StopGain5))
       {
        Print("Please check the Traling Activation vs GainStop setting.");
        return(INIT_PARAMETERS_INCORRECT);
       }

//TesterWithdrawal()
    StopGainBreakEvenActivated = false;

    StopAfterXTrades = input_StopAfterXTrades;
    if(input_StopAfterXTradesMode != saNone && StopAfterXTrades == 0)
       {
        Print("Please check the Stop after X Trades parameters.");
        return(INIT_PARAMETERS_INCORRECT);
       }

//+------------------------------------------------------------------+
//| Daily BreakEven                                                  |
//+------------------------------------------------------------------+
    DailyBreakEvanActivated = false;
    DailyBreakevenActivationMoney = input_DailyBreakevenActivationMoney;
    DailyBreakevenMaxDrownDownMoney = input_DailyBreakevenMaxDrownDownMoney;
    if((DailyBreakevenActivationMoney == 0 && DailyBreakevenMaxDrownDownMoney > 0)
       || (DailyBreakevenActivationMoney > 0 && DailyBreakevenMaxDrownDownMoney == 0))
       {
        Print("Please check the Breakeven parameters.");
        return(INIT_PARAMETERS_INCORRECT);
       }

//+------------------------------------------------------------------+
//| Trade Settings                                                   |
//+------------------------------------------------------------------+
    Trade.LogLevel(LOG_LEVEL_ALL); // https://www.mql5.com/en/docs/standardlibrary/tradeclasses/ctrade/ctradeLogLevel
    Trade.SetExpertMagicNumber(input_MagicNumber); // https://www.mql5.com/en/docs/standardlibrary/tradeclasses/ctrade/ctradesetexpertmagicnumber
    Trade.SetAsyncMode(true); // https://www.mql5.com/en/docs/standardlibrary/tradeclasses/ctrade/ctradesetasyncmode


    ResetDayTrade();

    PrintFormat("LAST PING=%.f ms", TerminalInfoInteger(TERMINAL_PING_LAST) / 1000.);

    return(INIT_SUCCEEDED);
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResetStopGainAvaliability()
   {
    StopGain1Avaliable = StopGain1 > 0;
    StopGain2Avaliable = StopGain2 > 0;
    StopGain3Avaliable = StopGain3 > 0;
    StopGain4Avaliable = StopGain4 > 0;
    StopGain5Avaliable = StopGain5 > 0;
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResetDayTrade()
   {
    CountDayTrades = 0;
    CloseAllDailyPositions = false;
    DailyBreakEvanActivated = false;
    PreviousDayAcumulatedProfit = AccountInfo.Balance();
    lastProcessedBar.time = NULL;
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResetTrade()
   {
    ResetStopGainAvaliability();
    TrailingStopActivated = false;
    StopGainBreakEvenActivated = false;
   }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HasOrder ;
bool HasPosition;


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
   {
    PositionInfo.Select(_Symbol);
    IsNewCandle = isNewCandle();
    PreviousDateTime = CurrentDateTime;
    PreviousTime = CurrentTime;
    CurrentDateTime = TimeTradeServer();
    CurrentTime = DateTime2Time(CurrentDateTime);
    HasOrder = OrdersTotal() > 0;
    HasPosition = PositionsTotal() > 0;
    bool buySignal = false;
    bool sellSignal = false;
    CopyRates(Symbol(), SelectedTimeframe, 0, 3, SelectedRates);

    if(IsNewCandle && PreviousTime > CurrentTime)
        ResetDayTrade();

    if(!HasOrder && !HasPosition)
        ResetTrade();

    if(HasOrder || HasPosition || lastProcessedBar.time == NULL)
        lastProcessedBar = SelectedRates[0];

    DayTradeProfit = DailyProfit();

// --- Process Close
    CloseAllDailyPositions = CloseAllDailyPositions || OutOfDailyOpperatonalTimeWindow();
    CloseAllDailyPositions = CloseAllDailyPositions || DailyStopLoss();
    CloseAllDailyPositions = CloseAllDailyPositions || DailyStopGain();

    if(CloseAllDailyPositions)
       {
        CloseAllPositions();
        CancelAllPendingOrders();
        return;
       }

// --- Process Input
    bool canOpenOrder = !HasOrder  && !HasPosition && !CloseAllDailyPositions;
    canOpenOrder = canOpenOrder && DateTimeBetween(CurrentTime, DailyBeginTime, DailyEndTime);
    canOpenOrder = canOpenOrder && !DateTimeBetween(CurrentTime, Window1BeginTime, Window1EndTime);
    canOpenOrder = canOpenOrder && !DateTimeBetween(CurrentTime, Window2BeginTime, Window2EndTime);
    canOpenOrder = canOpenOrder && !StopAfterXDailyTrades();

    if(canOpenOrder)
        getBuySellSignal(buySignal, sellSignal);

    bool OrderCreated = InputOrder(buySignal, sellSignal);

// --- Process Output
    if(HasOrder || HasPosition || OrderCreated)
       {

        //-- Gain
        if(input_StopGainOrderType == cMarket)
           {
            bool _ = OutputOrderMarketStopGainProcess(StopGain5Avaliable, StopGain5, StopGain5Volume)
                     || OutputOrderMarketStopGainProcess(StopGain4Avaliable, StopGain4, StopGain4Volume)
                     || OutputOrderMarketStopGainProcess(StopGain3Avaliable, StopGain3, StopGain3Volume)
                     || OutputOrderMarketStopGainProcess(StopGain2Avaliable, StopGain2, StopGain2Volume)
                     || OutputOrderMarketStopGainProcess(StopGain1Avaliable, StopGain1, StopGain1Volume);

           }
        else
            if(input_StopGainOrderType == cLimit)
               {
                bool _ = OutputOrderLimitStopGainProcess(StopGain1Avaliable, StopGain1, StopGain1Volume)
                         || OutputOrderLimitStopGainProcess(StopGain2Avaliable, StopGain2, StopGain2Volume)
                         || OutputOrderLimitStopGainProcess(StopGain3Avaliable, StopGain3, StopGain3Volume)
                         || OutputOrderLimitStopGainProcess(StopGain4Avaliable, StopGain4, StopGain4Volume)
                         || OutputOrderLimitStopGainProcess(StopGain5Avaliable, StopGain5, StopGain5Volume);
               }

        //-- Loss
        if(StopLoss > 0 && getPositionPriceDifference() <= (StopLoss * -1))
           {
            CancelAllPendingOrders();
            CloseAllPositions();
            return;
           }

        bool orderCreated = EnableStopGainBreakEven(StopGain1);
        if(orderCreated)
            return;

        orderCreated = DailyBreakEven();
        if(orderCreated)
            return;

        orderCreated = TrailingStop();
        if(orderCreated)
            return;
       }

   }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getPositionPriceDifference()
   {
    if(PositionInfo.Ticket() > 0)
       {
        double current = PositionInfo.PriceCurrent();
        double open = PositionInfo.PriceOpen();

        if(PositionInfo.PositionType() == POSITION_TYPE_BUY)
            return current - open;

        if(PositionInfo.PositionType() == POSITION_TYPE_SELL)
            return open - current;
       }
    return 0;
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DailyProfit()
   {
    return AccountInfo.Equity() - PreviousDayAcumulatedProfit;
   }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TrailingStop()
   {
    if(TrailingStopDistance == 0)
        return false;

    double PositionPriceDifference = getPositionPriceDifference();

    if(!TrailingStopActivated
       && PositionPriceDifference >= TrailingStopActivation)
       {
        TrailingStopActivated = true;
        TrailingStopWatherMark  = 0;
       }

    if(TrailingStopActivated)
       {
        TrailingStopWatherMark = MathMax(TrailingStopWatherMark, PositionInfo.PriceCurrent());

        if(PositionInfo.PriceCurrent() < TrailingStopWatherMark - TrailingStopDistance)
           {
            CancelAllPendingOrders();
            CloseAllPositions();
            return true;
           }
       }

    return false;
   }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool EnableStopGainBreakEven(double StopGain)
   {
    if(StopGain <= 0)
        return false;

    double PositionDifference = getPositionPriceDifference();

    if(!StopGainBreakEvenActivated
       && PositionDifference >= StopGain)
       {
        StopGainBreakEvenActivated = true;
       }

    if(StopGainBreakEvenActivated
       && PositionInfo.Profit() <= 0)
       {
        CancelAllPendingOrders();
        CloseAllPositions();
        return true;
       }

    return false;
   }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool DailyBreakEven()
   {
    if(DailyBreakevenActivationMoney == 0)
        return false;

    if(!DailyBreakEvanActivated
       && DayTradeProfit >= DailyBreakevenActivationMoney)
       {
        DailyBreakEvanActivated = true;
        DailyBreakevenWatherMark = 0;
       }

    if(DailyBreakEvanActivated)
       {
        DailyBreakevenWatherMark = MathMax(DayTradeProfit, DailyBreakevenWatherMark);

        if(DayTradeProfit < DailyBreakevenWatherMark - DailyBreakevenMaxDrownDownMoney)
           {
            CancelAllPendingOrders();
            CloseAllPositions();
            CloseAllDailyPositions = true;
            return true;
           }
       }

    return false;
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OutputOrderMarketStopGainProcess(bool &StopGainAvaliable, double StopGain, int StopGainVolume)
   {
    if(StopGain <= 0)
        return false;

    double PositionPriceDifference = getPositionPriceDifference();
    if(StopGainAvaliable && PositionPriceDifference >= StopGain)
       {
        OutputOrderMarket(StopGainVolume);
        StopGainAvaliable = false;
        return true;
       }
    return false;
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OutputOrderLimitStopGainProcess(bool &StopGainAvaliable, double StopGain, int StopGainVolume)
   {
    if(StopGain <= 0)
        return false;

    int orderTotal = OrdersTotal() + PositionsTotal();
    if(StopGainAvaliable && orderTotal == 1)
       {
        OutputOrderLimit(StopGain, StopGainVolume);
        StopGainAvaliable = false;
        return true;
       }
    return false;
   }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OutputOrderMarket(int Volume)
   {
    string comment = "Market StopGain";
    if(PositionInfo.PositionType() == POSITION_TYPE_SELL)
        Trade.Buy(Volume, _Symbol, 0, 0, 0, comment);

    if(PositionInfo.PositionType() == POSITION_TYPE_BUY)
        Trade.Sell(Volume, _Symbol, 0, 0, 0, comment);
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OutputOrderLimit(double StopGain, int Volume)
   {
    string comment = "Limit StopGain";
    if(PositionInfo.PositionType() == POSITION_TYPE_SELL)
       {
        double price =  SymbolInfo.NormalizePrice(PositionInfo.PriceOpen() - StopGain);
        Trade.BuyStop(Volume, price, _Symbol, 0, 0, ORDER_TIME_GTC, TimeTradeServer(), comment);
       }
    if(PositionInfo.PositionType() == POSITION_TYPE_BUY)
       {
        double price = SymbolInfo.NormalizePrice(PositionInfo.PriceOpen() + StopGain);
        Trade.SellStop(Volume, price, _Symbol, 0, 0, ORDER_TIME_GTC, TimeTradeServer(), comment);
       }
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OutOfDailyOpperatonalTimeWindow()
   {
    if(DailyCloseTime == 0)
       {
        return(false);
       }
    return CurrentTime >= DailyCloseTime;
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool DailyStopLoss()
   {
    return (input_dailyStopLossMoney > 0 && DayTradeProfit < 0 && DayTradeProfit < input_dailyStopLossMoney);
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool DailyStopGain()
   {
    return (input_dailyStopGainMoney > 0 && DayTradeProfit > 0 && DayTradeProfit > input_dailyStopGainMoney);
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool StopAfterXDailyTrades()
   {
    static ulong lastPositionTicket = 0;
    if(lastPositionTicket != PositionInfo.Ticket() && PositionInfo.Ticket() != 0)
       {
        CountDayTrades++;
        lastPositionTicket = PositionInfo.Ticket();
       }

    if(CountDayTrades >= StopAfterXTrades
       && (input_StopAfterXTradesMode == saBoth
           || (input_StopAfterXTradesMode == saLossing && DayTradeProfit < 0)
           || (input_StopAfterXTradesMode == saWinning && DayTradeProfit > 0)))
       {
        return true;
       }
    return false;
   }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllPositions()
   {
    uint posOpened = PositionsTotal();
    for(uint i = 0; i < posOpened; i++)
       {
        ulong ticket = PositionGetTicket(i);
        Print("Closed Position no.: " + IntegerToString(ticket) + " by day trade time");
        Trade.PositionClose(ticket);
       }
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CancelAllPendingOrders()
   {
    uint pendingOrders = OrdersTotal();
    for(uint i = 0; i < pendingOrders; i++)
       {
        ulong ticket = OrderGetTicket(i);
        Print("Canceled Order no.: " + IntegerToString(ticket) + " by day trade time");
        Trade.OrderDelete(ticket);
       }
   }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &OnTradeTransaction,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
   {
    myOnTradeTransaction(OnTradeTransaction, request, result);
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool InputOrder(bool buySignal, bool sellSignal)
   {
    if((!buySignal && !sellSignal) || (buySignal && sellSignal))
        return false;

    double _positionVolume = NomalizeSymbolVolume(PositionVolume);

    if(orderSendType == oMarket)
       {
        if(buySignal)
           {
            string _comment = "Market Buy";
            return Trade.Buy(_positionVolume, _Symbol, 0, 0, 0, _comment);
           }
        if(sellSignal)
           {
            string _comment = "Market Sell" ;
            return Trade.Sell(_positionVolume, _Symbol, 0, 0, 0, _comment);
           }
       }

    if(orderSendType == oLimit)
       {
        datetime _orderExpiration = TimeTradeServer() + limitOrderExecutionSeconds / 60;

        if(buySignal)
           {
            double _price =  SymbolInfo.NormalizePrice(SymbolInfo.Bid() + limitOrderSpread);
            string _comment = "Limit Buy" ;
            return Trade.BuyLimit(_positionVolume, _price, _Symbol, 0, 0, ORDER_TIME_SPECIFIED, _orderExpiration, _comment);
           }
        if(sellSignal)
           {
            double _price = SymbolInfo.NormalizePrice(SymbolInfo.Ask() - limitOrderSpread);
            string _comment = "Limit Sell" ;
            return Trade.SellLimit(_positionVolume, _price, _Symbol, 0, 0, ORDER_TIME_SPECIFIED, _orderExpiration, _comment);
           }
       }

    return false;
   }

//+------------------------------------------------------------------+
//|  Process bars and return Buy and Sell signals                                                                |
//+------------------------------------------------------------------+
void getBuySellSignal(bool &outBuySignal, bool &outSellSignal)
   {
    outBuySignal = false;
    outSellSignal = false;

//-- should try buy/sell only once by candle
    if(lastProcessedBar.time == SelectedRates[0].time)
        return;

    MqlRates actionBar;
    static MqlRates referenceBar;

    if(operationMode == Close && IsNewCandle)
       {
        actionBar = SelectedRates[1];
        if(operationDisruption == Previous)
            referenceBar = SelectedRates[2];
        else
            if(operationDisruption == Reference && referenceBar.time == NULL)
                referenceBar = SelectedRates[0];
       }
    else
        if(operationMode == Open)
           {
            actionBar = SelectedRates[0];
            if(operationDisruption == Previous)
                referenceBar = SelectedRates[1];
            else
                if(operationDisruption == Reference && referenceBar.time == NULL)
                    referenceBar = SelectedRates[0];
           }


    if(referenceBar.time == actionBar.time)
        return;

//-- If reference candle is smaller than DY will remove buy and sell signals
    if(input_filterDxDyMode == fDY
       && MathAbs(referenceBar.high - referenceBar.low) < DY)
        return;

//-- Stock Variation
    if(stockVariation != NULL && stockVariation > 0)
       {
        double dayOpenRate = getOpenDayRate();
        double variationHigh = 100 * (referenceBar.high - dayOpenRate) / dayOpenRate;
        double variationLow  = 100 * (dayOpenRate - referenceBar.low) / referenceBar.low;
        if((variationHigh > 0 && variationHigh > stockVariation)
           && (variationLow  > 0 && variationLow  > stockVariation))
           {
            outBuySignal = false;
            outSellSignal = false;
            return;
           }
       }

//-- FollowingTrend
    outBuySignal = (referenceBar.high + DX) < actionBar.high;
    if(!outBuySignal)
        outSellSignal = (referenceBar.low - DX) > actionBar.low;

//-- AgainstTrend
    if(operationDirection == AgainstTrend)
       {
        bool aux = outBuySignal;
        outBuySignal = outSellSignal;
        outSellSignal = aux;
       }

    if(OperationDirection == odBuy)
        outSellSignal = false;

    if(OperationDirection == odSell)
        outBuySignal = false;
   }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NomalizeSymbolVolume(double dblLots)
   {
    double
    dblLotsMinimum = SymbolInfo.LotsMin(),
    dblLotsMaximum = SymbolInfo.LotsMax(),
    dblLotsStep    = SymbolInfo.LotsStep();

// Adjust Volume for allowable conditions
    double   dblLotsNext = fmin(dblLotsMaximum,                          // Prevent too greater volume
                                fmax(dblLotsMinimum,                     // Prevent too smaller volume
                                     round(dblLots) * dblLotsStep));     // Align to Step value

    return (dblLotsNext);
   }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getOpenDayRate()
   {
    MqlRates rate[];
    CopyRates(Symbol(), PERIOD_D1, 0, 1, rate);
    return (rate[0].open);
   }

//+------------------------------------------------------------------+
//|  Custom Fuctions                                                  |
//+------------------------------------------------------------------+
bool isNewCandle()
   {
    static datetime last_time = 0;
    datetime lastbar_time = (datetime)SeriesInfoInteger(Symbol(), SelectedTimeframe, SERIES_LASTBAR_DATE);
    if(last_time == 0)
       {
        last_time = lastbar_time;
        return(false);
       }
    if(last_time != lastbar_time)
       {
        last_time = lastbar_time;
        return(true);
       }
    return(false);
   }
//+------------------------------------------------------------------+
