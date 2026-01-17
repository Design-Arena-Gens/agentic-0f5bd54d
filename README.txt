SENTINEL XAU - MetaTrader 5 Expert Advisor for Gold Trading
===========================================================

OVERVIEW:
---------
Sentinel XAU is a professional-grade Expert Advisor designed specifically for trading Gold (XAUUSD)
on MetaTrader 5. It uses a multi-indicator trend-following strategy optimized for Gold's volatility
and price behavior.

STRATEGY:
---------
The EA combines multiple technical indicators for robust trade signals:

1. EMA Crossover System (9/21 periods)
   - Fast and slow EMAs to identify trend changes
   - Crossover signals initiate potential trades

2. Signal SMA (50 period)
   - Confirms overall market direction
   - Acts as a trend filter

3. RSI (14 period)
   - Momentum confirmation
   - Filters out overbought/oversold conditions
   - Prevents counter-trend entries

4. ATR-Based Dynamic Stop Loss/Take Profit
   - Adapts to market volatility
   - 1.5x ATR for SL, 3x ATR for TP
   - Alternative: Fixed 300/600 point SL/TP

FEATURES:
---------
✓ Automatic lot sizing based on account risk percentage
✓ Trailing stop functionality to lock in profits
✓ Daily loss limit protection
✓ Spread filter to avoid poor execution
✓ Time-of-day trading filter
✓ Basic news avoidance
✓ Maximum position limit
✓ Risk management per trade

INSTALLATION:
-------------
1. Copy SentinelXAU.mq5 to your MetaTrader 5 data folder:
   File -> Open Data Folder -> MQL5 -> Experts

2. Restart MetaTrader 5 or compile the EA:
   - Open MetaEditor (F4)
   - Open SentinelXAU.mq5
   - Click Compile (F7)

3. Attach to XAUUSD chart:
   - Open XAUUSD chart (any timeframe, M15 or H1 recommended)
   - Drag SentinelXAU from Navigator -> Expert Advisors
   - Configure parameters (see below)
   - Enable "AutoTrading" button

RECOMMENDED SETTINGS:
--------------------
For Conservative Trading:
- LotSize: 0.01
- UseAutoLot: true
- RiskPercent: 1.0
- MaxDailyLoss: 3.0
- UseTrailingStop: true

For Aggressive Trading:
- RiskPercent: 2.0
- MaxDailyLoss: 5.0
- MaxPositions: 2

For M15 Timeframe (Scalping):
- FastEMA: 9
- SlowEMA: 21
- StopLoss: 200
- TakeProfit: 400

For H1 Timeframe (Swing):
- FastEMA: 12
- SlowEMA: 26
- StopLoss: 500
- TakeProfit: 1000

PARAMETER GUIDE:
---------------
Trading Parameters:
- LotSize: Fixed lot size if not using auto-sizing
- UseAutoLot: Automatically calculate lot size based on risk
- RiskPercent: Risk per trade as % of account balance (1-2% recommended)
- StopLoss: Stop loss in points (300 = 30 pips for Gold)
- TakeProfit: Take profit in points (600 = 60 pips)
- MaxSpread: Maximum spread allowed for trading (30 points recommended)

Strategy Parameters:
- FastEMA: Fast EMA period (9 recommended)
- SlowEMA: Slow EMA period (21 recommended)
- SignalSMA: Trend filter SMA (50 recommended)
- RSI_Period: RSI calculation period (14 standard)
- ATR_Multiplier: ATR multiplier for dynamic SL/TP (1.5 recommended)

Risk Management:
- MaxDailyLoss: Maximum daily loss % before stopping (3-5% recommended)
- MaxPositions: Maximum simultaneous positions (1 recommended)
- TrailingStart: Points profit before trailing starts (200 points)
- TrailingStep: Distance of trailing stop (50 points)

BACKTESTING:
-----------
1. Open MetaTrader 5 Strategy Tester (Ctrl+R)
2. Select SentinelXAU
3. Symbol: XAUUSD
4. Period: M15 or H1
5. Date range: At least 6 months of recent data
6. Model: Every tick based on real ticks
7. Optimization: Can optimize RSI, EMA, and ATR parameters

IMPORTANT NOTES:
---------------
⚠ Always test on demo account first
⚠ Past performance does not guarantee future results
⚠ Gold is highly volatile - use appropriate risk management
⚠ Ensure broker allows EA trading and has low spreads for XAUUSD
⚠ Monitor during major news events (NFP, FOMC, CPI)
⚠ Recommended minimum account balance: $500 for 0.01 lots

TROUBLESHOOTING:
---------------
- EA not opening trades: Check AutoTrading is enabled, spread is not too wide
- Compilation errors: Ensure you're using MetaTrader 5 (not MT4)
- Unexpected behavior: Check journal logs for error messages
- Poor results: Optimize parameters for your broker's conditions

SUPPORT:
--------
For best results:
- Use ECN/STP broker with low spreads on XAUUSD
- Ensure stable internet connection
- VPS recommended for 24/7 operation
- Monitor performance weekly

VERSION: 1.00
Compatible with: MetaTrader 5 build 3300+
