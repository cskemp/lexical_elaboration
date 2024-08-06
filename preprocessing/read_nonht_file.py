import os
from collections import Counter
from pdfminer.high_level import extract_text
import pandas as pd
import pickle    
import re
import argparse
import nltk
from nltk.tokenize import word_tokenize
from docx import Document

# drop all forms with COCA frequencies smaller than this value
mincounts = 400

# load part of speech tags and frequencies based on COCA (Corpus of Contemporary English)
pos = pickle.load(open("../data/forpreprocessing/wordpos.p", "rb"))

counts = pickle.load(open("../data/forpreprocessing/wordposcounts.p", "rb"))

engwordlist = set(nltk.corpus.words.words())
engworddict = dict.fromkeys(engwordlist, 1)

# check that the word is in our first phase vocabulary
def checkvocab(string):
    return (string in phase1_vocab) 

def check_english(string):
    return(string in engworddict) and len(string) > 2 
        
def check_token(string):
    return len(string) > 2

# check that the word in string has the right part of speech and is above the frequency threshold
def checkpos(string):
    return pos[string] != 0 and len(string) > 2 and bool(re.match(restring, pos[string])) and counts[string] > mincounts

pattern = re.compile('[a-zA-Z-]+')

# strip punctuation from tokens (but keep internal hyphens)
def strip_punctuation(string):
    no_punct = ' '.join(pattern.findall(string))
    return(no_punct.lstrip('-').rstrip('-'))

def read_files(args):
    global phase1_vocab
    phase1_vocab  = pickle.load(open("../data/forpreprocessing/" + args.pos + "_vocab.p", "rb"))

    global restring
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

    outpref = '../data/forpreprocessing/' + args.pos + '_counts_phase2_nonhathi/'

    if not os.path.exists(outpref):
        os.makedirs(outpref)

    for file_path in args.files:
        fname = os.path.basename(file_path.rstrip('/'))
        fname = fname.rsplit('.', 1)[0]
        outsuff = '_top_1500_' + args.pos + '_freqs_phase2.csv'

        outfile = outpref + fname + outsuff
        if os.path.exists(outfile):
            return # skip files that have already been processed
        try:
            if file_path.endswith(".pdf"):
                # Extract text from the PDF
                pdf_text = extract_text(file_path)
                tokens = word_tokenize(pdf_text)
            elif file_path.endswith(".csv"):
                origdf = pd.read_csv(file_path)
                defns = origdf['Description'].apply(word_tokenize)
                tokens = [token for sublist in defns for token in sublist]
            elif file_path.endswith(".docx"):
                doc = Document(file_path)
                tokens = []
                for para in doc.paragraphs:
                    para_tokens = word_tokenize(para.text)
                    tokens.extend(para_tokens)

            all_tkns =  [token for token in tokens if check_token(token)]
            unigrams = [strip_punctuation(token.lower()) for token in tokens]
            english_tkns =  [token for token in unigrams if check_english(token)]
            all_pos =  [token for token in unigrams if checkpos(token)]
            
            # Calculate unigram frequencies
            unigram_freq = Counter(unigrams)

            df = pd.DataFrame.from_dict(unigram_freq, orient='index', columns=['count'])
            df.index.name = 'lowercase' 

            # Filter out unigrams that are not in the phase 1 vocabulary
            df = df[list(map(checkvocab, df.index))]

            df = df.sort_values('count', ascending=False).reset_index()

            newindex = df.index.max() + 1
            df.loc[newindex] = {'lowercase':'all_token_count_data', 'count':len(all_tkns)}
            df.loc[newindex + 1] = {'lowercase':'all_english_count_data', 'count':len(english_tkns)}
            df.loc[newindex + 2] = {'lowercase':'all_pos_count_data', 'count':len(all_pos)}

            # Create a CSV file for the unigram frequencies
            df.to_csv(outfile, index = False)
        except:
            print("---- error processing " + file_path)


def main():
    parser = argparse.ArgumentParser(description="Read Non Hathi Trust file.")
    parser.add_argument("--pos", type=str, choices=['noun', 'verb', 'adj', 'nounverbadj'], required=True, help="POS tag: noun, verb, adj, or nounverbadj")
    parser.add_argument("files", nargs='+', help="Input pdfs")
    args = parser.parse_args()
    read_files(args)

if __name__ == "__main__":
    main()
