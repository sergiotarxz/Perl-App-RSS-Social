git submodule update --init --recursive
git clone https://github.com/pret/agbcc
cd agbcc
git clean -f
./build.sh
./install.sh ../pokefirered
cd ../pokefirered/
make -j6
