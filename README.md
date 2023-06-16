# metatrader
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

The MQL5 Expert Advisor MA_Channel_Stochastic_01.mq5 issues an alert just once per signal
(coded to play MT5's alert.wav 20 times with 2-second pauses between each chime - this should
be enough to wake a person up if they're sleeping within earshot of their computer; if not,
the delay and number of repeats are coded as parameters the trader can set to desired values),
rather than chiming incessantly as long as the signal is seen.
