/* simavr UART console for an ATmega8 HEX. CLI simavr does not feed stdin to USART. */
#include <ctype.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "sim_avr.h"
#include "sim_hex.h"
#include "avr_uart.h"

static uint32_t flash_used;
static unsigned txn;

static void on_tx(struct avr_irq_t *irq, uint32_t value, void *param)
{
	(void)irq;
	(void)param;
	txn++;
	int c = (int)(value & 0xff);
	if (isprint(c) || c == '\n' || c == '\r')
		fputc(c, stdout);
	else
		fprintf(stdout, "<%02x>", (unsigned)c);
	fflush(stdout);
}

static void send_byte(avr_t *avr, uint8_t b)
{
	avr_irq_t *irq = avr_io_getirq(avr, AVR_IOCTL_UART_GETIRQ('0'), UART_IRQ_INPUT);
	if (!irq) {
		fprintf(stderr, "avr-con: no uart0 input\n");
		exit(1);
	}
	avr_raise_irq(irq, b);
}

static void send_line(avr_t *avr, const char *s)
{
	for (; *s; s++) {
		if (*s == '\n' || *s == '\r')
			continue;
		send_byte(avr, (uint8_t)*s);
	}
	send_byte(avr, '\r');
}

static int step(avr_t *avr)
{
	int s = avr_run(avr);
	if (s == cpu_Crashed) {
		fprintf(stderr, "\navr-con: crash pc_bytes=0x%04x pc_words=0x%04x\n",
			avr->pc, avr->pc >> 1);
		return 2;
	}
	if (flash_used && (avr->pc >> 1) >= (flash_used / 2)) {
		fprintf(stderr, "\navr-con: PC past image pc_bytes=0x%04x used %u\n",
			avr->pc, flash_used);
		return 3;
	}
	return 0;
}

static int drain_quiet(avr_t *avr, long max)
{
	unsigned last = txn;
	long quiet = 0;
	long i;
	for (i = 0; i < max; i++) {
		int e = step(avr);
		if (e)
			return e;
		if (txn != last) {
			last = txn;
			quiet = 0;
		} else if (++quiet > 300000)
			return 0;
	}
	return 0;
}

int main(int argc, char **argv)
{
	const char *hex = argc > 1 ? argv[1] : "firmware.hex";
	uint32_t dsize = 0, start = 0;
	uint8_t *bin = read_ihex_file(hex, &dsize, &start);
	if (!bin) {
		fprintf(stderr, "avr-con: cannot read %s\n", hex);
		return 1;
	}
	flash_used = dsize;
	fprintf(stderr, "avr-con: %s (%u bytes) atmega8 8 MHz 9600\n", hex, dsize);

	avr_t *avr = avr_make_mcu_by_name("atmega8");
	if (!avr) {
		fprintf(stderr, "avr-con: no atmega8 core\n");
		return 1;
	}
	avr_init(avr);
	avr->frequency = 8000000;
	avr_loadcode(avr, bin, dsize, start);
	free(bin);

	uint32_t flags = 0;
	avr_ioctl(avr, AVR_IOCTL_UART_GET_FLAGS('0'), &flags);
	flags &= ~AVR_UART_FLAG_STDIO;
	flags &= ~AVR_UART_FLAG_POLL_SLEEP;
	avr_ioctl(avr, AVR_IOCTL_UART_SET_FLAGS('0'), &flags);

	avr_irq_t *out = avr_io_getirq(avr, AVR_IOCTL_UART_GETIRQ('0'), UART_IRQ_OUTPUT);
	if (!out) {
		fprintf(stderr, "avr-con: no uart0 output\n");
		return 1;
	}
	avr_irq_register_notify(out, on_tx, NULL);

	if (drain_quiet(avr, 8000000))
		return 2;

	if (argc > 2 && strcmp(argv[2], "-f") == 0) {
		FILE *in;
		char buf[256];
		if (argc < 4) {
			fprintf(stderr, "avr-con: -f needs a path\n");
			return 1;
		}
		in = fopen(argv[3], "rb");
		if (!in) {
			perror(argv[3]);
			return 1;
		}
		while (fgets(buf, sizeof buf, in)) {
			send_line(avr, buf);
			if (drain_quiet(avr, 200000000L)) {
				fclose(in);
				return 2;
			}
		}
		fclose(in);
		fputc('\n', stdout);
		return 0;
	}

	if (argc > 2) {
		int a;
		for (a = 2; a < argc; a++) {
			send_line(avr, argv[a]);
			if (drain_quiet(avr, 200000000L))
				return 2;
		}
		fputc('\n', stdout);
		return 0;
	}

	if (fcntl(0, F_SETFL, O_NONBLOCK) < 0) {
		perror("avr-con: fcntl");
		return 1;
	}
	fprintf(stderr, "avr-con: type Forth, Enter sends CR. Ctrl-D to exit.\n");
	for (;;) {
		if (step(avr))
			return 2;
		char c;
		ssize_t n = read(0, &c, 1);
		if (n == 0)
			break;
		if (n < 0)
			continue;
		if (c == '\n')
			c = '\r';
		send_byte(avr, (uint8_t)c);
	}
	return 0;
}
