#!/bin/bash

#set -x
#set -e

. $(dirname $0)/prolog.sh

ff="arpifs/adiab/gnhpre.F90                       \
	arpifs/adiab/gnhgrpre.F90                     \
	arpifs/adiab/gpflwi.F90                       \
	arpifs/adiab/gnhee_grp.F90                    \
	arpifs/adiab/gpxxd.F90                        \
	arpifs/adiab/gnhgrgw.F90                      \
	arpifs/adiab/gnhd3.F90                        \
	arpifs/adiab/gnh_tndlagadiab_uvs.F90          \
	arpifs/adiab/gnh_tndlagadiab_spd.F90          \
	arpifs/adiab/gnh_tndlagadiab_gw.F90           \
	arpifs/adiab/gnh_tndlagadiab_svd.F90          \
	arpifs/adiab/gnhee_refine_psurf.F90           \
	arpifs/utility/verderfe.F90                   \
	algor/external/linalg/tridia.F90              \
   .fypp/arpifs/adiab/siseve_gp.F90               \
   .fypp/arpifs/adiab/sidd_gp.F90                 \
   .fypp/arpifs/adiab/siptp_gp.F90                \
   .fypp/arpifs/adiab/sidh_gp.F90                 \
   .fypp/arpifs/adiab/sinhee_seve_gp.F90          \
   .fypp/arpifs/adiab/sitnu_nh_gp.F90             \
   .fypp/arpifs/adiab/sigam_nh_gp.F90             \
   arpifs/adiab/gp_kappa.F90                      \
   arpifs/adiab/gp_kappat.F90                     \
   arpifs/adiab/larcinha.F90"

ff=""

### create _openacc files
for f in ${ff}; do

	echo "creating openacc version of ${f}"

	dir=$(dirname ${f} | sed -e "s|.fypp/||") # remove leading .fypp
	cpg_dyn=""   # si*gp files use KIDIA
	echo ${f} | grep -q "adiab/si.*_gp.F90" || cpg_dyn="--cpg_dyn"    # other files use KST

	openacc.pl --stack84 --cycle 49 --pointers --nocompute ABOR1 --version ${cpg_dyn} --dir src/local/ifsaux/openacc/$dir $(resolve --user $f)


	# check if called openacc and parallel files exist
	f_acc=ifsaux/openacc/${dir}/$(basename $f); f_acc=${f_acc%.F90}_openacc.F90
	openacc_includes=$(grep "#include.*_openacc.intfb.h" src/local/${f_acc} | awk -F' ' '{print $2}' | sed -e "s/\"//g")
	for ii in ${openacc_includes}; do
		zz=$(find IAL/ifsaux/ -name ${ii})
		if [[ -z ${zz} ]]; then
			echo "  warning: ${ii} doesn't exist yet"
		else
			echo "  (ok) ${ii} already exists"
		fi
	done

done


# dirty fix!
mv src/local/ifsaux/openacc/algor/external/linalg/tridia_openacc.intfb.h src/local/ifsaux/openacc/algor/external/linalg/tridia_openacc.h > /dev/null 2>&1

### create _parallel files
ff="arpifs/adiab/cpg_gp.F90         \
	arpifs/adiab/cpg_gp_nhee.F90    \
	arpifs/adiab/lacdyn.F90         \
	arpifs/adiab/lanhsi.F90         \
	arpifs/adiab/lanhsib.F90        \
	arpifs/adiab/latte_kappa.F90    \
	arpifs/adiab/lapinea.F90        \
	arpifs/adiab/lapineb.F90        \
	aladin/adiab/elarmes.F90        \
	arpifs/adiab/larcinb.F90        \
	arpifs/adiab/larcinhb.F90"

ff="arpifs/adiab/lapineb.F90 arpifs/adiab/larcinhb.F90"

for f in ${ff}; do

	echo "creating parallel version of ${f}"

	dir=$(dirname $f)

	pointerParallel.pl \
		--gpumemstat --stack84 --jlon JROF --nproma YDCPG_OPTS%KLON,YDGEOMETRY%YRDIM%NPROMA,YDGEOMETRY%YRDIM%NPROMNH --cycle 49 --use-acpy \
		--types-fieldapi-dir types-fieldapi --post-parallel synchost,nullify --version --dir \
		src/local/$dir $(resolve $f)
	
	# check if called openacc and parallel files exist
	openacc_includes=$(grep "#include.*_openacc.intfb.h" src/local/${f%.F90}_parallel.F90 | awk -F' ' '{print $2}' | sed -e "s/\"//g")
	for ii in ${openacc_includes}; do
		zz=$(find IAL/ -name ${ii})
		if [[ -z ${zz} ]]; then
			echo "  warning: ${ii} doesn't exist yet"
		else
			echo "  (ok) ${ii} already exists"
		fi
	done

	parallel_includes=$(grep "#include.*_parallel.intfb.h" src/local/${f%.F90}_parallel.F90 | awk -F' ' '{print $2}' | sed -e "s/\"//g")
	for ii in ${parallel_includes}; do
		zz=$(find src/local/.intfb/ -name ${ii})
		if [[ -z ${zz} ]]; then
			echo "  warning: ${ii} doesn't exist yet"
		else
			echo "  (ok) ${ii} already exists"
		fi
	done


done


