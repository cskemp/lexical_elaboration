import argparse
import os
import re
from htrc_features import *
import pickle
import pandas as pd
import nltk


# Read raw dictionary data files
# Requires the htrc-feature-reader library: see https://github.com/htrc/htrc-feature-reader

# To run this on the full set of dictionaries, use parallel as follows:
# `find ../data/rawdata/*.json.bz2| parallel --eta --jobs 90% -n 50 python read_ht_file.py --phase 1 --pos "noun"`

# number of forms to keep for each dictionary
nperd = 1500

# drop all forms with COCA frequencies smaller than this value
mincounts = 400

# load part of speech tags and frequencies based on COCA (Corpus of Contemporary English)

pos = pickle.load(open("../data/forpreprocessing/wordpos.p", "rb"))
counts = pickle.load(open("../data/forpreprocessing/wordposcounts.p", "rb"))

engwordlist = set(nltk.corpus.words.words())
engworddict = dict.fromkeys(engwordlist, 1)

pattern = re.compile('[a-zA-Z-]+')

# strip punctuation from tokens (but keep internal hyphens)
def strip_punctuation(string):
    no_punct = ' '.join(pattern.findall(string))
    return(no_punct.lstrip('-').rstrip('-'))

# check that the word in string has the right part of speech and is above the frequency threshold
def checkpos(string):
    return pos[string] != 0 and len(string) > 2 and bool(re.match(restring, pos[string])) and counts[string] > mincounts

def check_english(string):
    return(string in engworddict) and len(string) > 2 
        
def check_token(string):
    return len(string) > 2

# check that the word is in our first phase vocabulary
def checkvocab(string):
    return (string in phase1_vocab) 

def read_files(args):
    global restring
    global phase1_vocab
    # if the restrings here change then add_pos_to_whitelist.py may also need to change
    if args.pos == 'noun':
        restring = '^n'
    elif args.pos == 'verb':
        restring = '^v'
    elif args.pos == 'adj':
        restring = '^j'
    elif args.pos == 'adv':
        restring = '^r'
    elif args.pos == 'nounverb':
        restring = '^n|^v'
    elif args.pos == 'nounverbadj':
        restring = '^n|^v|^j'
    elif args.pos == 'all':
        restring = '^'
    else:
        print('unknown type')

    if args.phase == 1: # keep top NPERD terms 
        phase1 = True
        outpref = '../data/forpreprocessing/' + args.pos + '_counts_phase1/'
        outsuff = '_top_' + str(nperd) + '_' + args.pos + '_freqs_phase1.csv'
    elif args.phase == 2: # keep all terms compiled in the first phase  
        phase1 = False
        outpref = '../data/forpreprocessing/' + args.pos + '_counts_phase2/'
        outsuff = '_top_' + str(nperd) + '_' + args.pos + '_freqs_phase2.csv'
        phase1_vocab  = pickle.load(open("../data/forpreprocessing/" + args.pos + "_vocab.p", "rb"))
    else:
        print("Invalid value for 'phase' argument. Use 1 to assemble vocab or 2 to create final files.")
        return

    if not os.path.exists(outpref):
        os.makedirs(outpref)

    for file_path in args.files:
        fname = os.path.basename(file_path.rstrip('/'))
        fname = os.path.splitext(fname.rsplit('.', 1)[0])[0]

        outfile = outpref + fname + outsuff
        #if os.path.exists(outfile):
        #    continue # skip files that have already been processed
        if not(os.path.exists(file_path)):
            print("**MISSING FILE: " + file_path)
            continue 
        try:
            vol = Volume(file_path)
            # print("%s - %s" % (vol.id, vol.title))
            # pages = False: combine all pages into one tokenlist
            # case = False: ignore lower/upper case
            # pos = False: don't include part of speech tags
            # section = "body": only include body of each page, not header/footer

            # df = vol.tokenlist(section="all", pages=True, case=False, pos=False)
            # df.to_csv("test.csv")

            df = vol.tokenlist(section="body", pages=False, case=False, pos=False)
            # drop the 'body' in multiindex
            df = df.xs('body', level='section').reset_index()

            if df.shape[0] < 1000:
                continue # dictionary too small

            df = df.sort_values('count', ascending=False)

            english_df = df.loc[df['lowercase'].apply(check_english)] 
            token_df = df.loc[df['lowercase'].apply(check_token)] 

            # strip punctuation and merge forms that become identical
            df['lowercase_nopunct'] = df['lowercase'].apply(strip_punctuation)
            df_m = df.groupby('lowercase_nopunct')['count'].agg('sum').reset_index()
            df_m = df_m.sort_values('count', ascending=False)
            df_m = df_m.rename(columns={'lowercase_nopunct': 'lowercase'})

            if phase1:
                pos_df = df_m.loc[df_m['lowercase'].apply(checkpos)] 
            else:
                pos_df = df_m.loc[df_m['lowercase'].apply(checkvocab)] 

            if pos_df.shape[0] == 0:
                all_count = 0
            else:
                all_count = sum(pos_df['count'])

            if all_count == 0:
                print("**  no tokens with correct POS for " + file_path)
                continue 

            nrow = pos_df.shape[0]
            # number of rows to keep
            if phase1:
                ntop = min(nperd, nrow)
            else:
                ntop = nrow
            top_df = pos_df.iloc[0:ntop]
            top_df = top_df.copy()

            newindex = top_df.index.max() + 1
            top_df.loc[newindex] = {'lowercase':'all_token_count_data', 'count':sum(token_df['count'])}
            top_df.loc[newindex + 1] = {'lowercase':'all_english_count_data', 'count':sum(english_df['count'])}
            top_df.loc[newindex + 2] = {'lowercase':'all_pos_count_data', 'count':all_count}

            top_df.to_csv(outfile, index = False)
        except:
            print("---- error processing " + file_path )

def main():
    parser = argparse.ArgumentParser(description="Read Hathi Trust file.")
    parser.add_argument("--phase", type=int, choices=[1, 2], required=True, help="1 to assemble vocab, 2 to make final counts")
    parser.add_argument("--pos", type=str, choices=['noun', 'verb', 'adj', 'nounverbadj'], required=True, help="POS tag: noun, verb, adj, or nounverbadj")
    parser.add_argument("files", nargs='+', help="Input feature files")
    args = parser.parse_args()
    read_files(args)

if __name__ == "__main__":
    main()
