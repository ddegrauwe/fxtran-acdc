package Pointer::Parallel::OpenMPSingleColumn;

use strict;
use Pointer::Parallel;
use Fxtran;
use DIR;
use Loop;

sub getDefaultWhere
{
  'host';
}

sub setOpenMPDirective
{
  my ($par, $t) = @_;

  my @priv = &Pointer::Parallel::getPrivateVariables ($par, $t);

  my ($do) = &F ('.//do-construct[./do-stmt[string(do-V)="JBLK"]]', $par);

  my $indent = &Fxtran::getIndent ($do);

  my $C = &n ('<C>!$OMP PARALLEL DO PRIVATE (' . join (', ', @priv)  . ')</C>');
  
  $do->parentNode->insertBefore ($C, $do);
  $do->parentNode->insertBefore (&t ("\n" . (' ' x $indent)), $do);

}

sub makeParallel
{
  shift;
  my ($par, $t) = @_;

  &DIR::removeDIR ($par);

  my ($do) = &F ('./do-construct', $par);

  die unless ($do);

  &Loop::removeJlonConstructs ($par);


  my @x = &F ('./node()', $do);

  for my $x (@x)
    {
      $x->unbindNode ();
    }

  my ($do_jlon) = &Fxtran::parse (fragment => << 'EOF');
DO JLON = 1, MIN (YDCPG_OPTS%KLON, YDCPG_OPTS%KGPCOMP - (JBLK - 1) * YDCPG_OPTS%KLON)
ENDDO
EOF

  my $in_do_jlon = 0;

  my $indent = 0;

  while (my $x = shift (@x))
    {

      if (($x->nodeName eq 'call-stmt') && ($x->textContent =~ m/^CALL YLCPG_BNDS%UPDATE/o))
        {
          $do->appendChild ($do_jlon);
          $indent = &Fxtran::getIndent ($do_jlon);

          $do->insertBefore (&t ("\n" . (' ' x $indent)), $do_jlon);
          $do->insertBefore (&t ("\n" . (' ' x $indent)), $do_jlon);

          $do_jlon->insertAfter (&s ("YLSTACK%U = stack_u (YSTACK, JBLK, YDCPG_OPTS%KGPBLKS)"), $do_jlon->firstChild);
          $do_jlon->insertAfter (&t ("\n" . (' ' x $indent)), $do_jlon->firstChild);
          $do_jlon->insertAfter (&s ("YLSTACK%L = stack_l (YSTACK, JBLK, YDCPG_OPTS%KGPBLKS)"), $do_jlon->firstChild);
          $do_jlon->insertAfter (&t ("\n" . (' ' x $indent)), $do_jlon->firstChild);

          $do_jlon->insertAfter (&s ("YLCPG_BNDS%KFDIA = JLON"), $do_jlon->firstChild);
          $do_jlon->insertAfter (&t ("\n" . (' ' x $indent)), $do_jlon->firstChild);
          $do_jlon->insertAfter (&s ("YLCPG_BNDS%KIDIA = JLON"), $do_jlon->firstChild);
          $do_jlon->insertAfter (&t ("\n" . (' ' x $indent)), $do_jlon->firstChild);


          $in_do_jlon = 1;
          $do->appendChild (shift (@x));
          next;
        }
      elsif ($x->nodeName eq 'end-do-stmt')
        {
          $do_jlon->insertBefore (&t (' ' x $indent), $do_jlon->lastChild);
          $do->appendChild ($x);
        }
      elsif ($in_do_jlon)
        {
          $do_jlon->insertBefore ($x, $do_jlon->lastChild);
        }
      else
        {
          $do->appendChild ($x);
        }

    }


  for my $N (&F ('.//named-E[R-LT/array-R/section-subscript-LT[string(section-subscript[1])=":"]]/N', $do))
    {
      next unless ($t->{$N->textContent}{nproma});    # Skip non-NPROMA stuff
      my $expr = $N->parentNode;
      next if ($expr->parentNode->nodeName eq 'arg'); # Skip routine arguments
      my ($ss) = &F ('./R-LT/array-R/section-subscript-LT/section-subscript[1]', $expr);
      $ss->replaceNode (&n ('<section-subscript><lower-bound><named-E><N><n>JLON</n></N></named-E></lower-bound></section-subscript>'));
    }

  my @call = &F ('.//call-stmt', $do_jlon);

  for my $call (@call)
    {
      my ($proc) = &F ('./procedure-designator/named-E/N/n/text()', $call);
      $proc->setData ($proc->textContent . '_OPENACC');
      my ($argspec) = &F ('./arg-spec', $call);
      $argspec->appendChild (&t (','));
      $argspec->appendChild (&n ('<arg><arg-N><k>YDSTACK</k></arg-N>=<named-E><N><n>YLSTACK</n></N></named-E></arg>'));
    }


  &setOpenMPDirective ($par, $t);


  return $par;
}

1;