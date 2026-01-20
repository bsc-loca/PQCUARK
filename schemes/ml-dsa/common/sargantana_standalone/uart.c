// See LICENSE for license details.

#include "uart.h"

void write_reg_u8(uintptr_t addr, uint8_t value)
{
    volatile uint8_t *loc_addr = (volatile uint8_t *)addr;
    *loc_addr = value;
}

uint8_t read_reg_u8(uintptr_t addr)
{
    return *(volatile uint8_t *)addr;
}

int is_transmit_empty()
{
    return read_reg_u8(UART_LINE_STATUS) & 0x20;
}

void uart_init(unsigned long long int freq, unsigned long long int baud) {
    uint32_t divisor = freq / (baud << 4);
/*
    write_reg_u8(UART_INTERRUPT_ENABLE, 0x00); // Disable all interrupts
    write_reg_u8(UART_LINE_CONTROL, 0x80);     // Enable DLAB (set baud rate divisor)
    write_reg_u8(UART_DLAB_LSB, divisor);         // divisor (lo byte)
    write_reg_u8(UART_DLAB_MSB, (divisor >> 8) & 0xFF);  // divisor (hi byte)
    write_reg_u8(UART_LINE_CONTROL, 0x03);     // 8 bits, no parity, one stop bit
    write_reg_u8(UART_MODEM_CONTROL, 0x20);    // Autoflow mode
*/
    write_reg_u8(UART_LINE_CONTROL, 0x80);     // Enable DLAB (set baud rate divisor)
    write_reg_u8(UART_DLAB_LSB, divisor);         // divisor (lo byte)
    write_reg_u8(UART_DLAB_MSB, (divisor >> 8) & 0xFF);  // divisor (hi byte)
    write_reg_u8(UART_LINE_CONTROL, 0x03);     // 8 bits, no parity, one stop bit
    write_reg_u8(UART_INTERRUPT_ENABLE, 0x00); // Disable all interrupts 

}

void uart_send(uint8_t data) {
  // wait until THR empty
    while (is_transmit_empty() == 0) {};
    write_reg_u8(UART_THR, data);
}

void uart_send_string(const char *str) {
  while(*str != 0) {
    while (is_transmit_empty() == 0) {};
    write_reg_u8(UART_THR, *(str++));
  }
}

void uart_send_buf(const char *buf, const int32_t len) {
  int32_t i;
  for(i=0; i<len; i++) {
    while (is_transmit_empty() == 0) {};
    write_reg_u8(UART_THR, *(buf + i));
  }
}

uint8_t uart_recv() {
  // wait until RBR has data
  while (is_transmit_empty() == 0) {};

  return read_reg_u8(UART_RBR);

}

// IRQ triggered read
uint8_t uart_read_irq() {
  return read_reg_u8(UART_RBR);
}

// check uart IRQ for read
uint8_t uart_check_read_irq() {
  return (read_reg_u8(UART_LINE_STATUS) & 0x01u);
}

// enable uart read IRQ
void uart_enable_read_irq() {
  write_reg_u8(UART_INTERRUPT_ENABLE, 0x0001u);
}

// disable uart read IRQ
void uart_disable_read_irq() {
  write_reg_u8(UART_INTERRUPT_ENABLE, 0x0000u);
}
