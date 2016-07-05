// $Id: BlinkToRadio.h,v 1.4 2006-12-12 18:22:52 vlahan Exp $

#ifndef BLINKTORADIO_H
#define BLINKTORADIO_H

enum {
  AM_BLINKTORADIO = 6,
  TIMER_PERIOD_MILLI = 500,
  LIGHT_THRESHOLD = 600,
};

typedef nx_struct BlinkToRadioMsg {
  nx_uint16_t srcid;
  nx_uint16_t dstid;
  nx_uint16_t packetid;
  nx_uint16_t sensorvalue;
} BlinkToRadioMsg;

#endif
