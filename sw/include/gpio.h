
#include <stdint.h>

#ifndef MMIO_GPIO_H
#define MMIO_GPIO_H

#define MMIO_GPIO_BASE      0x80001000

#define MMIO_GPIO_R0_ADDR   (MMIO_GPIO_BASE + 0x0)
#define MMIO_GPIO_R1_ADDR   (MMIO_GPIO_BASE + 0x4)
#define MMIO_GPIO_W0_ADDR   (MMIO_GPIO_BASE + 0x8)
#define MMIO_GPIO_W1_ADDR   (MMIO_GPIO_BASE + 0xC)

#define MMIO_GPIO_R0        (* (volatile uint32_t *) MMIO_GPIO_R0_ADDR )
#define MMIO_GPIO_R1        (* (volatile uint32_t *) MMIO_GPIO_R1_ADDR )
#define MMIO_GPIO_W0        (* (volatile uint32_t *) MMIO_GPIO_W0_ADDR )
#define MMIO_GPIO_W1        (* (volatile uint32_t *) MMIO_GPIO_W1_ADDR )

#endif
