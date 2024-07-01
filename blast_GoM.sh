#using BLAST to search for hits to GoM sequences

mamba activate bioinformatics #activate environment
cd ~/Desktop/AW/ #set current directory
ls #list directory contents

#run file of ASVs through BLAST global database with custom output------------------

#trying out on test file
blastn -db nt -remote -query test.fasta -out test_BLASTresults.tsv -outfmt "6 qseqid qlen sseqid staxids slen sstart send length pident evalue" 

#command for job script in Hydra
    #6 = put in table format, qseqid = query sequence ID, sacc = subject accession number, sscinames = subject scientific name, evalue = e-value, bitscore = bit score, pident = % of identical matches, qcovs = query coverage per subject
blastn -query /scratch/genomics/wooda2/edna/gomx-anth-edna/rep-seqs.fasta -db nt -out repseqsblast.out -max_target_seqs 10 -outfmt "6 qseqid sacc staxid sscinames evalue bitscore pident qcovs" -num_threads $NSLOTS

#removing duplicate sequence IDs from file we want to use as database
grep ">" cat_originalsponges.fasta | sort | uniq -c #find how many sequences there are for a sequence with a given ID
grep ">" cat_originalsponges.fasta | sort | uniq -d #find IDs of duplicated sequences 
#deleted duplicated sequences by hand from cat_originalsponges.fasta file

#make Allen's sponge sequences into a reference database to test GoM sequences against
makeblastdb -in cat_originalsponges.fasta -out spongedatabase -dbtype nucl -title SpongeRefSeqs -parse_seqids 

#run file of ASVs through reference database with custom output


