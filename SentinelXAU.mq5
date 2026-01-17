//+------------------------------------------------------------------+
//|                                                  SentinelXAU.mq5 |
//|                                       Advanced Gold Trading EA   |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Sentinel XAU"
#property version   "1.00"
#property strict

// Input Parameters
input group "=== Trading Parameters ==="
input double LotSize = 0.01;                    // Lot size
input bool UseAutoLot = true;                   // Use automatic lot sizing
input double RiskPercent = 1.0;                 // Risk per trade (%)
input int StopLoss = 300;                       // Stop Loss in points
input int TakeProfit = 600;                     // Take Profit in points
input int MaxSpread = 30;                       // Maximum allowed spread

input group "=== Strategy Parameters ==="
input int FastEMA = 9;                          // Fast EMA period
input int SlowEMA = 21;                         // Slow EMA period
input int SignalSMA = 50;                       // Signal SMA period
input int RSI_Period = 14;                      // RSI period
input int RSI_Overbought = 70;                  // RSI overbought level
input int RSI_Oversold = 30;                    // RSI oversold level
input int ATR_Period = 14;                      // ATR period for volatility
input double ATR_Multiplier = 1.5;              // ATR multiplier for dynamic SL/TP

input group "=== Time Filter ==="
input bool UseTimeFilter = true;                // Enable time filter
input int StartHour = 1;                        // Trading start hour (GMT)
input int EndHour = 22;                         // Trading end hour (GMT)

input group "=== Risk Management ==="
input double MaxDailyLoss = 5.0;                // Max daily loss (%)
input int MaxPositions = 1;                     // Maximum open positions
input bool UseTrailingStop = true;              // Use trailing stop
input int TrailingStart = 200;                  // Trailing start in points
input int TrailingStep = 50;                    // Trailing step in points

input group "=== News Filter ==="
input bool AvoidNews = true;                    // Avoid trading during news
input int NewsMinutesBefore = 30;               // Minutes before news
input int NewsMinutesAfter = 30;                // Minutes after news

// Global Variables
int handleFastEMA, handleSlowEMA, handleSignalSMA, handleRSI, handleATR;
double fastEMA[], slowEMA[], signalSMA[], rsi[], atr[];
datetime lastBarTime = 0;
double dailyStartBalance = 0;
int magicNumber = 234567;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize indicators
    handleFastEMA = iMA(_Symbol, PERIOD_CURRENT, FastEMA, 0, MODE_EMA, PRICE_CLOSE);
    handleSlowEMA = iMA(_Symbol, PERIOD_CURRENT, SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
    handleSignalSMA = iMA(_Symbol, PERIOD_CURRENT, SignalSMA, 0, MODE_SMA, PRICE_CLOSE);
    handleRSI = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
    handleATR = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);

    if(handleFastEMA == INVALID_HANDLE || handleSlowEMA == INVALID_HANDLE ||
       handleSignalSMA == INVALID_HANDLE || handleRSI == INVALID_HANDLE ||
       handleATR == INVALID_HANDLE)
    {
        Print("Error creating indicators");
        return(INIT_FAILED);
    }

    ArraySetAsSeries(fastEMA, true);
    ArraySetAsSeries(slowEMA, true);
    ArraySetAsSeries(signalSMA, true);
    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(atr, true);

    dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);

    Print("Sentinel XAU initialized successfully for ", _Symbol);
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    IndicatorRelease(handleFastEMA);
    IndicatorRelease(handleSlowEMA);
    IndicatorRelease(handleSignalSMA);
    IndicatorRelease(handleRSI);
    IndicatorRelease(handleATR);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check for new bar
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(currentBarTime == lastBarTime)
        return;
    lastBarTime = currentBarTime;

    // Update daily balance tracker
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);
    if(timeStruct.hour == 0 && timeStruct.min == 0)
        dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);

    // Check daily loss limit
    if(CheckDailyLoss())
    {
        Print("Daily loss limit reached. Trading suspended.");
        return;
    }

    // Check spread
    long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    if(spread > MaxSpread)
    {
        Print("Spread too wide: ", spread);
        return;
    }

    // Time filter
    if(UseTimeFilter && !IsTimeToTrade())
        return;

    // News filter
    if(AvoidNews && IsNewsTime())
        return;

    // Copy indicator values
    if(CopyBuffer(handleFastEMA, 0, 0, 3, fastEMA) <= 0 ||
       CopyBuffer(handleSlowEMA, 0, 0, 3, slowEMA) <= 0 ||
       CopyBuffer(handleSignalSMA, 0, 0, 3, signalSMA) <= 0 ||
       CopyBuffer(handleRSI, 0, 0, 3, rsi) <= 0 ||
       CopyBuffer(handleATR, 0, 0, 3, atr) <= 0)
        return;

    // Update trailing stops
    if(UseTrailingStop)
        TrailingStop();

    // Check if we can open new position
    if(PositionsTotal() >= MaxPositions)
        return;

    // Trading logic
    int signal = GetTradeSignal();

    if(signal == 1)
        OpenBuy();
    else if(signal == -1)
        OpenSell();
}

