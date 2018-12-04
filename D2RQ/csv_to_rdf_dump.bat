REM CODE NEW
SET "d2rLocation=C:\JavaPrograms\d2rq-0.8.1\"
SET "baseResourceUrl=http://localhost:9999/blazegraph/DLRadiomics/"
REM SET "dataFile=radiomicslung2_data.ttl" 	# option A
SET "dataFile=radiomicslung2_data.nt"		# option B
SET "mappingFile=radiomicslung2_mapping.ttl"
SET "currentFolder=C:\Users\zhenwei.shi\Documents\PythonBasedDistributedLearning\Data_mapping\"

CD "%d2rLocation%"

# option A: for data with .ttl extension
REM CALL dump-rdf.bat --verbose -b "%baseResourceUrl%" -o "%currentFolder%%dataFile%" -f TURTLE "%currentFolder%%mappingFile%"

# option B: for data with .nt extension (much faster)
CALL dump-rdf.bat --verbose -b "%baseResourceUrl%" -o "%currentFolder%%dataFile%" -f N-TRIPLE "%currentFolder%%mappingFile%"

CD "%currentFolder%"