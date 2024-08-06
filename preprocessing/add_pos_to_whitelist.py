import pickle
import pandas as pd
import re

pos = pickle.load(open("../data/forpreprocessing/wordpos.p", "rb"))

def checkpos(string, restring):
    return pos[string] != 0 and bool(re.match(restring, pos[string])) 

def assignpos(string):
    if checkpos(string, '^n'):
        return("noun")
    elif checkpos(string, '^n|^v|^j'):
        return("nounverbadj")
    else:
        return("missing")

df = pd.read_csv("../data/forpreprocessing/whitelist.txt", names = ['lowercase'])
df['pos'] = df['lowercase'].apply(assignpos)
#df = df[df['pos'] != 'missing']
df.to_csv('../data/forpreprocessing/whitelist_pos.csv', index=False)



