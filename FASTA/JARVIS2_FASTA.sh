#!/bin/bash
#
HELP=0;
ABOUT=0;
DECOMPRESS=0;
INSTALL=0;
BLOCK="20MB";
THREADS="8";
#
################################################################################
#
SHOW_MENU () {
  echo " -------------------------------------------------------";
  echo "                                                        ";
  echo " JARVIS2, v1.0 - FASTA / Multi-FASTA Extension          ";
  echo "                                                        ";
  echo " Program options ---------------------------------------";
  echo "                                                        ";
  echo " -h, --help                   Show this,                ";
  echo " -a, --about                  Show program information, ";
  echo " -c, --install                Install/compile programs, ";
  echo "                                                        ";
  echo " -b <INT>, --block <INT>      Block size to be splitted,";
  echo " -t <INT>, --threads <INT>    Number of JARVIS2 threads,";
  echo "                                                        ";
  echo " -d, --decompress             Decompression mode,       ";
  echo "                                                        ";
  echo " Input options -----------------------------------------";
  echo "                                                        ";
  echo " -i <FILE>, --input <FILE>    Input FASTA filename.     ";
  echo "                                                        ";
  echo " Example -----------------------------------------------";
  echo "                                                        ";
  echo " ./JARVIS2_FASTA.sh --block 10MB -t 8 -i sample.fa      ";
  echo " ./JARVIS2_FASTA.sh --decompress -t 4 -i sample.fa.tar  ";
  echo "                                                        ";
  echo " -------------------------------------------------------";
  }
#
################################################################################
#
CHECK_INPUT () {
  FILE=$1
  if [ -f "$FILE" ];
    then
    echo "Input filename: $FILE"
    else
    echo -e "\e[31mERROR: input file not found!\e[0m";
    SHOW_MENU;
    exit;
    fi
  }
#
################################################################################
#
Program_installed () {
  # printf "Checking $1 ... ";
  if ! [ -x "$(command -v $1)" ];
    then
    echo -e "\e[41mERROR\e[49m: $1 is not installed." >&2;
    echo -e "\e[42mTIP\e[49m: Try: ./JARVIS2_FASTA.sh --install" >&2;
    exit 1;
    fi
  }
#
################################################################################
#
SHOW_HEADER () {
  echo "                                                        ";
  echo " [JARVIS2 :: FASTA Extension]                           ";
  echo "                                                        ";
  echo " Release year: 2021,                                    ";
  echo " Version: 1.0                                           ";
  echo " Author: D. Pratas                                      ";
  echo " Language: Bash / C                                     ";
  echo " License: GPL v3                                        ";
  echo "                                                        ";
  }
#
################################################################################
#
if [[ "$#" -lt 1 ]];
  then
  HELP=1;
  fi
#
POSITIONAL=();
#
while [[ $# -gt 0 ]]
  do
  i="$1";
  case $i in
    -h|--help|?)
      HELP=1;
      shift
    ;;
    -a|--about|--version)
      ABOUT=1;
      shift
    ;;
    -c|--install|--compile)
      INSTALL=1;
      shift
    ;;
    -d|--decompress|--uncompress|--decompression)
      DECOMPRESS=1;
      shift
    ;;
    -b|--block)
      BLOCK="$2";
      shift 2;
    ;;
    -t|--threads)
      THREADS="$2";
      shift 2;
    ;;
    -i|--input)
      INPUT="$2";
      shift 2;
    ;;
    -*) # unknown option with small
    echo "Invalid arg ($1)!";
    echo "For help, try: ./JARVIS2_FASTA.sh -h"
    exit 1;
    ;;
  esac
  done
#
set -- "${POSITIONAL[@]}" # restore positional parameters
#
################################################################################
#
if [[ "$HELP" -eq "1" ]];
  then
  SHOW_MENU;
  exit;
  fi
#
################################################################################
#
if [[ "$ABOUT" -eq "1" ]];
  then
  SHOW_HEADER;
  exit;
  fi
#
################################################################################
#
if [[ "$INSTALL" -eq "1" ]];
  then
  echo "Running installation ...";
  gcc bzip2.c -o bzip2
  g++ bbb.cpp -o bbb
  make;
  cd ../src/
  make
  cp JARVIS2 ../FASTA/
  cd ../FASTA
  echo "Done!"; 
  exit;
  fi
#
################################################################################
#
if [[ "$DECOMPRESS" -eq "0" ]];
  then
  # COMPRESSION
  #
  CHECK_INPUT "$INPUT";
  #
  Program_installed "./SplitFastaStreams";
  Program_installed "./bbb";
  Program_installed "./bzip2";
  Program_installed "./JARVIS2";
  #
  echo "Block size: $BLOCK";
  echo "Number of threads: $THREADS";
  echo "Compressing data ...";
  #
  ./SplitFastaStreams < $INPUT
  ./SplitDNA.sh "DNA.JV2" "$BLOCK" "$THREADS" &
  ./bbb cfm10q HEADERS.JV2 HEADERS.JV2.bbb &
  ./bzip2 -f EXTRA.JV2 &
  wait
  #
  tar -cvf $INPUT.tar DNA.JV2.tar EXTRA.JV2.bz2 HEADERS.JV2.bbb 1> .rep_out_enc
  #
  echo "Done!";
  ls -lah HEADERS.JV2.bbb | awk '{ print "HEADS:\t"$5; }'
  ls -lah DNA.JV2.tar | awk '{ print "DNA:\t"$5; }'
  ls -lah EXTRA.JV2.bz2 | awk '{ print "EXTRA:\t"$5; }'
  echo "------";
  ls -lah $INPUT.tar | awk '{ print "TOTAL:\t"$5; }'
  #
  rm -f DNA.JV2.tar EXTRA.JV2 HEADERS.JV2 .rep_out_enc
  #
  echo "Compressed file: $INPUT.tar";
  #
  else 
  # DECOMPRESSION:
  # 
  # Make sure file exits else die
  CHECK_INPUT "$INPUT";
  #
  Program_installed "./MergeFastaStreams";
  Program_installed "./bbb";
  Program_installed "./bzip2";
  Program_installed "./JARVIS2";
  #
  echo "Decompressing data ...";
  tar -xvf $INPUT 1> .rep_out_dec
  ./MergeDNA.sh "DNA.JV2.tar" "$THREADS" &
  ./bzip2 -d -f EXTRA.JV2.bz2 &
  ./bbb -fqd HEADERS.JV2.bbb HEADERS.JV2 &
  wait
  mv DNA.JV2.tar.out DNA.JV2
  ./MergeFastaStreams > $INPUT.out
  rm -f DNA.JV2.jc DNA.JV2.tar.out EXTRA.JV2.bz2 HEADERS.JV2.bbb .rep_out_dec
  echo "Done!";
  echo "Decompressed file: $INPUT.out";
  #
  fi
#
################################################################################
#
