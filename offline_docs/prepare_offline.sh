#!/bin/bash
#
# Accepted parameters:
#
# Version: Boundless Desktop's version (e.g. 1.0)

set -e

Version=$1
# Clean things up
rm -rf tmp  #Only use when a big clea up is needed
mkdir -p tmp
cd tmp
rm -rf output
mkdir output

# Getting Desktop documentation

if [ ! -d "desktop-documentation" ]; then
  git clone --recursive https://github.com/boundlessgeo/desktop-documentation.git;
fi

cd desktop-documentation;

case "$Version" in
	"1.0")
		git fetch origin r1.0;
		git checkout r1.0;
		git merge origin/r1.0;
		;;
	"1.1")
		git fetch origin r1.1;
		git checkout r1.1;
		git merge origin/r1.1;
		;;
	*)
		git checkout master;
		git pull origin master;
		;;
esac

git submodule update --recursive

cd installers

make text SPHINXOPTS="-t win"
cp build/text/README.txt ../docs/source/_static/README_win.txt
make text SPHINXOPTS="-t osx"
cp build/text/README.txt ../docs/source/_static/README_osx.txt

cd ../docs

echo "Setting up Desktop docs virtual enviornment..."

if [ -d "bdeskdocs_virtualenv" ]; then
   rm -rf bdeskdocs_virtualenv
fi

virtualenv bdeskdocs_virtualenv;
source bdeskdocs_virtualenv/bin/activate;
pip install -r requirements.txt;

rm -rf ../../output/desktop_doc
sphinx-build -b html -t offline -d build/doctrees   source ../../output/desktop_doc
deactivate
rsync -uthvr --delete build/ ../../output/desktop_doc

cd ../..
# Getting QGIS Core Documentation
if [ ! -d "QGIS-Documentation" ]; then
  git clone git@github.com:boundlessgeo/QGIS-Documentation.git;
fi
cd QGIS-Documentation;

rm -rf output;
git checkout -- .
case "$Version" in
	"1.0")
		git fetch origin manual_en_2.14;
		git checkout manual_en_2.14;
		git merge origin/manual_en_2.14;
		;;
	"1.1")
		git fetch origin release_2.18;
		git checkout release_2.18;
		git merge origin/release_2.18;
		;;
	"2.0")
		git fetch origin BD200_release;
		git checkout BD200_release;
		git merge origin/BD200_release;
		;;
	*)
		git checkout master;
		git pull origin master;
		;;
esac

echo "Setting up QGIS docs virtual enviornment..."

if [ -d "qgisdocs_virtualenv" ]; then
   rm -rf qgisdocs_virtualenv
fi

virtualenv qgisdocs_virtualenv;
source qgisdocs_virtualenv/bin/activate;
pip install -r REQUIREMENTS.txt;

# Exclude unwanted QGIS Documentation
#echo "Replacing conf.py file..."

#ARRAY=("training_manual" "developers_guide" "documentation_guidelines" "gentle_gis_introduction")

#for doc in ${ARRAY[*]}
#do
#  sed -i.bak "s|# exclude_patterns += \['docs/${doc}|exclude_patterns += \['docs/${doc}|g" source/conf.py;
#done
#
#sed -i.bak2 '/PDF/d' source/docs/index.rst;

make clean
make fasthtml
deactivate
rsync -uthvrq --delete output/ ../output/qgis_core_docs
#cd ..
#
##Put index Page in place
#cd ..
#rsync -uthvr _static/ tmp/output/_static
#cp index.html tmp/output
