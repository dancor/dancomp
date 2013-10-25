##
## Put me in ~/.irssi/scripts, and then execute the following in irssi:
##
##       /load perl
##       /script load notify
##

use strict;
use Irssi;
use vars qw($VERSION %IRSSI);

$VERSION = "0.01";
%IRSSI = (
    authors     => 'Luke Macken',
    contact     => 'lewk@csh.rit.edu',
    name        => 'notify.pl',
    description => 'TODO',
    license     => 'GNU General Public License',
    url         => 'http://lewk.org/log/code/irssi-notify',
);

sub notify {
    my ($dest, $text, $message) = @_;
    my $server = $dest->{server};

    return if (!$server || !($dest->{level} & MSGLEVEL_HILIGHT));

    system ("doNotify", "irc", "1", $dest->{target}, $message);
}

sub priv_message {
    my ($server, $message, $nick, $address, $target) = @_;
    system ("doNotify", "irc", "1", $nick, $message);
}

Irssi::signal_add('print text', 'notify');
Irssi::signal_add_last('message private', 'priv_message');
