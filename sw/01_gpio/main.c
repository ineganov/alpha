
#include "gpio.h"

#define DELAY 10
//#define DELAY 5000000

void main (void) {

    MMIO_GPIO_W1 = 0x76543210;

    while(1) {
        MMIO_GPIO_W0 = 1;
        for(int i=0; i<DELAY; i++);
        MMIO_GPIO_W0 = 0;
        for(int i=0; i<DELAY; i++);
    }
}
