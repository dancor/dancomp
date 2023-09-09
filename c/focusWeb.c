#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "../../templates/cpp/err.h"
char buf[65536]; int bufI;
inline void bufReadWord(char *wd, int &wdI) {wdI = 0; bufReadWord:
  char c = zre(buf[bufI++]); if (c != ' ') {wd[wdI++] = c; goto bufReadWord;}
  wd[wdI++] = 0;}
inline void bufSkipSpaces() {while (zre(buf[bufI]) == ' ') bufI++;}
inline void bufSkipWord() {while (zre(buf[bufI++]) != ' ') {}}
int main() {int w, h, maxArea = 0, wdI;
  char wd[65536], id[65536], bestId[65536], *buf2;
  FILE* p = zre(popen("wmctrl -lG", "r"));
  while (fgets(buf, sizeof buf, p)) {
    bufI = 0; //printf("buf:%s", buf);
    bufReadWord(id, wdI);
    bufSkipSpaces(); bufSkipWord();
    bufSkipSpaces(); bufSkipWord();
    bufSkipSpaces(); bufSkipWord();
    bufSkipSpaces(); bufReadWord(wd, wdI); w = atoi(wd);
    bufSkipSpaces(); bufReadWord(wd, wdI); h = atoi(wd);
    bufSkipSpaces(); bufSkipWord();
    buf2 = buf + bufI;
    bufSkipSpaces();
    if (strcmp(" - Google Chrome\n", buf2 + strlen(buf2) - 17)) continue;
    if (w * h <= maxArea) continue;
    maxArea = w * h;
    strcpy(bestId, id);
  } //pclose(p);
  return execl("/bin/wmctrl", "wmctrl", "-ia", bestId, NULL);
}
