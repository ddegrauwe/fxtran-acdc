#!/bin/bash


# create missing field_array stuff in types-fieldapi



for dim in $(seq 2 1 5); do

	cat > types-fieldapi/FIELD_${dim}RB_ARRAY.pl << EOF
\$VAR1 = {
          'comp' => {
                      'P' => [
                               'F_P',
                               $((dim-1)),
                               'REAL(KIND=JPRB)'
                             ]
                    },
          'name' => 'FIELD_${dim}RB_ARRAY',
          'super' => undef,
          'update_view' => 1
        };
EOF

	cat > types-fieldapi/FIELD_${dim}RM_ARRAY.pl << EOF
\$VAR1 = {
          'comp' => {
                      'P' => [
                               'F_P',
                               $((dim-1)),
                               'REAL(KIND=JPRM)'
                             ]
                    },
          'name' => 'FIELD_${dim}RM_ARRAY',
          'super' => undef,
          'update_view' => 1
        };
EOF


	cat > types-fieldapi/FIELD_${dim}RD_ARRAY.pl << EOF
\$VAR1 = {
          'comp' => {
                      'P' => [
                               'F_P',
                               $((dim-1)),
                               'REAL(KIND=JPRD)'
                             ]
                    },
          'name' => 'FIELD_${dim}RD_ARRAY',
          'super' => undef,
          'update_view' => 1
        };
EOF


	cat > types-fieldapi/FIELD_${dim}IM_ARRAY.pl << EOF
\$VAR1 = {
          'comp' => {
                      'P' => [
                               'F_P',
                               $((dim-1)),
                               'INTEGER(KIND=JPIM)'
                             ]
                    },
          'name' => 'FIELD_${dim}IM_ARRAY',
          'super' => undef,
          'update_view' => 1
        };
EOF



	cat > types-fieldapi/FIELD_${dim}LM_ARRAY.pl << EOF
\$VAR1 = {
          'comp' => {
                      'P' => [
                               'F_P',
                               $((dim-1)),
                               'LOGICAL'
                             ]
                    },
          'name' => 'FIELD_${dim}LM_ARRAY',
          'super' => undef,
          'update_view' => 1
        };
EOF

done
