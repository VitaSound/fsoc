\ Follows theforth.net publishing guidelines:
\   https://theforth.net/guidelines
forth-package
    key-value name fsoc
    key-value version 0.5.0
    key-value license COPL
    key-value description Forth-native SoC builder: boards, toolchains, iomap, J1
    key-value main fsoc.4th
    key-value fmix ~> 0.8
    key-value flint ~> 0.2
    key-value fcov ~> 0.3
    key-list fcov-exclude boards
    key-list fcov-exclude targets
    key-list tags gforth
    key-list tags soc
    key-list tags fpga
    key-list dependencies fenum git https://github.com/VitaSound/fenum tag 0.1.1
    key-list dependencies ttester git https://github.com/VitaSound/ttester tag 1.2.1
    key-list dependencies fjson git https://github.com/VitaSound/fjson tag 0.2.5
end-forth-package
