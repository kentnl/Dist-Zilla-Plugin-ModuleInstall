use strict;
use warnings;

package Dist::Zilla::Plugin::ModuleInstall;

# ABSTRACT: Build Module::Install based Distributions with Dist::Zilla

use Moose;
use Moose::Autobox;

with 'Dist::Zilla::Role::InstallTool';
with 'Dist::Zilla::Role::TextTemplate';
with 'Dist::Zilla::Role::Tempdir';
with 'Dist::Zilla::Role::PrereqSource';
with 'Dist::Zilla::Role::TestRunner';

use Dist::Zilla::File::InMemory;

=head1 DESCRIPTION

This module will create a F<Makefile.PL> for installing the dist using L<Module::Install>.

It is at present a very minimal feature set, but it works.

=cut

=head1 SYNOPSIS

dist.ini

  [ModuleInstall]
  [MakeMaker::Tests] # use the testing part of eumm.



=cut

use namespace::autoclean;

require inc::Module::Install;

my $template = q|

use strict;
use warnings;

use inc::Module::Install {{ $miver }};

name    '{{ $module_name }}' ;
abstract "{{ quotemeta( $abstract ) }}" ;
author   "{{ quotemeta( $author ) }}";
version  "{{ quotemeta( $version  ) }}";
license  '{{ $license }}';
{{ $requires }}
WriteAll();

|;

my $prereq_template = q|{{$type}} "{{ quotemeta( $prereq_name ) }}" => "{{ quotemeta( $prereq_version ) }}";|;

sub register_prereqs {
  my ($self) = @_;
  $self->zilla->register_prereqs( { phase => 'configure' }, 'ExtUtils::MakeMaker' => 6.42 );
  $self->zilla->register_prereqs( { phase => 'build' },     'ExtUtils::MakeMaker' => 6.42 );
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
  my $prereqs = $self->zilla->prereqs;
  my %prereqs = (
    configure_requires => $prereqs->requirements_for(qw(configure requires))->as_string_hash,
    build_requires     => $prereqs->requirements_for(qw(build     requires))->as_string_hash,
    requires           => $prereqs->requirements_for(qw(runtime   requires))->as_string_hash,
    recommends         => $prereqs->requirements_for(qw(runtime   recommends))->as_string_hash,
    test_requires      => $prereqs->requirements_for(qw(test   requires))->as_string_hash,

  );
 use Data::Dump qw( dump );
 my @requires;

 my $doperl = sub {
     my ( $package, $version ) = @_;
     if( $package eq 'perl' ){
        push @requires, $self->fill_in_string(q|perl_version "{{ quotemeta( $version ) }}";|, {
            version => $version,
        });
        return 1;
     }
     return 0;
 };
 my $doit = sub {
    my ( $sourcekey , $targetkey, $hash ) = @_;
    for ( sort keys %{ $hash->{$sourcekey} } ){
    next if $doperl->( $_, $hash->{$sourcekey}->{$_} );
    push @requires, $self->fill_in_string( $prereq_template, {
        type => $targetkey,
        prereq_name => $_ ,
        prereq_version => $hash->{$sourcekey}->{$_}
    });
  }
 };

 $doit->( configure_requires => 'configure_requires', \%prereqs );
 $doit->( build_requires => 'configure_requires', \%prereqs );
 $doit->( requires => 'requires', \%prereqs );
 $doit->( requires => 'requires', \%prereqs );
 $doit->( recommends => 'recommends', \%prereqs );
 $doit->( test_requires => 'test_requires', \%prereqs );


 my $content = $self->fill_in_string(
    $template,
    {
      module_name => $name,
      abstract    => $self->zilla->abstract,
      author      => $self->zilla->authors->[0],
      version     => $self->zilla->version,
      license     => $self->zilla->license->meta_yml_name,
      dist        => \$self->zilla,
      miver       => "$Module::Install::VERSION",
      requires    => join(qq{\n}, @requires ),

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
      system( $^X, 'Makefile.PL' ) and do {
        warn "Error running Makefile.PL, freezing in tempdir so you can diagnose it\n";
        warn "Will die() when you 'exit' ( and thus, erase the tempdir )";
        system("bash") and die "Can't call bash :(";
        die "Finished with tempdir diagnosis, killing dzil";
      };
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

sub build {
  my ($self) = shift;
  system( $^X => 'Makefile.PL' ) and die "error running Makefile.PL\n";
  system('make') and die "error running make\n";
  return;
}

sub test {
  my ( $self, $target ) = @_;

  $self->build;
  system('make test') and die "error running make test\n";
  return;

}

1;

