import argparse
import pandas as pd
from collections import defaultdict
import pickle

# Make dictionary with Phase one vocabulary and words on whitelist

def make_dict(args):
    outfile= '../data/forpreprocessing/nounverbadj_counts_phase1/' + args.pos + '_vocab.p'

    uk_us_file= '../rawdata/downloaded/uk_us_spelling.csv'
    uk_us= pd.read_csv(uk_us_file)
    whitelistfile= '../data/forpreprocessing/whitelist_pos.csv'
    whitelist = pd.read_csv(whitelistfile)  
    if args.pos == 'noun':
        whitelist = whitelist[whitelist['pos'] != 'nounverbadj']  # include cases with "missing" pos
    vocab = set()

    for file_path in args.files:
        d = pd.read_csv(file_path, na_filter=False)
        d_words = d['lowercase']
        vocab.update(d_words)

    vocab.update(whitelist['lowercase'])

    ukvocab = set()
    for word in vocab:
        sub_uk_us = uk_us[uk_us['US'] == word]
        ukvocab.update(sub_uk_us['UK'])

    vocab.update(ukvocab)
    vocab_dict = {word:1 for word in vocab}    

    pickle.dump( vocab_dict, open(outfile, "wb") )

def main():
    parser = argparse.ArgumentParser(description="Read Hathi Trust file.")
    parser.add_argument("--pos", type=str, choices=['noun', 'verb', 'adj', 'nounverbadj'], required=True, help="POS tag: noun, verb, adj, or nounverbadj")
    parser.add_argument("files", nargs='+', help="Input feature files")
    args = parser.parse_args()
    make_dict(args)

if __name__ == "__main__":
    main()
