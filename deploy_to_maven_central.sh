#!/bin/bash
# Deploy maven artefact in current directory into Maven central repository using maven-release-plugin goals

BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

set -e

argparse() {
    argparser=$(mktemp "/tmp/argparser.temp.XXXXXX")
    cat > "$argparser" <<EOF
import sys
import argparse
import os

class MyArgumentParser(argparse.ArgumentParser):
    def print_help(self, file=None):
        super(MyArgumentParser, self).print_help(file=file)
        sys.exit(1)

parser = MyArgumentParser(prog=os.path.basename("$0"))
EOF
    cat >> "$argparser"
    cat >> "$argparser" <<EOF
args = parser.parse_args()
for arg in [a for a in dir(args) if not a.startswith('_')]:
    print '{}="{}";'.format(arg.upper(), getattr(args, arg) or '')
EOF
    if python "$argparser" "$@" &> /dev/null; then
      eval $(python "$argparser" "$@")
      retval=0
    else
      python "$argparser" "$@"
      retval=1
    fi
    rm "$argparser"
    return $retval
}

argparse "$@" <<EOF || exit 1
parser.add_argument('--artifact', type=str, required=True, help='Artifact to deploy, e.g. ''sevntu-checks''')
EOF

if [ "$#" -eq 0 ]
then
  ./$0 --help
  exit 1
fi

read -p "Really deploy to maven central repository  (yes/no)? "

if ( [ "$REPLY" == "yes" ] ) then
  echo "Deploying $ARTIFACT to Maven Central ..."
  cd "$BASEDIR/$ARTIFACT"
  mvn release:clean release:prepare release:perform -B -e -DdryRun=true -Darguments="-Dmaven.test.skip=true -Dcobertura.skip=true -Dcheckstyle.skip=true" 
else
  echo 'Exit without deploy'
fi
