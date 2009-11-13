

use strict;
use warnings;

use inc::Module::Install 0.91;

name    'Dist-Zilla-Plugin-ModuleInstall' ;
abstract "Build\ Module\:\:Install\ based\ Distributions\ with\ Dist\:\:Zilla" ;
author   "Kent\ Fredric\ \<kentnl\@cpan\.org\>";
version  "0\.01002219";
license  'perl';
requires   "Dist\:\:Zilla\:\:Role\:\:Tempdir" => "0\.01000003";
requires   "Dist\:\:Zilla" => "1\.093140";
requires   "Module\:\:Install" => "0\.90";
requires   "Moose\:\:Autobox" => "0\.10";
requires   "Moose" => "0\.92";

WriteAll();

