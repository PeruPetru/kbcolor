kbcolor: kbcolor.c
	gcc -o kbcolor kbcolor.c -lhidapi-hidraw -lm

clean:
	rm -f kbcolor

.PHONY: clean
