\ tests/midi_foot_test.4th — host FOOTSWITCH-SCAN MIDI bytes

s" test_common.4th" included
s" ../firmware/midi_foot.4th" included

midi-foot-init
0 btn-press
FOOTSWITCH-SCAN
midi-log-n @ 3 expect=
midi-log c@ $90 expect=
midi-log 1+ c@ $3C expect=
midi-log 2 + c@ $7F expect=

midi-log-reset
0 btn-release
FOOTSWITCH-SCAN
midi-log-n @ 3 expect=
midi-log c@ $80 expect=
midi-log 1+ c@ $3C expect=
midi-log 2 + c@ $00 expect=

cr ." midi_foot_test ok" cr
