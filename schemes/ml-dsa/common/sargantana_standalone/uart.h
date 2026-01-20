#ifndef UART_HEADER_H
#define UART_HEADER_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

#define UART_BASE 0x00040000000

#define UART_RBR UART_BASE + 0x1000
#define UART_THR UART_BASE + 0x1000
#define UART_INTERRUPT_ENABLE UART_BASE + 0x1004
#define UART_INTERRUPT_IDENT UART_BASE + 0x1008
#define UART_FIFO_CONTROL UART_BASE + 0x1008
#define UART_LINE_CONTROL UART_BASE + 0x100C
#define UART_MODEM_CONTROL UART_BASE + 0x1010
#define UART_LINE_STATUS UART_BASE + 0x1014
#define UART_MODEM_STATUS UART_BASE + 0x1018
#define UART_DLAB_LSB UART_BASE + 0x1000
#define UART_DLAB_MSB UART_BASE + 0x1004

// UART APIs
extern void uart_init(unsigned long long int freq, unsigned long long int baud);
extern void uart_send(uint8_t);
extern void uart_send_string(const char *str);
extern void uart_send_buf(const char *buf, const int32_t len);
extern uint8_t uart_recv();
extern uint8_t uart_read_irq();
extern uint8_t uart_check_read_irq();
extern void uart_enable_read_irq();
extern void uart_disable_read_irq();

#ifdef __cplusplus
}
#endif

#endif
