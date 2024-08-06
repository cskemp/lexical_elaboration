import sys
import regex
from collections import defaultdict
from operator import itemgetter
from tqdm import tqdm
import unicodedata

def read_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        # skip header
        return file.readlines()[1:]

lang_names_path = "../../data/forpreprocessing/language_names.csv"
lang_names = read_file(lang_names_path)

lang_names= [unicodedata.normalize('NFC', lang.strip()) for lang in lang_names]  # strip language names and normalize
lang_counts = {lang: 0 for lang in lang_names}  # Initialize language counters
lang_patterns = [regex.compile(r'(?w)\b{}\b'.format(regex.escape(lang)), regex.IGNORECASE) for lang in lang_names]

#f = open("/Users/ckemp/Downloads/hathitrust/hathi_full_20231101.txt", 'r', encoding = 'utf-8')
f = open("hathi_full_20231101.txt", 'r', encoding = 'utf-8')

titledict = defaultdict()
imprintdict = defaultdict()
datedict = defaultdict()
oclcdict = defaultdict()
lccndict = defaultdict()
enumerationdict = defaultdict()
accessdict = defaultdict()
rightsdict= defaultdict()

for line in tqdm(f):
    fields = [x.strip() for x in line.split('\t')]
    (volume, access, rights, title, imprint, pubdate, oclc, lccn, enumeration) = (fields[0], fields[1], fields[2], fields[11], fields[12], fields[16], fields[7], fields[10], fields[4])
    (volume, title, imprint, pubdate, oclc, lccn, enumeration) = (fields[0], fields[11], fields[12], fields[16], fields[7], fields[10], fields[4])
    title = unicodedata.normalize('NFC', title)
    if regex.search("ictionar", title): 
        if ( regex.search("uinea|ustrali|frica|acific|ceani|inguist|anguage|exico|ocabular|ialect", title) or 
             regex.search("uinea|ustrali|frica|acific|ceani|inguist|anguage|exico|ocabular|ialect|Mouton|Gruyter|of Hawa|Lincom|Köppe|Madras|California|ission", imprint) or
             any(pattern.search(title) for pattern in lang_patterns) ):
#        for pattern, lang in zip(lang_patterns, lang_names):
#            if pattern.search(title):
                titledict[volume] = title
                imprintdict[volume] = imprint 
                accessdict[volume] = access
                rightsdict[volume] = rights
                datedict[volume] = pubdate
                oclcdict[volume] =oclc 
                lccndict[volume] =lccn
                enumerationdict[volume] =enumeration
               # lang_counts[lang] += 1
f.close()

#print("Language Counts:")
#for lang, count in  sorted( lang_counts.items(), key=itemgetter(1), reverse=True):
#    print(f"{lang}: {count}")

fout = sys.stdout
fout.write("id\ttitle\tenumeration\timprint\tyear\toclc\tlcc\taccess\trights\n")
for k, v in sorted( datedict.items(), key=itemgetter(1), reverse=True):
    v = datedict[k]
    t = titledict[k]
    i = imprintdict[k]
    o = oclcdict[k]
    l = lccndict[k]
    e = enumerationdict[k]
    r = rightsdict[k]
    a = accessdict[k]
    fout.write("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" % (k, t, e, i, v, o, l, a, r))
