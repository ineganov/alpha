

#include <stdint.h>
#include "uart16550.h"
#include "gpio.h"

#define SIMULATION  0
#define HARDWARE    1

// config start

#define RUNTYPE     SIMULATION

// config end

// The devisor value set should be equal to 
// (system clock speed) / (16 x desired baud rate).
#define DIVISOR_50M     (50*1000*1000 / (16*115200))
#define DIVISOR_SIM     1

#if     RUNTYPE == SIMULATION
    #define UART_DIVISOR    DIVISOR_SIM
#elif   RUNTYPE == HARDWARE
    #define UART_DIVISOR    DIVISOR_50M
#endif

void uartInit(uint16_t divisor)
{
    MMIO_UART_LCR  = MMIO_UART_LCR_8N1;     // 8n1
    MMIO_UART_LCR |= MMIO_UART_LCR_LATCH;   // Divisor Latches access enable
    MMIO_UART_DLL  =  divisor & 0xFF;       // Divisor LSB
    MMIO_UART_DLH  = (divisor >> 8) & 0xff; // Divisor MSB
    MMIO_UART_LCR &= ~MMIO_UART_LCR_LATCH;  // Divisor Latches access disable
}

void uartTransmit(uint8_t data)
{
    // waiting for transmitter fifo empty
    while (!(MMIO_UART_LSR & MMIO_UART_LSR_TFE));

    // transmitted data
    MMIO_UART_TXR = data;
}

void receivedDataOutput(uint8_t data)
{
    MMIO_GPIO_W1 = data;
}

uint8_t uartReceive(void)
{
    //waiting for RX data
    while (!(MMIO_UART_LSR & MMIO_UART_LSR_DR));
    //returning received data
    return MMIO_UART_RXR;
}

void uartWrite(const char str[])
{
    while(*str)
        uartTransmit(*str++);
}

int main ()
{
    // init
    const uint16_t uartDivisor = UART_DIVISOR;
    uartInit(uartDivisor);

    // say Hello after reset
    uartWrite("Hello!");

    // received data output and loopback
    for(;;)
    {
        uint8_t data = uartReceive();
        receivedDataOutput(data);

        #if   RUNTYPE == HARDWARE
        uartTransmit(data);
        #endif
    }
}
