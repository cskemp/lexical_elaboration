from collections import defaultdict 
import pickle

# w1cs_c.txt contains  
# "Single words occurring three times or more in the
#  Corpus of Contemporary American English (http://corpus.byu.edu/coca)
#  Case sensitive; with part of speech"

# It is not included in this repository but the citation is
# Davies, Mark. (2011) N-grams data from the Corpus of Contemporary American
# English (COCA). Downloaded from http://www.ngrams.info on January 09,
# 2012.

# change the file path
cocaf= open('C:/Users/tkhishigsure/OneDrive - The University of Melbourne/Documents/github/lexical_elaboration/rawdata/downloaded/w1cs_c.txt', 'r')

counts = defaultdict(int)
pos = defaultdict(int)


for _ in range(14):
  next(cocaf)

for line in cocaf:
  fields = line.rstrip("\r\n").split('\t')
  if not(fields[1] in counts) or counts[fields[1]] < int(fields[0]): 
    counts[fields[1]] = int(fields[0])
    pos[fields[1]] = fields[2]

pickle.dump( pos, open("../data/forpreprocessing/wordpos.p", "wb") )
pickle.dump( counts, open("../data/forpreprocessing/wordposcounts.p", "wb") )



