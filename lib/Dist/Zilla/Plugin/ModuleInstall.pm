use strict;
use warnings;

package Dist::Zilla::Plugin::ModuleInstall;
our $VERSION = '0.01002219';



# ABSTRACT: Build Module::Install based Distributions with Dist::Zilla

use Moose;
use Moose::Autobox;

with 'Dist::Zilla::Role::InstallTool';
with 'Dist::Zilla::Role::TextTemplate';
with 'Dist::Zilla::Role::Tempdir';
with 'Dist::Zilla::Role::MetaProvider';

use Dist::Zilla::File::InMemory;



use namespace::autoclean;

require inc::Module::Install;

my $template = q|

use strict;
use warnings;

use inc::Module::Install {{ $miver }};

name    '{{ $module_name }}' ;
abstract "{{ quotemeta( $dist->abstract ) }}" ;
author   "{{ quotemeta( $dist->authors->[0] ) }}";
version  "{{ quotemeta( $dist->version  ) }}";
license  '{{ $dist->license->meta_yml_name }}';
{{
  my $prereq = $dist->prereq;
  $OUT .= qq{requires   "} . quotemeta( $_ ) . qq{" => "} . quotemeta( $prereq->{$_} ) . qq{";\n}
    for keys %$prereq;
  chomp $OUT;
  return '';
}}

WriteAll();

|;

sub metadata {
  return {
    configure_requires => { 'ExtUtils::MakeMaker' => 6.42 },
    build_requires     => { 'ExtUtils::MakeMaker' => 6.42 }
  };
}

sub setup_installer {
  my ( $self, $arg ) = @_;

  my $name = $self->zilla->name;

  #  my $exe_files = $self->zilla->files
  #    ->grep( sub { ( $_->install_type || '' ) eq 'bin' } )
  #    ->map(  sub { $_->name } )
  #    ->join(q{ });

  #  my %test_dirs;
  #  for my $file ($self->zilla->files->flatten) {
  #    next unless $file->name =~ m{\At/.+\.t\z};
  #    (my $dir = $file->name) =~ s{/[^/]+\.t\z}{/*.t}g;

  #    $test_dirs{ $dir } = 1;
  #  }

  my $content = $self->fill_in_string(
    $template,
    {
      module_name => $name,
      dist        => \$self->zilla,
      miver       => "$Module::Install::VERSION",

      #     exe_files   => \$exe_files,
      #author_str  => \quotemeta( $self->zilla->authors->join(q{, }) ),
      #test_dirs   => join (q{ }, sort keys %test_dirs),
    },
  );

  my $file = Dist::Zilla::File::InMemory->new(
    {
      name    => 'Makefile.PL',
      content => $content,
    }
  );

  $self->add_file($file);
  my (@generated) = $self->capture_tempdir(
    sub {
      system( $^X, 'Makefile.PL' );
    }
  );
  for (@generated) {
    if ( $_->{status} eq 'N' ) {
      $self->log( 'ModuleInstall created: ' . $_->{name} );
      if ( $_->{name} =~ /^inc\/Module\/Install/ ) {
        $self->log( 'ModuleInstall added  : ' . $_->{name} );
        $self->add_file( $_->{file} );
      }
    }
    if ( $_->{status} eq 'M' ) {
      $self->log( 'ModuleInstall modified: ' . $_->{name} );
    }
  }
  return;
}

1;


__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::ModuleInstall - Build Module::Install based Distributions with Dist::Zilla

=head1 VERSION

version 0.01002219

=head1 SYNOPSIS

dist.ini

  [ModuleInstall]
  [MakeMaker::Tests] # use the testing part of eumm.

=head1 DESCRIPTION

This module will create a F<Makefile.PL> for installing the dist using L<Module::Install>.

It is at present a very minimal feature set, but it works.

=head1 AUTHOR

  Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

