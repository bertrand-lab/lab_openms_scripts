# bash script for removing duplicate sequences from databases

for FILE in *fasta; do
    echo $FILE
    python /var/www/sfolder/general/remove_duplicates.py $FILE
done

