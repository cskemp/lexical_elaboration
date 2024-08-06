import glob
import pandas as pd
import os
import re
import argparse

# Combine counts for all dictionaries into one file

def read_files(args):
    poscntdir = '../data/forpreprocessing/' + args.pos + '_counts_phase2/'
    poscntdir_nonht = '../data/forpreprocessing/' + args.pos + '_counts_phase2_nonhathi/'
    d_cntfiles = glob.glob(poscntdir + '*.csv') + glob.glob(poscntdir_nonht + '*.csv') 
    alldcounts_list = []

    for d_cntfile in d_cntfiles:
            dname = os.path.basename(d_cntfile)
            dname = re.sub("_top_.*freqs_phase2.csv", "", dname)
            # dname = re.sub(',', '.', dname)
            thisdcounts = pd.read_csv(d_cntfile, na_filter=False)
            thisdcounts.rename(columns={'lowercase': 'word'}, inplace=True)
            thisdcounts['id_sanitized'] = dname
            alldcounts_list.append(thisdcounts)
            print(dname)

    alldcounts = pd.concat(alldcounts_list, axis = 0, sort = True)
    alldcountsfile = '../data/forpreprocessing/dictionary_counts_' + args.pos + '.csv'
    with open(alldcountsfile, 'w') as f:
            alldcounts.to_csv(f, index=False)


def main():
    parser = argparse.ArgumentParser(description="Compile dictionary counts.")
    parser.add_argument("--pos", type=str, choices=['noun', 'verb', 'adj', 'nounverbadj'], required=True, help="POS tag: noun, verb, adj, or nounverbadj")
    args = parser.parse_args()
    read_files(args)

if __name__ == "__main__":
    main()
