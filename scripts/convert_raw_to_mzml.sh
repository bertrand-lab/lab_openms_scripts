# this script uses ThermoRawFileParser to convert the mass spec files from raw to mzml

DIR=$1

for FILE in $DIR*raw; do
    echo $FILE
    mono /var/www/sfolder/general/ThermoRawFileParser/ThermoRawFileParser.exe -i $FILE -o $DIR -f 1
done
