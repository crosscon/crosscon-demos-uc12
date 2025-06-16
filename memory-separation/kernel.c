#include "io.h"

static char buf[256] = "Hello world!\n";

void main()
{
    uart_init();
    uart_writeText(buf);

    while (1) {
        uart_writeText("Enter text: ");
        uart_readLine(buf, sizeof(buf));
        uart_writeText("Got: ");
        uart_writeText(buf);
        uart_writeText("\n");
    }
}
