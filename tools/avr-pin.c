/* simavr watcher: PB0 must rise and then fall.
   PB1: a software 8N1 byte "b" (runs of 2,1,3,2,1 bits). */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "sim_avr.h"
#include "sim_hex.h"
#include "avr_ioport.h"

#define EDGE_MAX 160

static int last_bit;
static int saw_hi;
static int saw_lo;
static int saw_b;
static avr_t *gavr;

static uint64_t edge_cyc[EDGE_MAX];
static int edge_lvl[EDGE_MAX];
static int nedges;

static void on_pin(struct avr_irq_t *irq, uint32_t value, void *param)
{
	int bit = (int)(value & 1);
	(void)irq;
	(void)param;
	if (bit == last_bit)
		return;
	last_bit = bit;
	if (bit)
		saw_hi = 1;
	else 	if (saw_hi)
		saw_lo = 1;
}

/* 'b' = 0x62, LSB first: low 2 bits, high 1, low 3, high 2, low 1. */
static int near_run(uint64_t got, uint64_t want)
{
	uint64_t d = got > want ? got - want : want - got;
	return want > 80 && d * 3 <= want;
}

static void note_pb1(struct avr_irq_t *irq, uint32_t value, void *param)
{
	int bit = (int)(value & 1);
	int i;
	(void)irq;
	(void)param;
	if (nedges < EDGE_MAX) {
		edge_cyc[nedges] = gavr->cycle;
		edge_lvl[nedges] = bit;
		nedges++;
	}
	if (saw_b)
		return;
	for (i = 1; i + 5 < nedges; i++) {
		uint64_t bitlen;
		if (edge_lvl[i] != 0 || edge_lvl[i - 1] != 1)
			continue;
		bitlen = (edge_cyc[i + 1] - edge_cyc[i]) / 2;
		if (!near_run(edge_cyc[i + 2] - edge_cyc[i + 1], bitlen))
			continue;
		if (!near_run(edge_cyc[i + 3] - edge_cyc[i + 2], bitlen * 3))
			continue;
		if (!near_run(edge_cyc[i + 4] - edge_cyc[i + 3], bitlen * 2))
			continue;
		if (!near_run(edge_cyc[i + 5] - edge_cyc[i + 4], bitlen))
			continue;
		saw_b = 1;
		return;
	}
}

int main(int argc, char **argv)
{
	const char *mcu;
	const char *hex;
	uint32_t dsize = 0, start = 0;
	uint8_t *bin;
	avr_t *avr;
	avr_irq_t *pin;
	avr_irq_t *tx;
	long i;

	if (argc != 3) {
		fprintf(stderr, "usage: avr-pin <mcu> <hex>\n");
		return 1;
	}
	mcu = argv[1];
	hex = argv[2];
	bin = read_ihex_file(hex, &dsize, &start);
	if (!bin) {
		fprintf(stderr, "avr-pin: cannot read %s\n", hex);
		return 1;
	}
	avr = avr_make_mcu_by_name(mcu);
	if (!avr) {
		fprintf(stderr, "avr-pin: no core %s\n", mcu);
		free(bin);
		return 1;
	}
	avr_init(avr);
	gavr = avr;
	avr->frequency = 8000000;
	avr_loadcode(avr, bin, dsize, start);
	free(bin);

	pin = avr_io_getirq(avr, AVR_IOCTL_IOPORT_GETIRQ('B'), IOPORT_IRQ_PIN0);
	if (!pin) {
		fprintf(stderr, "avr-pin: no PORTB pin 0 on %s\n", mcu);
		return 1;
	}
	avr_irq_register_notify(pin, on_pin, NULL);
	tx = avr_io_getirq(avr, AVR_IOCTL_IOPORT_GETIRQ('B'), IOPORT_IRQ_PIN1);
	if (tx)
		avr_irq_register_notify(tx, note_pb1, NULL);

	for (i = 0; i < 40000000L; i++) {
		int s = avr_run(avr);
		if (s == cpu_Crashed || s == cpu_Done) {
			fprintf(stderr, "avr-pin: %s stopped pc=0x%x\n", mcu, avr->pc);
			return 2;
		}
		if (saw_hi && saw_lo) {
			printf("%s PB0 edges\n", mcu);
			if (saw_b)
				printf("%s PB1 b\n", mcu);
			return 0;
		}
	}
	fprintf(stderr, "avr-pin: %s no both edges hi=%d lo=%d\n", mcu, saw_hi, saw_lo);
	return 3;
}
