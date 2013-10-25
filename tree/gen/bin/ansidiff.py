#!/usr/bin/env python

# ansidiff.py: A script to color the output of diff or git-show.
# Copyright (C) 2008  Facebook.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import cgi
import getopt
import sys

# diff-part types
dp_gitshow_header = 's'
dp_file_header = 'f'
dp_section_header = '@'
dp_same_block = ' '
dp_add_block = '+'
dp_del_block = '-'
dp_notice_block = '\\'  # for:  \ No newline at end of file
dp_blocks = (dp_same_block, dp_add_block, dp_del_block, dp_notice_block)

def do_warn(s):
    print(s, file=sys.stderr)

def lev_dist(a, b): # from the python cookbook (http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/252237)
    """ Calculates the Levenshtein Distance between strings a and b,
        as a fraction of the length of the longer string
    """
    n, m = len(a), len(b)
    if n > m:
        # Make sure n <= m, to use O(min(n,m)) space
        a,b = b,a
        n,m = m,n
    if not m:
        return 0

    current = range(n+1)
    for i in range(1,m+1):
        previous, current = current, [i]+[0] * m
        for j in range(1, n+1):
            add, delete = previous[j] + 1, current[j-1] + 1
            change = previous[j-1]
            if a[j-1] != b[i-1]:
                change +=1
            current[j] = min(add, delete, change)
    return float(current[n]) / m

def render_matrix(m):
    k = list(m.keys())
    x_vals = [x for (x, y) in k]
    y_vals = [y for (x, y) in k]
    x_r = list(range(min(x_vals), max(x_vals) + 1))
    y_r = list(range(min(y_vals), max(y_vals) + 1))
    return '\n'.join([' '.join([str(m[x, y]) for x in x_r]) for y in y_r])

def render_bools(l):
    m = {False: '.', True: 'X'}
    return ''.join([m[x] for x in l])

def true_ranges(l):
    rs = []
    r_start = None
    for i, v in enumerate(l):
        if r_start == None:
            if v:
                r_start = i
        elif not v:
            rs.append((r_start + 1, i + 1))
            r_start = None
    if r_start != None:
        rs.append((r_start + 1, len(l) + 1))
    return rs

def prune_short_false_runs(l, n=3):
    '''given a list of bools, turn to true any consecutive run of falses with
        length <= n'''
    false_count = 0
    ret = []
    for b in l:
        if b:
            if false_count:
                if false_count <= n:
                    ret += [True] * false_count
                else:
                    ret += [False] * false_count
                false_count = 0
            ret.append(b)
        else:
            false_count += 1
    if false_count:
        if false_count <= n:
            ret += [True] * false_count
        else:
            ret += [False] * false_count
    return ret

def lev_dist_hls(a, b):
    # we actually get much more natural results processing backwards
    a = a[::-1]
    b = b[::-1]

    c, d = {}, {}
    # d constants
    d_x, d_y = 1, 2
    d_xy_same, d_xy_diff = 3, 4

    n, m = len(a), len(b)
    if n == 0 and m == 0:
        # don't get div by 0 error below
        return ([], [])

    c[0, 0] = 0
    # d[0, 0] is not set
    d[0, 0] = 0
    for i in range(1, n + 1):
        c[i, 0] = i
        d[i, 0] = d_x
    for j in range(1, m + 1):
        c[0, j] = j
        d[0, j] = d_y

    for i in range(1, n + 1):
        for j in range(1, m + 1):
            x = c[i - 1, j] + 1
            y = c[i, j - 1] + 1
            if a[i - 1] == b[j - 1]:
                z = c[i - 1, j - 1]
                my_d = d_xy_same
            else:
                z = c[i - 1, j - 1] + 1
                my_d = d_xy_diff
            my_c = min(x, y, z)
            if my_c == x:
                # prefer same but not diff for best reconstruction
                if my_d != d_xy_same:
                    my_d = d_x
            elif my_c == y:
                # prefer same but not diff for best reconstruction
                if my_d != d_xy_same:
                    my_d = d_y
            c[i, j] = my_c
            d[i, j] = my_d

    # reconstruct
    i, j = n, m
    a_hl, b_hl = [], []
    while i > 0 or j > 0:
        my_d = d[i, j]
        if my_d == d_x:
            a_hl.append(True)
            i -= 1
        elif my_d == d_y:
            b_hl.append(True)
            j -= 1
        else:
            do_hl = (my_d == d_xy_diff)
            a_hl.append(do_hl)
            b_hl.append(do_hl)
            i -= 1
            j -= 1

    return (true_ranges(prune_short_false_runs(a_hl)),
        true_ranges(prune_short_false_runs(b_hl)))

