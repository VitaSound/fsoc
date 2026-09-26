\ fsoc/core.4th — builder core without tasks. Paths are relative to this file.
\ Only fjson/util.4th and fjson/emit.4th are used: fjson.4th brings
\ struct.fs, which does not coexist with begin-structure in one image.

s" ../forth-packages/fenum/0.1.1/fenum-bs.4th" included
s" ../forth-packages/fjson/0.2.5/fjson/util.4th" included
s" ../forth-packages/fjson/0.2.5/fjson/emit.4th" included

s" utils.4th" included
s" paths.4th" included
s" sh.4th" included
s" log.4th" included
s" project.4th" included
s" registry.4th" included
s" hdl.4th" included
s" platform.4th" included
s" ../targets/emulation.4th" included
s" ../targets/quartus.4th" included
s" ../targets/yosys.4th" included
s" soc/iomap.4th" included
s" build.4th" included
