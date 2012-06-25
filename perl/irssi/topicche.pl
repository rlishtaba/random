# INSTALLATION
# ------------
#
#   /sbar topic remove topic
#   /sbar topic remove topic_empty
#   /sbar topic add -after topicbarstart -priority 0 -alignment left topicche
#

use Encode;

use Irssi;
use Irssi::TextUI;
use vars qw($VERSION %IRSSI);

$VERSION = '0.1';
%IRSSI = (
	author      => 'meh',
	contact     => 'meh@paranoici.org',
	name        => 'topicche',
	description => 'Animated topic.',
	license     => 'WTFPL',
);

# the refresh rate in milliseconds
Irssi::settings_add_int('topicche', 'topicche_refresh', 150);

# the default ticks waiting before starting the rotation
Irssi::settings_add_int('topicche', 'topicche_wait', 10);

sub escape {
	my $text = shift;

	$text =~ s/%/%%/g;

	return $text;
}

sub topic {
	my $window = Irssi::active_win()->{active};
	my $server = $window->{server};
	my $topic;

	if ($window->{type} eq 'QUERY') {
		my $query = $server->query_find($window->{name});

		$topic = "$query->{address} ($server->{tag})";
	}
	elsif ($window->{type} eq 'CHANNEL') {
		my $channel = $server->channel_find($window->{name});

		$topic = $channel->{topic};
	}
	else {
		$topic = 'Irssi v' . Irssi::parse_special('$J') . ' - http://www.irssi.org';
	}

	if ($topic) {
		$topic =~ s/\003((\d\d?)(,\d\d?)?)?//g;
		$topic =~ s/\001//g;
		$topic =~ s/\002//g;

		return $topic;
	}
	else {
		return '';
	}
}

my $current = 0;
my $spacing = -1;
my $wait    = Irssi::settings_get_int('topicche_wait');

sub show {
	my ($item, $get_size_only) = @_;

	$item->default_handler(1, ' ' x 1024, undef, 1);

	if ($get_size_only) {
		return;
	}

	my $topic = decode_utf8(topic());
	my $width = $item->{size} - 1;

	if ($wait > 0 || length($topic) <= $width) {
		$item->default_handler(0, ' ' . escape($topic), undef, 1);
		$wait--;

		return;
	}

	if ($spacing == -1) {
		$spacing = $width / 2;
	}

	my $text = substr $topic, $current;

	if (length($text) == 0) {
		$text .= ' ' x $spacing . $topic;
		$spacing--;

		if ($spacing <= 0) {
			$current = 0;
			$spacing = -1;
		}
	}
	elsif (length($text) < $width / 2) {
		$text .= ' ' x ($width / 2) . substr $topic, 0, $width - length($text);
		$current++;
	}
	else {
		$current++;
	}

	$item->default_handler(0, ' ' . escape($text), undef, 1);
}

Irssi::statusbar_item_register('topicche', '$0', 'show');

sub redraw {
	Irssi::statusbar_items_redraw('topicche');
}

Irssi::signal_add 'window changed' => sub {
	redraw();

	$current = 0;
	$spacing = -1;
	$wait    = Irssi::settings_get_int('topicche_wait');
};

my $timeout;

Irssi::signal_add 'setup changed' => sub {
	if ($timeout) {
		Irssi::timeout_remove($timeout);
	}

	$timeout = Irssi::timeout_add(Irssi::settings_get_int('topicche_refresh'), 'redraw', undef);
};

$timeout = Irssi::timeout_add(Irssi::settings_get_int('topicche_refresh'), 'redraw', undef);