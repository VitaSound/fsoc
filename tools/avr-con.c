/* simavr console for an AVR HEX. CLI simavr does not feed stdin to USART.
   -m <mcu> selects the core (default atmega8). -b is 9600 8N1 on PB2/PB1. */
#include <ctype.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "sim_avr.h"
#include "sim_hex.h"
#include "avr_uart.h"
#include "avr_ioport.h"

/* Firmware keyb samples PB2 every 783 cycles. TX edges on PB1 are 786 apart. */
#define RX_BIT 783
#define TX_BIT 786
#define EDGE_MAX 8192

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

static uint64_t edge_cyc[EDGE_MAX];
static uint8_t edge_lvl[EDGE_MAX];
static int nedges;
static int last_tx = -1;
static avr_t *gavr;

static void on_pb1(struct avr_irq_t *irq, uint32_t value, void *param)
{
	int bit = (int)(value & 1);
	(void)irq;
	(void)param;
	if (bit == last_tx)
		return;
	last_tx = bit;
	if (nedges < EDGE_MAX) {
		edge_cyc[nedges] = gavr->cycle;
		edge_lvl[nedges] = (uint8_t)bit;
		nedges++;
	}
}

static void set_rx(avr_t *avr, int high)
{
	avr_ioport_external_t ext;
	avr_irq_t *pin;

	memset(&ext, 0, sizeof ext);
	ext.name = 'B';
	ext.mask = 1u << 2;
	ext.value = high ? (1u << 2) : 0;
	avr_ioctl(avr, AVR_IOCTL_IOPORT_SET_EXTERNAL('B'), &ext);
	pin = avr_io_getirq(avr, AVR_IOCTL_IOPORT_GETIRQ('B'), IOPORT_IRQ_PIN2);
	if (pin)
		avr_raise_irq(pin, high ? 1 : 0);
}

static int bang_cycles(avr_t *avr, int n)
{
	uint64_t end = avr->cycle + (uint64_t)n;
	while (avr->cycle < end) {
		int e = step(avr);
		if (e)
			return e;
	}
	return 0;
}

static int bang_send(avr_t *avr, uint8_t b)
{
	int i;
	set_rx(avr, 0);
	if (bang_cycles(avr, RX_BIT))
		return 2;
	for (i = 0; i < 8; i++) {
		set_rx(avr, (b >> i) & 1);
		if (bang_cycles(avr, RX_BIT))
			return 2;
	}
	set_rx(avr, 1);
	return bang_cycles(avr, RX_BIT);
}

static int level_at(int from, uint64_t cyc)
{
	int lvl = 1;
	int i;
	if (from > 0)
		lvl = edge_lvl[from - 1];
	for (i = from; i < nedges; i++) {
		if (edge_cyc[i] > cyc)
			break;
		lvl = edge_lvl[i];
	}
	return lvl;
}

static int next_fall(int from, uint64_t after, uint64_t *at)
{
	int i;
	int prev = from > 0 ? edge_lvl[from - 1] : 1;
	for (i = from; i < nedges; i++) {
		if (edge_cyc[i] >= after && edge_lvl[i] == 0 && prev == 1) {
			if (i + 1 < nedges &&
			    edge_cyc[i + 1] - edge_cyc[i] < (uint64_t)TX_BIT / 2) {
				prev = edge_lvl[i];
				continue;
			}
			*at = edge_cyc[i];
			return 1;
		}
		prev = edge_lvl[i];
	}
	return 0;
}

static void bang_decode(int from)
{
	uint64_t pos;
	int i;
	if (!next_fall(from, 0, &pos))
		return;
	for (;;) {
		int byte = 0;
		uint64_t nxt;
		for (i = 0; i < 8; i++) {
			uint64_t at = pos + (uint64_t)(3 + 2 * i) * (TX_BIT / 2);
			if (level_at(from, at))
				byte |= 1 << i;
		}
		if (isprint(byte) || byte == '\n' || byte == '\r')
			fputc(byte, stdout);
		else
			fprintf(stdout, "<%02x>", byte & 0xff);
		if (!next_fall(from, pos + (uint64_t)TX_BIT * 9, &nxt))
			break;
		pos = nxt;
	}
	fflush(stdout);
}

