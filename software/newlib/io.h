#pragma once
#define UART_TX 0xa00003f8
#define UART_RX 0xa00003f8
#include<stdint.h>

static inline uint8_t  load1(uint32_t addr) { return *(volatile uint8_t  *)addr; }
static inline uint16_t load2(uint32_t addr) { return *(volatile uint16_t *)addr; }
static inline uint32_t load4(uint32_t addr) { return *(volatile uint32_t *)addr; }

static inline void store1(uint32_t addr, uint8_t  data) { *(volatile uint8_t  *)addr = data; }
static inline void store2(uint32_t addr, uint16_t data) { *(volatile uint16_t *)addr = data; }
static inline void store4(uint32_t addr, uint32_t data) { *(volatile uint32_t *)addr = data; }
