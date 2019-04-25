
#include <stdint.h>

#ifndef MMIO_UART_16550_H
#define MMIO_UART_16550_H

#define MMIO_UART_BASE           0x80002000

#define MMIO_UART_TXR_ADDR       (MMIO_UART_BASE + 0)  /*  Transmit register (WRITE) */
#define MMIO_UART_RXR_ADDR       (MMIO_UART_BASE + 0)  /*  Receive register  (READ)  */
#define MMIO_UART_IER_ADDR       (MMIO_UART_BASE + 1)  /*  Interrupt Enable          */
#define MMIO_UART_IIR_ADDR       (MMIO_UART_BASE + 2)  /*  Interrupt ID              */
#define MMIO_UART_FCR_ADDR       (MMIO_UART_BASE + 2)  /*  FIFO control              */
#define MMIO_UART_LCR_ADDR       (MMIO_UART_BASE + 3)  /*  Line control              */
#define MMIO_UART_MCR_ADDR       (MMIO_UART_BASE + 4)  /*  Modem control             */
#define MMIO_UART_LSR_ADDR       (MMIO_UART_BASE + 5)  /*  Line Status               */
#define MMIO_UART_MSR_ADDR       (MMIO_UART_BASE + 6)  /*  Modem Status              */
#define MMIO_UART_DLL_ADDR       (MMIO_UART_BASE + 0)  /*  Divisor Latch Low         */
#define MMIO_UART_DLH_ADDR       (MMIO_UART_BASE + 1)  /*  Divisor latch High        */

#define MMIO_UART_LCR_LATCH      (1 << 7)        /* LCR Divisor Latch Access bit */
#define MMIO_UART_LCR_8N1        3               /* 8N1 UART mode */
#define MMIO_UART_MCR_DTR        (1 << 0)        /* Data Terminal Ready (DTR) signal control */
#define MMIO_UART_MCR_RTS        (1 << 1)        /* Request To Send (RTS) signal control */
#define MMIO_UART_LSR_DR         (1 << 0)        /* Data Ready (DR) indicator */
#define MMIO_UART_LSR_TFE        (1 << 5)        /* Transmitter FIFO empty */
#define MMIO_UART_IER_RDA        (1 << 0)        /* Received Data available interrupt enable */
#define MMIO_UART_IIR_RDA        (1 << 2)        /* Receiver Data available interrupt */
#define MMIO_UART_FCR_CLR        (1 << 1)        /* Clear Receiver FIFO */
#define MMIO_UART_FCR_CLT        (1 << 2)        /* Clear Transmitter FIFO */
#define MMIO_UART_FCR_ITL1       (0 << 6)        /* Receiver FIFO Interrupt trigger level - 1 byte */
#define MMIO_UART_FCR_ITL4       (1 << 6)        /* Receiver FIFO Interrupt trigger level - 4 byte */
#define MMIO_UART_FCR_ITL8       (2 << 6)        /* Receiver FIFO Interrupt trigger level - 8 byte */
#define MMIO_UART_FCR_ITL14      (3 << 6)        /* Receiver FIFO Interrupt trigger level - 14 byte */

#define MMIO_UART_TXR            (* (volatile uint8_t *) MMIO_UART_TXR_ADDR      )
#define MMIO_UART_RXR            (* (volatile uint8_t *) MMIO_UART_RXR_ADDR      )
#define MMIO_UART_IER            (* (volatile uint8_t *) MMIO_UART_IER_ADDR      )
#define MMIO_UART_IIR            (* (volatile uint8_t *) MMIO_UART_IIR_ADDR      )
#define MMIO_UART_LCR            (* (volatile uint8_t *) MMIO_UART_LCR_ADDR      )
#define MMIO_UART_MCR            (* (volatile uint8_t *) MMIO_UART_MCR_ADDR      )
#define MMIO_UART_LSR            (* (volatile uint8_t *) MMIO_UART_LSR_ADDR      )
#define MMIO_UART_MSR            (* (volatile uint8_t *) MMIO_UART_MSR_ADDR      )
#define MMIO_UART_DLL            (* (volatile uint8_t *) MMIO_UART_DLL_ADDR      )
#define MMIO_UART_DLH            (* (volatile uint8_t *) MMIO_UART_DLH_ADDR      )
#define MMIO_UART_FCR            (* (volatile uint8_t *) MMIO_UART_FCR_ADDR      )

#endif
