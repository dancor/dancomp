from cmd_util import cmd_output
import os

# base params

w_chars = 80
h_chars = 48

scr_num = 2
scrs = range(scr_num)

#w1, h1 = 1366, 768
w1, h1 = 1280, 768
w2, h2 = 1920, 1080

wc, hc = 8, 13

# derived params

w_scr = [w1, w2]
h_scr = [h1, h2]

w = w_chars * wc
h = h_chars * hc

dw = 2 * w
tw = 3 * w
w_half = [w_scr[i] // 2 for i in scrs]

scr_term_num = [(w_scr[i] + w - 1) // w for i in scrs]
scr_full_term_num = [w_scr[i] // w for i in scrs]

w_thin = [w_scr[i] - (scr_term_num[i] - 1) * w for i in scrs]

top_scr_rows = 4

# rectangle (x, y, w, h)
def rect(pos):
    # vertical splitting
    if pos[0] in ("h", "l", "t"):
        vert = pos[0]
        pos = pos[1:]
    else:
        vert = ""

    scr_n = ord(pos[0]) - ord("a")
    pos = pos[1:]

    if pos and pos[-1] == "s":
        short = True
        pos = pos[:-1]
    else:
        short = False

    width_normal = "n"
    width_half = "h"
    width_most = "m"
    width_full = "f"
    if pos:
        pos0 = pos[0]
        if pos0 in (width_half, width_most):
            width = pos0
            pos = pos[1:]
        else:
            width = width_normal
    else:
        width = width_full

    if pos:
        pos_n = int(pos)
    else:
        pos_n = 0

    if width == width_full:
        r = 0, 0, w_scr[scr_n]
    elif width == width_normal:
        #print pos_n
        if pos_n >= 1 and pos_n < scr_term_num[scr_n]:
            r = w * (pos_n - 1), 0, w
        elif pos_n == scr_term_num[scr_n]:
            r = w * (pos_n - 1), 0, w_thin[scr_n]
        else:
            raise Exception("unknown position")
    elif width == width_half:
        if pos_n == 1:
            r = 0, 0, whalf[scr_n]
        elif pos_n == 2:
            r = whalf[scr_n], 0, whalf[scr_n]
        else:
            raise Exception("unknown position")
    elif width == width_most:
        # prob need to adjust these more dependent on scr info
        if pos_n == 1:
            r = 0, 0, dw
        elif pos_n == 2:
            r = w, 0, w + w_thin[scr_n]
        else:
            raise Exception("unknown position")
    else:
        raise Exception("unknown position")

    rx, ry, rw = r
    rh = h_scr[scr_n]
    if short:
        ry += hc * top_scr_rows
        rh -= hc * top_scr_rows
    if vert == "h":
        rh /= 2
    elif vert == "l":
        rh /= 2
        ry += rh
    elif vert == "t":
        rh = hc * top_scr_rows
        ry = 0
    if scr_n == 1:
        rx += w_scr[0]
    elif scr_n != 0:
        raise Exception("unknown position")
    return rx, ry, rw, rh

# rectangle (x, y, w_chars, h_chars)
def rect_chars(pos):
    x, y, w, h = rect(pos)
    return x, y, w // wc, h // hc

def abbr(p):
    # vertical splitting
    if p[0] in ("a", "q", "'"):
        if p[0] == "a":
            h_mod = "h"
        elif p[0] == "q":
            h_mod = "l"
        else:
            h_mod = "t"
        p = p[1:]
    else:
        h_mod = ""

    lh_up = "qwfpg"
    lh = "arstd"
    lh_down = "zxcvb"
    rh_up = "jluy;"
    rh = "hneio"
    rh_down = "km,./"
    if p == lh[1]:
        r = "a1"
    elif p == lh[1].upper():
        r = "a1s"
    elif p == lh[2]:
        r = "a2"
    elif p == lh[2].upper():
        r = "a2s"
    elif p == lh[3]:
        r = "a3"
    elif p == rh[0]:
        r = "b1"
    elif p == rh[1]:
        r = "b2"
    elif p == rh[2]:
        r = "b3"
    elif p == rh[3]:
        r = "b4"

    elif p == lh[4]:
        r = "a"
    elif p == lh_up[3]:
        r = "ah1"
    elif p == lh_up[4]:
        r = "ah2"
    elif p == lh_down[2]:
        r = "am1"
    elif p == lh_down[3]:
        r = "am2"

    elif p == rh[0]:
        r = "b"
    elif p == rh_up[0]:
        r = "bh1"
    elif p == "g":
        r = "bh2"
    elif p == "m":
        r = "bm1"
    elif p == "w":
        r = "bm2"

    else:
        return ""

    if h_mod:
        r = h_mod + r

    return r
