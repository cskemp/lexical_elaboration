## Mode of subsistence

Assign mode of subsistence (hunter-gatherer or non-hunter-gatherer) to all languages in BILA. We collected hunter-gatherer languages information from Cysouw and Comrie (2013), Guldemann et al. (2020), AUTOTYP, and D-Place (see `../rawdata/downloaded/README.md`).

We aimed to assign binary values--*hunter-gatherer* or *other* as dominant mode of subsistence--to each language in BILA. We first collated all information obtained from the above four sources (see `read_subsistence.R`). If different strategies were indicated for the same language as dominant mode of subsistence, we preferred Guldemann et al. (2020), and then Cysouw and Comrie (2013), and then D-Place to assign unique strategy for each language. After compiling subsistence strategy information in `../data/forpreprocessing/subsistence.csv`, we added them to the list of BILA dictionaries file by running `../preprocessing/create_bila_dictionaries.R`. For those languages with no information found, we automatically assigned *other*.




