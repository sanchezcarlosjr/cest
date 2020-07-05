#include "types.h"

#ifndef __STDIO_H
#define __STDIO_H

enum Color {
    STANDARD_WHITE = 0x1F00,
    STANDARD_GREY = 0x0700,
    STANDARD_GREEN = 0x2a00
};

void delay(int seconds) {
    int actual = 0;
    while(actual <= seconds*100000000) {
        actual++;
    }
}

class Cursor {
private:
    uint8_t screenPosition = 80;
    uint8_t x=0,y=0;
public:
    void setAction(bool isLineBreakCharacter) {
        if (isLineBreakCharacter || this->x >= 80) {
            this->lineBreak();
        } else {
            this->moveCursor();
        }
    }
    int getCursor() {
        return 80*this->y+this->x;
    }
    void lineBreak() {
        this->x = 0;
        this->y++;
    }
    void moveCursor(int step = 1) {
        this->x = this->x + step;
    }
};


class Screen {
private:
    uint16_t *videoMemory = (uint16_t *) 0xb8000;
    uint16_t color = (uint16_t) Color::STANDARD_GREEN;
    Cursor cursor;
    char finalTextCharacter = '\0';
    char lineBreakCharacter = '\n';
public:
    void print(char *str) {
        bool isLineBreak = false;
        char character = this->finalTextCharacter;
        for(int i = 0; str[i] != this->finalTextCharacter; ++i)
        {
            this->print(str[i]);
        }
    }
    void print(char str) {
        bool isLineBreak = false;
        char character = this->finalTextCharacter;
        isLineBreak = str == this->lineBreakCharacter;
        this->cursor.setAction(isLineBreak);
        character = (isLineBreak) ? this->finalTextCharacter : str;
        this->videoMemory[this->cursor.getCursor()] = (this->videoMemory[this->cursor.getCursor()] & this->color) | character;
    }
};

void print(char *str) {
   Screen screen;
   screen.print(str);
}

#endif