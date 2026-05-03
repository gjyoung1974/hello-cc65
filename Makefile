CC     = cl65
CFLAGS = -t none -C apple1.cfg -O
LOAD   = 0x0800

TARGET = hello.bin
CSRC   = hello.c
ASM    = pia.s

$(TARGET): $(CSRC) $(ASM) apple1.cfg
	$(CC) $(CFLAGS) -o $@ $(ASM) $(CSRC)

# Produce Woz-monitor upload hex — paste into the Apple 1 terminal, then type 800R
monitor: $(TARGET)
	python3 -c "d=open('$(TARGET)','rb').read();[print('{:04X}:'.format($(LOAD)+i),*['{:02X}'.format(b) for b in d[i:i+8]]) for i in range(0,len(d),8)]"

clean:
	rm -f $(TARGET) *.o *.map

.PHONY: monitor clean
