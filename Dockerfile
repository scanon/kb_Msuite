FROM kbase/kbase:sdkbase.latest
MAINTAINER KBase Developer
# -----------------------------------------
# In this section, you can install any system dependencies required
# to run your App.  For instance, you could place an apt-get update or
# install line here, a git checkout to download code, or run any other
# installation scripts.

RUN apt-get install software-properties-common
RUN add-apt-repository ppa:avsm/ppa
RUN apt-get update
#RUN apt-get install ocaml ocaml-native-compilers camlp4-extra opam
RUN apt-get install libgsl0-dev

# Here we install a python coverage tool and an
# https library that is out of date in the base image.

RUN pip install coverage

# update security libraries in the base image
RUN pip install cffi --upgrade \
    && pip install pyopenssl --upgrade \
    && pip install ndg-httpsclient --upgrade \
    && pip install pyasn1 --upgrade \
    && pip install requests --upgrade \
    && pip install 'requests[security]' --upgrade

# install opam
RUN wget https://raw.github.com/ocaml/opam/master/shell/opam_installer.sh -O - | sh -s /usr/local/bin
RUN /usr/local/bin/opam init --comp 4.02.1 && \
    opam switch 4.03.0
RUN eval `opam config env` && opam update && \
    opam depext conf-pkg-config.1.0 && \
    opam install camlp4 ctypes ocp-indent ctypes-foreign ocamlfind
RUN opam repo add pplacer-deps http://matsen.github.com/pplacer-opam-repository
RUN opam update pplacer-deps


###### CheckM installation
#  Directions from https://github.com/Ecogenomics/CheckM/wiki/Installation#how-to-install-checkm
#System requirements
#
#CheckM is designed to run on Linux. The limiting requirement for CheckM is memory. Inference of lineage-specific marker sets using the full reference genome tree required approximately 40 GB of memory. However, a reduced genome tree (--reduced_tree) can also be used to infer lineage-specific marker sets which is suitable for machines with as little as 16 GB of memory. We recommend using the full tree if possible, though our results suggest that the same lineage-specific marker set will be selected for the vast majority of genomes regardless of the underlying reference tree. System requirements are far more modest if you plan to make use of taxonomic-specific marker sets or your own custom marker genes as this bypasses the need to place genomes in the reference genome tree.
#
#How to install CheckM
#
#CheckM requires the following programs to be added to your system path:
#
#HMMER (>=3.1b1)
#prodigal (2.60 or >=2.6.1)
#executable must be named prodigal and not prodigal.linux
#pplacer (>=1.1)
#guppy, which is part of the pplacer package, must also be on your system path
#pplacer binaries can be found on the pplacer GitHub page
#CheckM is a Python 2.x program and we recommend installing it through pip:
#
#> sudo pip install numpy
#> sudo pip install checkm-genome
#
#This will install CheckM and all other required Python libraries.
#
#CheckM relies on a number of precalculated data files. To install these run:
#
#> sudo checkm data update
#
#This will prompt you for an installation directory for the required data files. You can update the data files in the future by re-running this command. If you are unable to automatically download these files (e.g., you are behind a proxy), the files can be manually downloaded from https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_v1.0.7.tar.gz. Decompress this file to an appropriate folder and run checkm data setRoot <data_directory> to inform CheckM of where the files have been placed.
#
#CheckM is now ready to run. For a list of CheckM commands type:
#
#> checkm
#
#If desired, you can also download the latest release of CheckM and install it manually. CheckM makes use of the following Python libraries:
#
#python >= 2.7 and < 3.0
#numpy >= 1.8.0
#scipy >= 0.9.0
#matplotlib >= 1.3.1
#pysam >= 0.8.3
#dendropy >= 4.0.0
#ScreamingBackpack >= 0.2.3

#
#### OK, got that cleared up.  Now install CheckM, but not data
#


# Install HMMER
WORKDIR /kb/module
RUN \
  curl http://eddylab.org/software/hmmer3/3.1b2/hmmer-3.1b2-linux-intel-x86_64.tar.gz > hmmer-3.1b2-linux-intel-x86_64.tar.gz && \
  tar xvf hmmer-3.1b2-linux-intel-x86_64.tar.gz && \
  ln -s hmmer-3.1b2-linux-intel-x86_64 hmmer && \
  rm -f hmmer-3.1b2-linux-intel-x86_64.tar.gz && \
  cd hmmer && \
  ./configure && \
  make

# Install Prodigal
WORKDIR /kb/module
RUN \
  curl -s https://github.com/hyattpd/Prodigal/releases/download/v2.6.3/prodigal.linux > prodigal

# Install Pplacer
WORKDIR /kb/module
RUN \
  curl -s https://codeload.github.com/matsen/pplacer/tar.gz/v1.1.alpha19 > pplacer-1.1.alpha19.tar.gz && \
  tar -xvzf pplacer-1.1.alpha19.tar.gz && \
  ln -s pplacer-1.1.alpha19 pplacer && \
  rm -f pplacer-1.1.alpha19.tar  && \
  cd pplacer && \
  cat opam-requirements.txt | xargs opam install -y && \
  make all

# Install numpy, etc. (probably not necessary)
#WORKDIR /kb/module
#RUN \
#  pip install numpy
#  pip install scipy
#  pip install matplotlib
#  pip install pysam
#  pip install dendropy
#  pip install ScreamingBackpack

# Install CheckM
WORKDIR /kb/module
RUN \
  pip install checkm-genome


# TODO: install data to mount
RUN mkdir /data && \
    mkdir /data/checkm_data
# TODO: set data root


# -----------------------------------------

COPY ./ /kb/module
RUN mkdir -p /kb/module/work
RUN chmod -R a+rw /kb/module

WORKDIR /kb/module

RUN make all

ENTRYPOINT [ "./scripts/entrypoint.sh" ]

CMD [ ]
