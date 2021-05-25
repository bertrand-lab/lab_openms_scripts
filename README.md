## OpenMS Bash Scripts for Doris

Here are a collection of scripts to do various things on Doris for proteomic database searching and quantification. This is a skeleton of what you can do, and always refer to the excellent [documentation](https://www.openms.de/getting-started/command-line-and-visualisations/), so always go back to there if there are questions! The main idea for this github repo is to be a skeleton, from which you can change settings to your preference. Each of these different bash scripts connects to each other, but you would have to manually run one and then manually run the next one. In the future, it would be great to wrap these together, and I think the best way to do that would be with [Snakemake](https://snakemake.readthedocs.io/en/stable/).

Note that some of these scripts assume a specific directory structure. You can always tweak the scripts for your own needs, but with this structure it should be easiest to run them (particularly for `feature-finder-general.sh`):

```
~\base-project-id
    \scripts
    \data
        \mzML-converted
```
 
Where `base-project-id` can be any name, and the bash scripts below are located in `scripts`.


### Converting your files

From the mass spec, your file format will likely be a .raw file. This can be converted using [ThermoRawFileParser](https://pubs.acs.org/doi/10.1021/acs.jproteome.9b00328). You can access this tool directly, or use the bash script `convert_raw_to_mzml.sh` to loop through a folder of .raw files and convert each one individually. If you wanted to use this bash script, run:

```
bash convert_raw_to_mzml.sh folder_with_raw_files/
```

In the example above, `folder_with_raw_files` has all your .raw files. Usually, we want a record of what you ran, and when. So I'd recommend you run this command 'in the background', like this:

```
nohup bash convert_raw_to_mzml.sh folder_with_raw_files/ > convert_to_raw_mzml.out &
```

This will convert your files to mzML, a common file format that is not proprietary. If you're interested in file formats used in proteomics, [there is a whole paper on them](https://www.mcponline.org/article/S1535-9476(20)33457-5/fulltext)

### Adding CRAP

There are contaminants in everything, and whenever we search our mass spectra against a database of protein sequences we should append a list of common contaminants. We've used this database called CRAP, which is saved on Doris.

You can append the CRAP database simply with this line:

```
cat /var/www/sfolder/general/crap.fasta protein_sequence_database.fasta > protein_sequence_database_with_crap.fasta
```

Or this can be written as a loop in a separate bash script if you are creating multiple databases.

### Removing redundant protein sequences

I've relied on this [great collection](https://github.com/pwilmart/fasta_utilities) of fasta processing scripts from P. Wilmarth. Specifically, I use the script `remove_duplicates.py` for removing duplicate sequences from my database prior to database searching. P. Wilmarth also has excellent documentation about proteomic data analysis in general, check out his github/twitter! 

For using this on Doris, I have the script `remove_duplicates.py` saved at this location: `/var/www/sfolder/general/`. There is a bash script that loops through using this python script for a set of fasta files if you need that (see `remove-duplicate-sequences.sh`).

### Database Searching with MSGF+

There are tonnes of database search engines. We have [MSGF+](https://www.nature.com/articles/ncomms6277) installed on Doris, which tends to work quite well and benchmarks well compared with other databases. This script (`database-searching-openms.sh`) conducts the database searching on a list of files. I'd recommend you write another separate script that uses this one as an input, like the following example: `database-searching-frag.sh`. Then you can run:

```
nohup bash database-searching-frag.sh > database-searching-frag.out &
```

This will run `database-searching-frag.sh` in the background, and you will have a record that you've run this script (your record is the `.out` file with the same name, you don't need it to be the same name but I find it helps to keep things organized). Within `database-searching-frag.sh` there is the core script, `database-searching-openms.sh`, which has two inputs. The first input is the sequence database, and the second input is the location of the mzML files. Note that you don't even need to use these bash scripts at all, and you could run each individual OpenMS command on Doris.

### Peptide/Protein Quantification

Once you've identified your peptides (matched spectra to peptides), you now might want to quantify each peptide. Generally, there are two main ways of quantifying peptides: spectral counting, and ion intensity quantification (XIC). Everybody has their own perspective on which is better, but for a lot of the MS methods we've run at the Proteomics Core Facility, I'd recommend using ion intensity quantification for several reasons, but to each their own. If you want to run spectral counting quant, you can do that simply with the `protein-quant-openms.sh` script, but you'll have to modify it because right now it loops through all files that are `featureXML`, and the input for spectral counting should be `.idXML`.

There are also several ways of doing XIC quant. I would recommend using `FeatureFinderIdentification`, which you can read all about [here](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5547443/). Before using this method, I'd highly recommend reading about it so you have some intuition of how and why it works so well. One area that needs to be more thoroughly investigated is it's use in metaproteomics, and more specifically how to determine which samples should be grouped. 

You need to designate samples to be grouped together (see the paper!). You can do that based on string matches -- i.e. all samples with the string 'Sample_1' can be grouped together. This grouping and quantification is done with the script `feature-finder-general.sh`. The inputs to this script are 1) location of the FDR-applied idXML data, 2) a string to append (can be left blank by just using empty quotes like this ''), 3) location of the mzML files, and 4) the grouping strings. 

If you have several grouping strings, you can write them like this:

```
bash feature-finder-general.sh '../fdr_idxml/' '' '../mzml_converted/' 'Sample_1' 'Sample_2' 'Sample_3'
``` 

Lets say you want to group sample 1 and 2 together, and not sample 3, then you could write:

```
bash feature-finder-general.sh '../fdr_idxml/' '' '../mzml_converted/' 'Sample_[1,2]' 'Sample_3'
```

I would recommend you write the above as a separate bash script, and then run it in the background. An example of this is given above (script name: `feature-finder-phyto-proteomes-phaeo.sh`).

Once you've conducted the peptide quant, you then want to output your results. This step uses the OpenMS function ProteinQuantifier. You can choose to output the peptide-level or protein-level quant, and I'd recommend reading about the assumptions that go into doing the protein-level quant. As above, the main script for doing this is `protein-quant-openms.sh`, but then I typically would write another script that just keeps a nice record of what I did, like `protein-quant-frag.sh`. Then, I would run:

```
nohup bash protein-quant-frag.sh > protein-quant-frag.out &
```

### After peptide quantification

This is the true wild-wild west. There are many directions you can go in -- are you looking at functional groupings? Taxonomic breakdown? Which level of taxonomic breakdown? So at this point you should decide on what exactly your question/approach is. There are some functions in [this](https://github.com/bertrand-lab/ross-sea-meta-omics/blob/main/scripts/post_processing_functions.R) script, which might help if you're using R to process your data.
