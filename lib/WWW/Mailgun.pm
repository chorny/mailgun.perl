package WWW::Mailgun;

use strict;
use warnings;

use JSON;
use MIME::Base64;

require LWP::UserAgent;

sub new {
    my ($class, $param) = @_;

    my $Key = $param->{key} // die "You must specify an API Key";
    my $Domain = $param->{domain} // die "You need to specify a domain (IE: samples.mailgun.org)";
    my $Url = $param->{url} // "https://api.mailgun.net/v2";
    my $From = $param->{from} // "";

    my $self = {
        ua  => LWP::UserAgent->new,
        url => $Url . '/' . $Domain . '/',
        from => $From,

    };

    $self->{get} = sub {
        my ($self, $type, $data) = @_;
        return my $r = $self->{ua}->get(_get_route($self,[$type, $data]));
    };

    $self->{del} = sub {
        my ($self, $type, $data) = @_;
        return my $r = $self->{ua}->delete(_get_route($self,[$type,$data]));
    };

    $self->{post} = sub {
        my ($self, $type, $data) = @_;
        return my $r = $self->{ua}->post(_get_route($self,$type), Content => $data);
    };

    $self->{ua}->default_header('Authorization' => 'Basic ' . encode_base64('api:' . $Key));

    return bless $self, $class;
}

sub _handle_response {
    my ($response) = shift;

    my $rc = $response->code;

    return 1 if $rc  == 200;

    die "Bad Request - Often missing a required parameter" if $rc == 400;
    die "Unauthorized - No valid API key provided" if $rc == 401;
    die "Request Failed - Parameters were valid but request failed" if $rc == 402;
    die "Not Found - The requested item doesn’t exist" if $rc == 404;
    die "Server Errors - something is wrong on Mailgun’s end" if $rc >= 500;

}

sub send {
    my ($self, $msg)  = @_;

    $msg->{from} = $msg->{from} // $self->{from};
    $msg->{to} = $msg->{to} // die "You must specify an email address to send to";
    if (ref $msg->{to} eq 'ARRAY') {
        $msg->{to} = join(',',@{$msg->{to}});
    }

    $msg->{subject} = $msg->{subject} // "";
    $msg->{text} = $msg->{text} // "";

    my $r = $self->{ua}->post($self->{url}.'messages',Content_Type => 'multipart/form-data', Content => $msg);

    _handle_response($r);

    return from_json($r->decoded_content);
}

sub _get_route {
    my ($self, $path) = @_;

    if (ref $path eq 'ARRAY'){
        my @clean = grep {defined} @$path;
        $path = join('/',@clean);
    }
    return $self->{url} . $path;
}

sub unsubscribes {
    my ($self, $method, $data) = @_;
    $method = $method // 'get';
    
    my $r = $self->{lc($method)}->($self,'unsubscribes',$data);
    _handle_response($r);
    return from_json($r->decoded_content);
}

sub complaints {
    my ($self, $method, $data) = @_;
    $method = $method // 'get';

    my $r = $self->{lc($method)}->($self,'complaints',$data);
    _handle_response($r);
    return from_json($r->decoded_content);
}

sub bounces {
    my ($self, $method, $data) = @_;
    $method = $method // 'get';

    my $r = $self->{lc($method)}->($self,'bounces',$data);
    _handle_response($r);
    return from_json($r->decoded_content);
}

sub stats {
    my $self = shift;

    my $r = $self->{ua}->get($self->{url}.'stats');
    _handle_response($r);
    return from_json($r->decoded_content);
}

sub logs {
    my $self = shift;

    my $r = $self->{ua}->get($self->{url}.'log');
    _handle_response($r);
    return from_json($r->decoded_content);
}

sub mailboxes {
    my $self = shift;

    my $r = $self->{ua}->get($self->{url}.'mailboxes');
    _handle_response($r);
    return from_json($r->decoded_content);
}
