#include <unistd.h>
#include <time.h>
#include <inttypes.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>
#include <hidapi/hidapi.h>
#include <wchar.h>
#include <stdio.h>

#define buffer_length 33

void setKeyboardColor(uint32_t color){
    uint8_t header[2] = {0xCC, 0x16};
    uint8_t effect = 1;
    uint8_t speed = 1;
    uint8_t brightness = 1;
    uint8_t red = color>>4*4;
    uint8_t green = (color>>2*4) - (red<<2*4);
    uint8_t blue = color - (red<<4*4) - (green<<2*4);

    uint8_t buffer[buffer_length] = {
        header[0], header[1],
        effect,
        speed,
        brightness,
        red, green, blue,
        red, green, blue,
        red, green, blue,
        red, green, blue,
        0x00,
        0, 0
    };
    
    hid_init();
    hid_device* handle = hid_open(0x048D, 0xC963, NULL);
    int res = hid_send_feature_report(handle, buffer, buffer_length);
    hid_close(handle); 
    hid_exit();
}

uint32_t hue2hex(int H) {
    float r = 0, g = 0, b = 0;
    float f = ((float)H / 60.0f);
    int i = (int)f;
    float fmod = f - i;

    switch (i) {
        case 0: r = 1; g = fmod; b = 0; break;
        case 1: r = 1 - fmod; g = 1; b = 0; break;
        case 2: r = 0; g = 1; b = fmod; break;
        case 3: r = 0; g = 1 - fmod; b = 1; break;
        case 4: r = fmod; g = 0; b = 1; break;
        case 5: r = 1; g = 0; b = 1 - fmod; break;
        default: r = 1; g = 0; b = 0; break;
    }

    int R = (int)(r * 255.0f);
    int G = (int)(g * 255.0f);
    int B = (int)(b * 255.0f);

    return (R << 16) | (G << 8) | B;
}

int main(int argc, char *argv[]) {
    if (argc <= 1) return 1;
    
    for (int argn = 1; argn < argc; argn+=1) {
        if (!strcmp(argv[argn], "rave")) {
            clock_t initial_clock = clock();
            int angle = 0;
            if (argc < argn + 1) return 1;
            for (int i = 1; i <= strtol(argv[argn + 1], NULL, 10); i += 1) {
                setKeyboardColor(hue2hex(angle));
                angle = (angle + 1) % 360;
                if (angle == 0) i+=1;
                usleep(277);
            }
            setKeyboardColor(0xaaaaaa);
            argn+=1;
            continue;
        } else if (!strcmp(argv[argn], "hue")) {
            if (argc < argn + 1) return 1;
            setKeyboardColor(hue2hex(strtol(argv[argn + 1], NULL, 10)));
            argn += 1;
        } else {
            setKeyboardColor(strtol(argv[1], NULL, 16));
            return 0;
        }
    }
    return 0; 
}
