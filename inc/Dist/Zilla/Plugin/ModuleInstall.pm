package  inc::Dist::Zilla::Plugin::ModuleInstall;

# $Id:$
use strict;
use warnings;
use Moose;
use Cwd;
use Data::Dump qw( dump );
my $lib = "";

BEGIN {
  $lib = cwd . "/lib/";
}
use lib "$lib";
use Dist::Zilla::Plugin::ModuleInstall ();

print "Bootstrapping Plugin::ModuleInstall\n";
extends 'Dist::Zilla::Plugin::ModuleInstall';

__PACKAGE__->meta->make_immutable;

1;

