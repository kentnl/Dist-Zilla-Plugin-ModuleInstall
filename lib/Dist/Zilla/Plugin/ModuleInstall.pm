use strict;
use warnings;

package Dist::Zilla::Plugin::ModuleInstall;

# ABSTRACT: Build Module::Install based Distributions with Dist::Zilla

use Moose;
use Moose::Autobox;

with 'Dist::Zilla::Role::InstallTool';
with 'Dist::Zilla::Role::TextTemplate';

use Dist::Zilla::File::InMemory;

=head1 DESCRIPTION

This module will create a F<Makefile.PL> for installing the dist using L<Module::Install>

=cut

use namespace::autoclean;

my $template = q|

use strict;
use warnings;

use inc::Module::Install;

name    '{{ $module_name }}' ;
abstract "{{ quotemeta( $dist->abstract ) }}" ;
author   "{{ quotemeta( $dist->authors->[0] ) }}";
version  "{{ quotemeta( $dist->version }}";
license  '{{ $dist->license->meta_yml_name }}';
{{
  my $prereq = $dist->prereq;
  $OUT .= qq{ require "} . quotemeta( $_ ) . qq{" => "} . quotemeta( $prereq->{$_} ) . qq{";\n"}
    for keys %$prereq;
  chomp $OUT;
  return '';
}}

WriteAll();

|;


sub setup_installer {
  my ($self, $arg) = @_;

  (my $name = $self->zilla->name) =~ s/-/::/g;

#  my $exe_files = $self->zilla->files
#    ->grep( sub { ( $_->install_type || '' ) eq 'bin' } )
#    ->map(  sub { $_->name } )
#    ->join(q{ });

#  my %test_dirs;
#  for my $file ($self->zilla->files->flatten) {
#    next unless $file->name =~ m{\At/.+\.t\z};
#    (my $dir = $file->name) =~ s{/[^/]+\.t\z}{/*.t}g;

#    $test_dirs{ $dir } = 1;
  }

  my $content = $self->fill_in_string(
    $template,
    {
      module_name => $name,
      dist        => \$self->zilla,
      #     exe_files   => \$exe_files,
      #author_str  => \quotemeta( $self->zilla->authors->join(q{, }) ),
      #test_dirs   => join (q{ }, sort keys %test_dirs),
    },
  );

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'Makefile.PL',
    content => $content,
  });

  $self->add_file($file);
  return;
}

1;