//+------------------------------------------------------------------+
//| Get trade signal based on strategy                               |
//+------------------------------------------------------------------+
int GetTradeSignal()
{
    // Multi-indicator strategy for Gold
    // 1. EMA crossover for trend
    // 2. RSI for momentum confirmation
    // 3. Price above/below signal SMA for overall trend

    bool emaBullish = fastEMA[0] > slowEMA[0] && fastEMA[1] <= slowEMA[1];
    bool emaBearish = fastEMA[0] < slowEMA[0] && fastEMA[1] >= slowEMA[1];

    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    bool priceAboveSMA = currentPrice > signalSMA[0];
    bool priceBelowSMA = currentPrice < signalSMA[0];

    bool rsiNotOverbought = rsi[0] < RSI_Overbought;
    bool rsiNotOversold = rsi[0] > RSI_Oversold;
    bool rsiRising = rsi[0] > rsi[1];
    bool rsiFalling = rsi[0] < rsi[1];

    // Trend strength filter
    bool strongUptrend = fastEMA[0] > slowEMA[0] && slowEMA[0] > signalSMA[0];
    bool strongDowntrend = fastEMA[0] < slowEMA[0] && slowEMA[0] < signalSMA[0];

    // Buy signal
    if(emaBullish && priceAboveSMA && rsiNotOverbought && rsiRising && strongUptrend)
        return 1;

    // Sell signal
    if(emaBearish && priceBelowSMA && rsiNotOversold && rsiFalling && strongDowntrend)
        return -1;

    return 0;
}

//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

    double sl, tp;

    if(ATR_Multiplier > 0 && atr[0] > 0)
    {
        sl = ask - (atr[0] * ATR_Multiplier);
        tp = ask + (atr[0] * ATR_Multiplier * 2);
    }
    else
    {
        sl = ask - (StopLoss * point);
        tp = ask + (TakeProfit * point);
    }

    double lots = CalculateLotSize(ask - sl);

    MqlTradeRequest request = {};
    MqlTradeResult result = {};

    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lots;
    request.type = ORDER_TYPE_BUY;
    request.price = ask;
    request.sl = sl;
    request.tp = tp;
    request.deviation = 10;
    request.magic = magicNumber;
    request.comment = "Sentinel XAU Buy";

    if(OrderSend(request, result))
    {
        if(result.retcode == TRADE_RETCODE_DONE)
            Print("Buy order opened successfully. Ticket: ", result.order);
        else
            Print("Buy order failed. RetCode: ", result.retcode);
    }
}

