all: kbcolor kbcolordaemon

kbcolor: kbcolor.c
	gcc -o kbcolor kbcolor.c -lhidapi-hidraw -lm

kbcolordaemon: kbcolordaemon.c
	gcc -o kbcolordaemon kbcolordaemon.c

clean:
	rm -f kbcolor
	rm -f kbcolordaemon

.PHONY: clean all