class Printer:
    def render_del_add_blocks(self, dp_del, dp_add):
        dp_del_type, dp_del_lines = dp_del
        dp_add_type, dp_add_lines = dp_add

        if len(dp_del_lines) * len(dp_add_lines) > 500:
            # we don't want to take too long, so just don't do any
            #   inter-line analysis/highlighting for large block-pairs
            return self.render_block(dp_del) + self.render_block(dp_add)

        dp_del_lines_hl = [[l, []] for l in dp_del_lines]
        dp_add_lines_hl = [[l, []] for l in dp_add_lines]
        # try to match up - and + lines
        matches = [(lev_dist(d[1:], a[1:]), d_i, a_i)
            for d_i, d in enumerate(dp_del_lines)
            for a_i, a in enumerate(dp_add_lines)]
        matches.sort()
        d_taken = set()
        a_taken = set()
        for score, d_i, a_i in matches:
            if score > .5:
                break
            if d_i in d_taken or a_i in a_taken:
                continue
            d_taken.add(d_i)
            a_taken.add(a_i)
            d_hls, a_hls = lev_dist_hls(dp_del_lines[d_i][1:],
                dp_add_lines[a_i][1:])
            dp_del_lines_hl[d_i][1] = d_hls
            dp_add_lines_hl[a_i][1] = a_hls

        return self.render_highlight_block((dp_del_type, dp_del_lines_hl),
            False, True) + \
            self.render_highlight_block((dp_add_type, dp_add_lines_hl),
            True, False)

    def render_block(self, dp):
        dp_type, dp_lines = dp
        return self.render_highlight_block((dp_type,
            [(l, []) for l in dp_lines]))

class HtmlPrinter(Printer):
    def render_header(self, comment=''):
        if comment:
            c = '<P>%s</P>' % self.escape(comment + '\n\n\n')
            # add newlines to <BR>'s since can see weird breaks on way long
            #   lines (bad browser doing that?)
            c = c.replace('<BR>', '<BR>\n')
        else:
            c = ''
        return '''\
<HEAD><STYLE TYPE='text/css'>
td {
    font-size: 8pt;
}
td td {
    white-space: pre;
}
td.mid {
    border: 0px solid black;
    border-left-width: 1px;
    border-right-width: 1px;
}
td.first {
    border-top-width: 1px;
}
td.last {
    border-bottom-width: 1px;
}
td.add {
    background: #ddffdd;
    border-color: green;
}
td.del {
    background: #ffdddd;
    border-color: red;
}
td.add font.hl {
    background: #99ee99;
}
td.del font.hl {
    background: #ee9999;
}
td.file {
    background: #ddddff;
    border-color: blue;
}
td.hunk {
    background: #ffffdd;
    border-color: yellow;
}
</STYLE></HEAD>
<BODY STYLE='font-size:8pt;font-family:Monaco,monospace'>''' + c + \
        '<TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">'

    def render_footer(self):
        return '</TABLE></BODY>'

    def escape(self, s):
        return cgi.escape(s).replace(' ', '&nbsp;').replace('\n', '<BR>')

    def render_highlight_block(self, dp, prev_block=False, next_block=False):
        dp_type, dp_lines = dp

        rows = []
        dp_lines_n = len(dp_lines)
        for i, (l, hls) in enumerate(dp_lines):
            classes = []
            if dp_type in (dp_add_block, dp_del_block, dp_file_header, dp_section_header):
                classes.append('mid')
                if dp_type == dp_add_block:
                    classes.append('add')
                elif dp_type == dp_del_block:
                    classes.append('del')
                elif dp_type == dp_file_header:
                    classes.append('file')
                elif dp_type == dp_section_header:
                    classes.append('hunk')
                if i == 0 and not prev_block:
                    classes.append('first')
                if i == dp_lines_n - 1 and not next_block:
                    classes.append('last')

            if hls:
                x = 0
                s = ''
                for hl_start, hl_end in hls:
                    s += self.escape(l[x:hl_start])
                    s += '<FONT CLASS="hl">' + \
                        self.escape(l[hl_start:hl_end]) + \
                        '</FONT>'
                    x = hl_end
                s += self.escape(l[x:])
            else:
                s = self.escape(l)

            rows.append('<TR><TD CLASS="%s">%s</TD></TR>\n' %
                (' '.join(classes), s))

        return ''.join(rows)

