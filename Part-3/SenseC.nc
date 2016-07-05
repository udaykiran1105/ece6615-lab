/*
 * Copyright (c) 2006, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2006-12-12 18:22:49 $
 * @author: Jan Hauer
 * ========================================================================
 */

/**
 * 
 * Sensing demo application. See README.txt file in this directory for usage
 * instructions and have a look at tinyos-2.x/doc/html/tutorial/lesson5.html
 * for a general tutorial on sensing in TinyOS.
 *
 * @author Jan Hauer
 */

#include <stdio.h>
#include "Timer.h"

module SenseC
{
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli>;
    interface Read<uint16_t>;
    interface Mts300Sounder;
    interface Packet;
    interface AMPacket;
    interface AMSend;
    interface Receive;
    interface SplitControl as AMControl;

  }
}

implementation
{

  // sampling frequency in binary milliseconds
  uint16_t counter;
  uint16_t LedSet=0;
  message_t pkt;
  bool busy = FALSE;
  // uint16_t pkts_proc[1000];    // Process a max of 1000 packets 
  
  event void Boot.booted() {
    call AMControl.start();
  }


 // Start the radio. If successful, start the timer, else try to restart the timer
  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call Timer.startPeriodic(TIMER_PERIOD_MILLI);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  } 
 
  // Decide the read the value when the time fires every TIMER_PERIOD_MILLI seconds
  event void Timer.fired() 
  {
    call Read.read();
  }

  // Decide to tx packet at end of sensing interval only if it is node 4
  event void Read.readDone(error_t result, uint16_t data) 
  {
    if (TOS_NODE_ID == 4 && result == SUCCESS && data < LIGHT_THRESHOLD){
          counter++;
            if (!busy) {
                        BlinkToRadioMsg* btrpkt = 
	                     (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));
                
                        //if (btrpkt == NULL) { return; }

                     btrpkt->sensorvalue = data;                     //assigning read value to packet 
                     btrpkt->dstid = TOS_NODE_ID - 1;                //specify destination as 3
                     btrpkt->srcid = TOS_NODE_ID;                    //transmit packet 
                     btrpkt->packetid = counter;
  
                     // btrpkt->nodeid = TOS_NODE_ID;

                      // btrpkt->pkt_id = counter;

                      if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
                        busy = TRUE;
                      }
                    }
        
      } 
  }


 // Set the busy flag to false when the node is finished tx-ing the pkt 
  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) {
      busy = FALSE;
    }
  }

 // Decide what to do when a packet is received
 event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    if (len == sizeof(BlinkToRadioMsg)) {
       BlinkToRadioMsg* pkt_tx = (BlinkToRadioMsg*)(call Packet.getPayload  
                                (&pkt,  sizeof (BlinkToRadioMsg)));    
      BlinkToRadioMsg* pkt_rx = (BlinkToRadioMsg*)payload;  
       
      if (!busy) {   
          if(TOS_NODE_ID == 1 ){
            call Mts300Sounder.beep(250);
            LedSet=pkt_rx->packetid;
            call Leds.set(LedSet);
            // rem_msg(btrpkt->pkt_id);
          } 
          else {       
            LedSet=pkt_rx->packetid;            
            call Leds.set(LedSet);
            
            pkt_tx->packetid = pkt_rx->packetid;          //forward packet id 
            pkt_tx->sensorvalue = pkt_rx->sensorvalue;    //forward sensor value

            pkt_tx->srcid = TOS_NODE_ID;                  //assign source ID as our node id
            pkt_tx->dstid = TOS_NODE_ID - 1;              //assign dest ID as next node id

            //data1=pkt_rx->sensorvalue;
             
           //start transmitting
            if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
              busy = TRUE;
            }
        }
        } //  Busy flag scope

    }
   return msg;
  }






}