static int bang_drain(avr_t *avr, long max)
{
	int last = nedges;
	long quiet = 0;
	long i;
	for (i = 0; i < max; i++) {
		int e = step(avr);
		if (e)
			return e;
		if (nedges != last) {
			last = nedges;
			quiet = 0;
		} else if (++quiet > 300000) {
			bang_decode(0);
			return 0;
		}
	}
	bang_decode(0);
	return 0;
}

static int bang_line(avr_t *avr, const char *s)
{
	for (; *s; s++) {
		if (*s == '\n' || *s == '\r')
			continue;
		if (bang_send(avr, (uint8_t)*s))
			return 2;
	}
	return bang_send(avr, '\r');
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
	const char *mcu = "atmega8";
	int bang = 0;
	int arg = 1;
	const char *hex;
	uint32_t dsize = 0, start = 0;
	uint8_t *bin;
	avr_t *avr;

	while (arg < argc && argv[arg][0] == '-' && strcmp(argv[arg], "-f") != 0) {
		if (strcmp(argv[arg], "-m") == 0 && arg + 1 < argc) {
			mcu = argv[++arg];
			arg++;
			continue;
		}
		if (strcmp(argv[arg], "-b") == 0) {
			bang = 1;
			arg++;
			continue;
		}
		break;
	}
	hex = arg < argc ? argv[arg++] : "firmware.hex";
	bin = read_ihex_file(hex, &dsize, &start);
	if (!bin) {
		fprintf(stderr, "avr-con: cannot read %s\n", hex);
		return 1;
	}
	flash_used = dsize;
	fprintf(stderr, "avr-con: %s (%u bytes) %s 8 MHz 9600\n", hex, dsize, mcu);

	avr = avr_make_mcu_by_name(mcu);
	if (!avr) {
		fprintf(stderr, "avr-con: no %s core\n", mcu);
		free(bin);
		return 1;
	}
	avr_init(avr);
	gavr = avr;
	avr->frequency = 8000000;
	avr_loadcode(avr, bin, dsize, start);
	free(bin);

	if (bang) {
		avr_irq_t *tx = avr_io_getirq(avr, AVR_IOCTL_IOPORT_GETIRQ('B'), IOPORT_IRQ_PIN1);
		if (!tx) {
			fprintf(stderr, "avr-con: no PORTB pin 1 on %s\n", mcu);
			return 1;
		}
		avr_irq_register_notify(tx, on_pb1, NULL);
		set_rx(avr, 1);
		if (bang_cycles(avr, 20000))
			return 2;
		if (arg < argc && strcmp(argv[arg], "-f") == 0) {
			FILE *in;
			char buf[256];
			if (arg + 1 >= argc) {
				fprintf(stderr, "avr-con: -f needs a path\n");
				return 1;
			}
			in = fopen(argv[arg + 1], "rb");
			if (!in) {
				perror(argv[arg + 1]);
				return 1;
			}
			while (fgets(buf, sizeof buf, in)) {
				if (bang_line(avr, buf) || bang_drain(avr, 80000000L)) {
					fclose(in);
					return 2;
				}
			}
			fclose(in);
			fputc('\n', stdout);
			return 0;
		}
		if (arg < argc) {
			for (; arg < argc; arg++) {
				if (bang_line(avr, argv[arg]) || bang_drain(avr, 80000000L))
					return 2;
			}
			fputc('\n', stdout);
			return 0;
		}
		fprintf(stderr, "avr-con: -b needs a line\n");
		return 1;
	}

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

	if (arg < argc && strcmp(argv[arg], "-f") == 0) {
		FILE *in;
		char buf[256];
		if (arg + 1 >= argc) {
			fprintf(stderr, "avr-con: -f needs a path\n");
			return 1;
		}
		in = fopen(argv[arg + 1], "rb");
		if (!in) {
			perror(argv[arg + 1]);
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

	if (arg < argc) {
		for (; arg < argc; arg++) {
			send_line(avr, argv[arg]);
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
