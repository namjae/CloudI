#-*-Mode:perl;coding:utf-8;tab-width:4;c-basic-offset:4;indent-tabs-mode:()-*-
# ex: set ft=perl fenc=utf-8 sts=4 ts=4 sw=4 et nomod:
#
# BSD LICENSE
# 
# Copyright (c) 2014-2017, Michael Truog <mjtruog at gmail dot com>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#     * All advertising materials mentioning features or use of this
#       software must display the following acknowledgment:
#         This product includes software developed by Michael Truog
#     * The name of the author may not be used to endorse or promote
#       products derived from this software without specific prior
#       written permission
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.
#

package Erlang::OtpErlangBinary;
use strict;
use warnings;

use constant TAG_BIT_BINARY_EXT => 77;
use constant TAG_BINARY_EXT => 109;

require Erlang::OutputException;

use overload
    '""'     => sub { $_[0]->as_string };

sub new
{
    my $class = shift;
    my ($value, $bits) = @_;
    if (! defined($bits))
    {
        $bits = 8;
    }
    my $self = bless {
        value => $value,
        bits => $bits,
    }, $class;
    return $self;
}

sub binary
{
    my $self = shift;
    my $value = $self->{value};
    if (ref($value) eq '')
    {
        my $length = length($value);
        if ($length > 4294967295)
        {
            die Erlang::OutputException->new('uint32 overflow');
        }
        my $bits = $self->{bits};
        if ($bits != 8)
        {
            return pack('CNC', TAG_BIT_BINARY_EXT, $length, $bits) . $value;
        }
        else
        {
            return pack('CN', TAG_BINARY_EXT, $length) . $value;
        }
    }
    else
    {
        die Erlang::OutputException->new('unknown binary type');
    }
}

sub as_string
{
    my $self = shift;
    my $class = ref($self);
    return "$class($self->{value},$self->{bits})";
}

1;