//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell()
{
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

    double sl, tp;

    if(ATR_Multiplier > 0 && atr[0] > 0)
    {
        sl = bid + (atr[0] * ATR_Multiplier);
        tp = bid - (atr[0] * ATR_Multiplier * 2);
    }
    else
    {
        sl = bid + (StopLoss * point);
        tp = bid - (TakeProfit * point);
    }

    double lots = CalculateLotSize(sl - bid);

    MqlTradeRequest request = {};
    MqlTradeResult result = {};

    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lots;
    request.type = ORDER_TYPE_SELL;
    request.price = bid;
    request.sl = sl;
    request.tp = tp;
    request.deviation = 10;
    request.magic = magicNumber;
    request.comment = "Sentinel XAU Sell";

    if(OrderSend(request, result))
    {
        if(result.retcode == TRADE_RETCODE_DONE)
            Print("Sell order opened successfully. Ticket: ", result.order);
        else
            Print("Sell order failed. RetCode: ", result.retcode);
    }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                 |
//+------------------------------------------------------------------+
double CalculateLotSize(double slDistance)
{
    if(!UseAutoLot)
        return LotSize;

    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * (RiskPercent / 100.0);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    double lots = 0.0;
    if(slDistance > 0 && tickSize > 0)
    {
        lots = (riskAmount * tickSize) / (slDistance * tickValue);
        lots = MathFloor(lots / lotStep) * lotStep;
    }

    if(lots < minLot)
        lots = minLot;
    if(lots > maxLot)
        lots = maxLot;

    return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Trailing stop function                                           |
//+------------------------------------------------------------------+
void TrailingStop()
{
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket <= 0)
            continue;

        if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
           PositionGetInteger(POSITION_MAGIC) != magicNumber)
            continue;

        double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentSL = PositionGetDouble(POSITION_SL);
        double currentTP = PositionGetDouble(POSITION_TP);
        long positionType = PositionGetInteger(POSITION_TYPE);

        if(positionType == POSITION_TYPE_BUY)
        {
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double profit = bid - positionOpenPrice;

            if(profit > TrailingStart * point)
            {
                double newSL = bid - (TrailingStep * point);
                if(newSL > currentSL)
                {
                    MqlTradeRequest request = {};
                    MqlTradeResult result = {};

                    request.action = TRADE_ACTION_SLTP;
                    request.symbol = _Symbol;
                    request.position = ticket;
                    request.sl = newSL;
                    request.tp = currentTP;

                    OrderSend(request, result);
                }
            }
        }
        else if(positionType == POSITION_TYPE_SELL)
        {
            double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double profit = positionOpenPrice - ask;

            if(profit > TrailingStart * point)
            {
                double newSL = ask + (TrailingStep * point);
                if(newSL < currentSL || currentSL == 0)
                {
                    MqlTradeRequest request = {};
                    MqlTradeResult result = {};

                    request.action = TRADE_ACTION_SLTP;
                    request.symbol = _Symbol;
                    request.position = ticket;
                    request.sl = newSL;
                    request.tp = currentTP;

                    OrderSend(request, result);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check daily loss limit                                           |
//+------------------------------------------------------------------+
bool CheckDailyLoss()
{
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double loss = dailyStartBalance - currentBalance;
    double lossPercent = (loss / dailyStartBalance) * 100.0;

    return (lossPercent >= MaxDailyLoss);
}

//+------------------------------------------------------------------+
//| Time filter                                                       |
//+------------------------------------------------------------------+
bool IsTimeToTrade()
{
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);

    int currentHour = timeStruct.hour;

    if(StartHour < EndHour)
        return (currentHour >= StartHour && currentHour < EndHour);
    else
        return (currentHour >= StartHour || currentHour < EndHour);
}

//+------------------------------------------------------------------+
//| News filter (basic implementation)                               |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
    // This is a simplified version
    // For full implementation, integrate with an economic calendar
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);

    // Avoid trading during typical high-impact news times for Gold
    // US session open and major economic releases
    int currentHour = timeStruct.hour;
    int currentMin = timeStruct.min;

    // Avoid 8:30 AM EST (13:30 GMT) - typical US news time
    if(currentHour == 13 && currentMin >= 0 && currentMin <= 60)
        return true;

    // Avoid 10:00 AM EST (15:00 GMT) - typical US news time
    if(currentHour == 15 && currentMin >= 0 && currentMin <= 60)
        return true;

    return false;
}
//+------------------------------------------------------------------+
