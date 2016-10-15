package Kafka::Librd;
use strict;
use warnings;
our $VERSION = "0.02";
my $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

require XSLoader;
XSLoader::load('Kafka::Librd', $XS_VERSION);

use Exporter::Lite;
our @EXPORT_OK;

=head1 NAME

Kafka::Librd - bindings for librdkafka

=head1 VERSION

This document describes Kafka::Librd version 0.02

=head1 SYNOPSIS

    use Kafka::Librd;

    my $kafka = Kafka::Librd->new(
        Kafka::Librd::RD_KAFKA_CONSUMER,
        {
            "group.id" => 'consumer_id',
        },
    );
    $kafka->brokers_add('server1:9092,server2:9092');
    $kafka->subscribe( \@topics );
    while (1) {
        my $msg = $kafka->consumer_poll(1000);
        if ($msg) {
            if ( $msg->err ) {
                say "Error: ", Kafka::Librd::Error::to_string($err);
            }
            else {
                say $msg->payload;
            }
        }
    }


=head1 DESCRIPTION

This module provides perl bindings for librdkafka.

=head1 METHODS

=cut

=head2 new

    $kafka = $class->new($type, \%config)

Create a new instance. $type can be either C<RD_KAFKA_CONSUMER> or
C<RD_KAFKA_PRODUCER>. Config is a hash with configuration parameters as
described in
L<https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md>,
additionally it may include C<default_topic_config> key, with a hash containing
default topic configuration properties.

=cut

sub new {
    my ( $class, $type, $params ) = @_;
    return _new( $type, $params );
}

{
    my $errors = Kafka::Librd::Error::rd_kafka_get_err_descs();
    no strict 'refs';
    for ( keys %$errors ) {
        *{__PACKAGE__ . "::RD_KAFKA_RESP_ERR_$_"} = eval "sub { $errors->{$_} }";
        push @EXPORT_OK, "RD_KAFKA_RESP_ERR_$_";
    }
}

=head2 brokers_add

    $cnt = $kafka->brokers_add($brokers)

add one or more brokers to the list of initial bootstrap brokers. I<$brokers>
is a comma separated list of brokers in the format C<[proto://]host[:port]>.

=head2 subscribe

    $err = $kafka->subscribe(\@topics)

subscribe to the list of topics using balanced consumer groups.

=head2 unsubscribe

    $err = $kafka->unsubscribe

unsubscribe from the current subsctiption set

=head2 consumer_poll

    $msg = $kafka->consumer_poll($timeout_ms)

poll for messages or events. If any message or event received, returns
L<Kafka::Librd::Message> object. If C<$msg->err> for returned object is zero
(RD_KAFKA_RESP_ERR_NO_ERROR), then it is a proper message, otherwise it is an
event or an error.

=head2 consumer_close

    $err = $kafka->consumer_close

close down the consumer

=head1 Kafka::Librd::Message

This class maps to C<rd_kafka_message_t> structure from librdkafka and represents message or event. Objects of this class have the following methods:

=head2 err

return error code from the message

=head2 topic

return topic name

=head2 partition

return partition number

=head2 offset

return offset. Note, that the value is truncated to 32 bit if your perl doesn't
support 64 bit integers.

=head2 key

return message key

=head2 payload

return message payload

=cut

1;

__END__

=head1 CAVEATS

Module is in early stage of development.

Currently only bindings for high level consumer API are implemented.

Message offset is truncated to 32 bit if perl compiled without support for 64 bit integers.

=head1 SEE ALSO

L<https://github.com/edenhill/librdkafka>

=head1 BUGS

Please report any bugs or feature requests via GitHub bug tracker at
L<http://github.com/trinitum/perl-Kafka-Librd/issues>.

=head1 AUTHOR

Pavel Shaydo C<< <zwon at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016 Pavel Shaydo

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
