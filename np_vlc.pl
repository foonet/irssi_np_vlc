use strict;
use vars qw($VERSION %IRSSI %channels);
use Irssi qw(command_bind signal_add signal_stop channel_find);
use IO::Socket::INET;
use XML::Simple;
use HTTP::Request;
use LWP::UserAgent;
use LWP::Simple;
use Module::Refresh;
use Encode;

$VERSION = '0.1';

%IRSSI = (
	authors		=> 'Ene Alin Gabriel',
	contact		=> 'zmeu@foonet.ro',
	name		=> 'Now Playing: VLC Edition',
	description	=> 'Displays the currently playing song or movie retrieved from VLC, either on the same system or remotely. Also allows for remote triggering, via screen registers.',
	license		=> 'GPLv3',
);

my $VLC_URL="http://127.0.0.1:8080/requests/irssi.xml";
my $VLC_PASS="password";
my $VLC_VERSION="Now Playing: VLC Edition for Irssi | Author: ZmEu | URL: http://zmeu.foonet.ro";

sub local_np_vlc{
    my($data, $server, $channel) = @_;

    my $title = get_np_vlc();

    if($title ne ""){
	if(defined($channel)){
	    $server->command('action '.$channel->{'name'}.' '.$title.' '.$data);
	}else{
	    Irssi::print($title);
	}
    }
}

sub get_np_vlc{
    my ($data, $server, $channel) = @_;

    my ($return_value);

    my @vlc_request = ();
    push(@vlc_request, "title");
    push(@vlc_request, "status");
    push(@vlc_request, "time");
    #push(@vlc_request, "resolution");
    

    my $vlc_data = {};

    $vlc_data = get_data_vlc( @vlc_request );

    my $hours   = sprintf "%02d", $vlc_data->{"time"} / 3600;
    my $minutes = sprintf "%02.0f", ($vlc_data->{"time"} % 3600) / 60;
    my $seconds = sprintf "%02d", $vlc_data->{"time"} % 60;
    
    if($vlc_data->{"title"} ne ''){
	#$return_value = "playing ".$vlc_data->{"title"}." ".$vlc_data->{"resolution"}.""." ".$hours.":".$minutes.":".$seconds;
        $return_value = "playing: ".$vlc_data->{"title"}." ".$hours.":".$minutes.":".$seconds;
    }else{
	$return_value = "VLC doesn't running. ".$VLC_VERSION;
    }
}

sub get_data_vlc{
    my(@tags) = @_;

    my $xml_doc;

    my $return_value = {};
    
    my $req = HTTP::Request->new('GET',$VLC_URL);

    $req->authorization_basic("",$VLC_PASS);

    my $ua = LWP::UserAgent->new;

    my $response = $ua->request($req);

    if(!$response->is_error()){
	my $xml_doc = XMLin($response->decoded_content);

	foreach(@tags){
	    $return_value->{$_} = $xml_doc->{$_};
	}
    }
    
    return $return_value;

}

command_bind('npvlc', 'local_np_vlc');
