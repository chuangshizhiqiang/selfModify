#include <stdio.h>
#include <stdlib.h>
#include "config.h"

extern int selfModify();
char cBuf[64] = { 0 };

int main(int argc, char* argv[]) {
    int iRet = 0;
    int iCount = 0;

    for (int iCycles = 0; iCycles < 100000000; iCycles ++) {
    
        iRet = selfModify();
        if (iRet) {
            DBGPRINT("Cycles:%d\r\n", iCycles);
            iCount++;
        } 
    }
    printf("Successful times: %d/100000000\r\n", iCount);
    return 0;
}
