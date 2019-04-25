#!/usr/bin/env bash
platform=$1

dirs=( bin kernel_bin kernel_bin/ioc64 kernel_bin/fpga kernel_bin/fpga/emulator kernel_bin/fpga/device kernel_bin/preprocessed logs/ioc64 logs/fpga logs/fpga/emulator logs/fpga/device )

mkdir -p ${dirs[*]}

function compilecl {
file="$1"
appendeds="$2"
buildopts="$3"
srcpath="device/$file.cl"
binpath=""

echo "Preprocess cl file"
binpath="kernel_bin/preprocessed/${file}_${appendeds}.cl"
cpp $buildopts -P $srcpath -o $binpath
srcpath=$binpath

echo "Compiling cl file $srcpath for platform $platform"
case $platform in
    ioc64)
        binpath="kernel_bin/ioc64/${file}_${appendeds}.ir"
        logpath="logs/ioc64/${file}_${appendeds}.txt"
        ioc64 -cmd=build -input="$srcpath" -ir="$binpath" -output="$logpath" -bo=\""$buildopts"\"
        ;;
    aoc_emulator)
        mkdir -p "kernel_bin/fpga/emulator/${file}_${appendeds}/"
	    binpath="kernel_bin/fpga/emulator/${file}_${appendeds}/${file}_${appendeds}"
        aoc -march=emulator "$srcpath" -o "$binpath" "$buildopts" > "logs/fpga/emulator/${file}_${appendeds}.txt"
        cp "$binpath.aocx" "kernel_bin/fpga/emulator/${file}_${appendeds}.aocx"
	    ;;
    aoc_report)
        mkdir -p "kernel_bin/fpga/device/${file}_${appendeds}/"
	    binpath="kernel_bin/fpga/device/${file}_${appendeds}/${file}_${appendeds}"
        aoc -rtl "$srcpath" -o "$binpath" "$buildopts" > "logs/fpga/device/${file}_${appendeds}.txt"
        if [ $? -eq 0 ]; then
            tar -cJf "reports/${file}_${appendeds}.tar.xz" "$binpath/reports"
            cat "$binpath/${file}_${appendeds}.log" | mail -s "${file}_${appendeds} report" -a "reports/${file}_${appendeds}.tar.xz" someone@example.com
        fi
        ;;
    aoc_binary_qsub)
        mkdir -p "kernel_bin/fpga/device/${file}_${appendeds}/"
        binpath="kernel_bin/fpga/device/${file}_${appendeds}/${file}_${appendeds}"
        qsub <<EOF
#!/bin/bash
#PBS -q skl
#PBS -V
#PBS -j oe
#PBS -l nodes=1:ppn=4
#PBS -l mem=24gb
#PBS -N "build_qsub_aoc_${file}_${appendeds}"
#PBS -m abe
#PBS -M someone@example.com

cd "\${PBS_O_WORKDIR}"
cat "" > "logs/fpga/device/${file}_${appendeds}.txt"
aoc "$srcpath" -o "$binpath" "$buildopts" |& tee -a "logs/fpga/device/${file}_${appendeds}.txt"
cp "$binpath.aocx" "kernel_bin/fpga/device/${file}_${appendeds}.aocx"
EOF
        ;;
    aoc_profile_binary_qsub)
        mkdir -p "kernel_bin/fpga/profiling/${file}_${appendeds}/"
        binpath="kernel_bin/fpga/profiling/${file}_${appendeds}/${file}_${appendeds}"
        qsub <<EOF
#!/bin/bash
#PBS -q skl
#PBS -V
#PBS -j oe
#PBS -l nodes=1:ppn=4
#PBS -l mem=24gb
#PBS -N "build_qsub_aoc_${file}_${appendeds}"
#PBS -m abe
#PBS -M someone@example.com

cd "\${PBS_O_WORKDIR}"
cat "" > "logs/fpga/device/${file}_${appendeds}.txt"
aoc --profile "$srcpath" -o "${binpath}" "$buildopts" |& tee -a "logs/fpga/device/${file}_${appendeds}.txt"
cp "$binpath.aocx" "kernel_bin/fpga/device/${file}_${appendeds}.aocx"
EOF
        ;;
    aoc_binary)
        mkdir -p "kernel_bin/fpga/device/${file}_${appendeds}/"
        binpath="kernel_bin/fpga/device/${file}_${appendeds}/${file}_${appendeds}"
        aoc "$srcpath" -o "$binpath" "$buildopts" > "logs/fpga/device/${file}_${appendeds}.txt"
        cp "$binpath.aocx" "kernel_bin/fpga/device/${file}_${appendeds}.aocx"
        ;;
    preprocessor)
        #handled above
        ;;
    *)
        echo "Invalid first argument"
        return -1
        ;;
esac
}

echo "This is the OpenCL build automation script. Please make sure to change the email addresses above to your own to receive reports and build job updates."

if [[ $# == 4 ]]
then
    compilecl "$2" "$3" "$4"
else

#Build commands go here

fi
exit
