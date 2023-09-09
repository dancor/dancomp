#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "../../templates/cpp/err.h"
char buf[65536]; int bufI;
inline void bufReadWord(char *wd, int &wdI) {wdI = 0; char c;
  while ((c = zre(buf[bufI++])) != ' ') wd[wdI++] = c;
  wd[wdI++] = 0;}
inline void bufSkipSpaces() {while (zre(buf[bufI]) == ' ') bufI++;}
inline void bufSkipWord() {while (zre(buf[bufI++]) != ' ') {}}
int main(int argc, char *argv[]) {char mode;
  if (argc == 2 && !argv[1][1] && (mode = argv[1][0]) >= 'f' && mode <= 'h')
    {} else zre(0);
  int x, y, w, h, val = 0, wdI;
  char wd[65536], id[65536], bestId[65536], *buf2;
  FILE* p = zre(popen("wmctrl -lG", "r"));
  while (fgets(buf, sizeof buf, p)) {bufI = 0; bufReadWord(id, wdI);
    bufSkipSpaces(); bufSkipWord(); bufSkipSpaces();
    bufReadWord(wd, wdI); x = atoi(wd); bufSkipSpaces();
    bufReadWord(wd, wdI); y = atoi(wd); bufSkipSpaces();
    bufReadWord(wd, wdI); w = atoi(wd); bufSkipSpaces();
    bufReadWord(wd, wdI); h = atoi(wd); bufSkipSpaces(); bufSkipWord();
    bufSkipSpaces(); buf2 = buf + bufI;
    if (strcmp(" - Google Chrome\n", buf2 + strlen(buf2) - 17)) continue;
    if (mode == 'g') {
      if (w * h <= val) continue; val = w * h; strcpy(bestId, id);} else
    if (mode == 'f') {if (x >= val) continue; val = x; strcpy(bestId, id);}
    else             {if (y <= val) continue; val = y; strcpy(bestId, id);}
  return execl("/bin/wmctrl", "wmctrl", "-ia", bestId, NULL);}
