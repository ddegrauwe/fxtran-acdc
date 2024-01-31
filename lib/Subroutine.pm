package Subroutine;

#
# Copyright 2022 Meteo-France
# All rights reserved
# philippe.marguinaud@meteo.fr
#


use strict;
use Fxtran;
use FileHandle;
  
sub getProgramUnit
{
  my $d = shift;

  my $pu;
  if ($d->isa ('XML::LibXML::Document'))
    {
      ($pu) = &F ('./object/file/program-unit', $d);
    }
  elsif ($d->nodeName eq 'program-unit')
    {
      $pu = $d;
    }
  else
    {
      die $d->nodeName;
    }

  return $pu;
}

sub addSuffix
{
  my ($d, $suffix) = @_;

  my $pu = &getProgramUnit ($d);

  my @sn = &F ('./subroutine-stmt/subroutine-N/N/n/text()|./end-subroutine-stmt/subroutine-N/N/n/text()', $pu);

  for my $sn (@sn) 
    {
      $sn->setData ($sn->data . $suffix);
    }

  my @drhook_name = &F ('.//call-stmt[string(procedure-designator)="DR_HOOK"]/arg-spec/arg/string-E/S/text()', $pu);

  for (@drhook_name)
    {
      (my $str = $_->data) =~ s/(["'])$/$suffix$1/go;
      $_->setData ($str);
    }

}

sub rename
{
  my ($d, $sub) = @_; 

  my $pu = &getProgramUnit ($d);

  my @name = (
               &F ('./subroutine-stmt/subroutine-N/N/n/text()', $pu),
               &F ('./end-subroutine-stmt/subroutine-N/N/n/text()', $pu),
             );
  my $name = $name[0]->textContent;

  my $name1 = $sub->($name);

  for (@name)
    {   
      $_->setData ($name1);
    }   

  my @drhook = &F ('.//call-stmt[string(procedure-designator)="DR_HOOK"]', $pu);

  for my $drhook (@drhook)
    {   
      next unless (my ($S) = &F ('./arg-spec/arg/string-E/S/text()', $drhook));
      my $str = $S->textContent;
      $str =~ s/$name/$name1/;
      $S->setData ($str);
    }   
  
}

sub getInterface
{
  my ($name, $find) = @_;
  my $file = $find->getInterface (name => $name);
  $file or die ("Could not find interface for $name");
  my $code = do { local $/ = undef; my $fh = 'FileHandle'->new ("<$file"); $fh or die ("Cannot open $file"); <$fh> };
  my ($intf) = &Fxtran::parse (fragment => $code);
  return $intf;
}

1;
