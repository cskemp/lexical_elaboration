
import argparse
from rdflib import Graph

def load_file(file_path):
    graph = Graph()
    print("name_type\tlabel")
    try:
        graph.parse(file_path, format='n3')
        for s, p, o in graph:
            #if str(p) == 'http://www.w3.org/2004/02/skos/core#altLabel' or \
            #    str(p) == 'http://www.w3.org/2000/01/rdf-schema#label':

            # handle entries with unmatched quotations
            o = o.replace('"', '')
            o = o.replace('“', '')
            o = o.replace('”', '')

            if str(o) != '':
                if str(p) == 'http://www.w3.org/2000/01/rdf-schema#label':
                    print("name\t" + str(o))
                elif str(p) == 'http://www.w3.org/2004/02/skos/core#altLabel':
                    print("altname\t" + str(o))   
    except FileNotFoundError:
        print(f"Error: File not found - {file_path}")

def main():
    #parser = argparse.ArgumentParser(description="Read language names from .n3 file.")
    #parser.add_argument("file_path", type=str, help="Path to the .n3 file")
    #args = parser.parse_args()
    #load_file(args.file_path)
    #load_file("/Users/ckemp/u/mygithub/lexical_elaboration/data/forpreprocessing/downloaded/glottolog_language.n3")
    #load_file("/Users/ckemp/u/mygithub/lexical_elaboration/rawdata/downloaded/glottolog_language.n3")
    load_file("../../rawdata/downloaded/glottolog_language.n3")

if __name__ == "__main__":
    main()
