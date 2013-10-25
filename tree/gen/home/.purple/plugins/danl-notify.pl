use Purple;
use HTML::Strip;

%PLUGIN_INFO = (
    perl_api_version => 2,
    name => "danl-notify plugin",
    version => "0.1",
    summary => "Test plugin for the Perl interpreter.",
    description => "Your description here",
    author => 'danl@alum.mit.edu',
    url => "http://dzl.no-ip.org",

    load => "plugin_load",
    unload => "plugin_unload"
);

sub plugin_init {
    return %PLUGIN_INFO;
}

sub signal_cb {
    my ($account, $sender, $message, $conv, $flags) = @_;
    $sender =~ s/@.*//;
    my $cmd = "doNotify";
    if ($message =~ '<html.*') {
        my $hs = HTML::Strip->new();
        $message = $hs->parse($message);
        $hs->eof;
    }
    my @args = ("im", "1", $sender, $message);
    system {$cmd} $cmd, @args;
}

sub plugin_load {
    my $plugin = shift;
    my $data = "hello";
    my $conversation_handle = Purple::Conversations::get_handle();
    Purple::Signal::connect($conversation_handle, "received-im-msg", $plugin, 
        \&signal_cb, $data);
}

sub plugin_unload {
}
