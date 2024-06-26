package Plugins::DSDPlayer::Plugin;

use strict;

use base qw(Slim::Plugin::OPMLBased);

use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Player::TranscodingHelper;

use Plugins::DSDPlayer::PlayerSettings;

my $prefs = preferences('plugin.playdsd');

my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'plugin.playdsd',
	'defaultLevel' => 'WARN',
	'description'  => 'PLUGIN_DSDPLAYER',
});

sub initPlugin {
	my $class = shift;

	Plugins::DSDPlayer::PlayerSettings->new;

	Slim::Control::Request::subscribe(\&initClientForDSD, [['client'],['new','reconnect']]);
}

sub setupTranscoder {
    my $client = $_[0] || return;

	my $usedop   = $prefs->client($client)->get('usedop');
	my $resample = $prefs->client($client)->get('resample') || "::::::";
	my $gain     = $prefs->client($client)->get('gain');

	my $cmdTable    = "[dsdplay] -R $resample " . '$START$ $END$ $RESAMPLE$ $FILE$';
	$cmdTable .= " | [sox] -q -t flac - -t flac -C 0 - gain -l $gain" if $gain;
	my $cmdTableDoP = "[dsdplay] -R $resample -u " . '$START$ $END$ $RESAMPLE$ $FILE$';
	my $capabilities = { F => 'noArgs', T => 'START=-s %t', U => 'END=-e %v', D => 'RESAMPLE=-r %d' };

	my $wvpxCmdTable = "[wvunpack] " . '$FILE$ $START$ $END$' . " --dff -o - | [dsdplay] -R $resample " . '$RESAMPLE$'; 
	my $wvpxCmdTableDoP = "[wvunpack] " . '$FILE$ $START$ $END$' . " --dff -o - | [dsdplay] -u -R $resample " . '$RESAMPLE$';
	my $wvpxCapabilities = { F => 'noArgs', T => 'START=--skip=%t', U => 'END=--until=%v', D => 'RESAMPLE=-r %d' };

	my $dsf = 'dsf-flc-*-' . lc($client->macaddress);
	my $dff = 'dff-flc-*-' . lc($client->macaddress);
	my $wvpx = 'wvpx-flc-*-' . lc($client->macaddress);

	if ($usedop) {

		$Slim::Player::TranscodingHelper::commandTable{ $dsf } = $cmdTableDoP;
		$Slim::Player::TranscodingHelper::capabilities{ $dsf } = $capabilities;
		$Slim::Player::TranscodingHelper::commandTable{ $dff } = $cmdTableDoP;
		$Slim::Player::TranscodingHelper::capabilities{ $dff } = $capabilities;
		$Slim::Player::TranscodingHelper::commandTable{ $wvpx } = $wvpxCmdTableDoP;
		$Slim::Player::TranscodingHelper::capabilities{ $wvpx } = $wvpxCapabilities;
		
	} else {

		$Slim::Player::TranscodingHelper::commandTable{ $dsf } = $cmdTable;
		$Slim::Player::TranscodingHelper::capabilities{ $dsf } = $capabilities;
		$Slim::Player::TranscodingHelper::commandTable{ $dff } = $cmdTable;
		$Slim::Player::TranscodingHelper::capabilities{ $dff } = $capabilities;
		$Slim::Player::TranscodingHelper::commandTable{ $wvpx } = $wvpxCmdTable;
		$Slim::Player::TranscodingHelper::capabilities{ $wvpx } = $wvpxCapabilities;

	}
}

sub initClientForDSD {
    my $request = shift;
  
    setupTranscoder($request->client());
}

1;