class TermPrinter(Printer):
    def render_header(self, comment):
        if comment:
            return comment + '\n\n\n'
        else:
            return ''

    def render_footer(self):
        return ''

    def render_ansi(self, fg):
        if type(fg) == type(()):
            s = '%d;%d' % fg
        else:
            s = str(fg)
        return '%c[%sm' % (27, s)

    def render_highlight_block(self, dp, prev_block=False, next_block=False):
        dp_type, dp_lines = dp

        if dp_type == dp_add_block:
            color = 32
            hl_color = (30, 42)
        elif dp_type == dp_del_block:
            color = 31
            hl_color = (30, 41)
        elif dp_type in (dp_file_header, dp_section_header):
            color = 33
            hl_color = 0
        else:
            color = 0
            hl_color = 0

        ls = []
        for l, hls in dp_lines:
            if hls:
                x = 0
                s = ''
                for hl_start, hl_end in hls:
                    s += self.render_ansi(color) + l[x:hl_start]
                    s += self.render_ansi(hl_color) + l[hl_start:hl_end] + \
                        self.render_ansi(0)
                    x = hl_end
                s += self.render_ansi(color) + l[x:] + self.render_ansi(0)
            else:
                s = self.render_ansi(color) + l + self.render_ansi(0)
            ls.append(s + '\n')

        return ''.join(ls)

def usage():
    print('ansidiff.py [-c comment]')
    sys.exit(-1)

if __name__ == '__main__':
    # -l does nothing, legacy option
    opt_list, rem_arg_list = getopt.getopt(sys.argv[1:], 'c:l')
    comment = ''
    printer_type = 'html'
    for opt, opt_val in opt_list:
        if opt == '-c':
            comment = opt_val
    for rem_arg in rem_arg_list:
        if rem_arg in ('html', 'mail'):
            printer_type = 'html'
        elif rem_arg == 'term':
            printer_type = 'term'
        else:
            usage()

    cur_dp_type = dp_file_header
    cur_dp_lines = []

    dps = []

    # process diff parts
    for i, l in enumerate([ln[:-1] for ln in sys.stdin.readlines()]):
        # git can have blank lines in "git show".  Pretend they start with
        # a space so we don't transition to another state.  This also prevents
        # the blank line from rendering as one pixel tall.
        if len(l) == 0:
            l = ' '
        c = l[0]

        # all the possible transitions between diff_part's
        if i == 0 and (l.startswith('commit ') or l.startswith('From ')):
            # First line starts with "commit" or "From "?
            # This is a git show or git format-patch.
            cur_dp_type = dp_gitshow_header
        elif cur_dp_type == dp_gitshow_header:
            # Git show doesn't end until a line starts with diff
            if l.startswith('diff '):
                dps.append((cur_dp_type, cur_dp_lines))
                cur_dp_lines = []
                cur_dp_type = dp_file_header
        elif cur_dp_type == dp_file_header:
            # the file-header can have arbitrary things and be 0-n lines tall
            #   but we'll know when it's over when we see a section header
            if c == dp_section_header:
                dps.append((cur_dp_type, cur_dp_lines))
                cur_dp_lines = []
                cur_dp_type = c
        elif cur_dp_type == dp_section_header:
            # the section-header is always exactly one '@@ ..' line
            if c in dp_blocks:
                dps.append((cur_dp_type, cur_dp_lines))
                cur_dp_lines = []
                cur_dp_type = c
            else:
                do_warn('unexpected line %d after section header: %s' %
                    i + 1, l)
                # panic and eject: jump back to top level
                dps.append((cur_dp_type, cur_dp_lines))
                cur_dp_lines = []
                cur_dp_type = dp_file_header
        else:
            # so cur_dp_type is in dp_blocks
            if c != cur_dp_type:
                dps.append((cur_dp_type, cur_dp_lines))
                cur_dp_lines = []
                if c in dp_blocks or c == dp_section_header:
                    cur_dp_type = c
                else:
                    cur_dp_type = dp_file_header
        cur_dp_lines.append(l)
    dps.append((cur_dp_type, cur_dp_lines))

    if printer_type == 'html':
        printer = HtmlPrinter()
    else:
        printer = TermPrinter()

    # print diff parts but consider - followed by + for change-detection
    sys.stdout.write(printer.render_header(comment))
    dp_i = 0
    dp_n = len(dps)
    while dp_i < dp_n:
        dp_type, dp = dps[dp_i]
        if dp_i < dp_n - 1 and dp_type == dp_del_block and \
                dps[dp_i + 1][0] == dp_add_block:
            sys.stdout.write(
                printer.render_del_add_blocks(dps[dp_i], dps[dp_i + 1]))
            dp_i += 2
        else:
            sys.stdout.write(printer.render_block(dps[dp_i]))
            dp_i += 1
    sys.stdout.write(printer.render_footer())
