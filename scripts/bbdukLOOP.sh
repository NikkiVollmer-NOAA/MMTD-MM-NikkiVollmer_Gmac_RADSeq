#This is a Loop script that uses the "bbduk.sh" script (which comes with bbmap) and loops through all the fastq sequences. 
#Before running this bbdukLOOP.sh, is easiest to change the directory to where the fastq files are that you want to trim (can even put the LOOP script in same folder as the fastq files)
#IF the LOOP script is in a different directory need to include path to LOOP script to run it (e.g. nohup /Applications/bbmap/bbdukLOOP.sh &)
#On NLV MAC LOOP script is saved in bbmap folder in Applications
#After the "do" line need to map to where the bbduk.sh (so the LOOP script knows where to look for it)
#all flags are same as SNPsaurus used except trimq which I set to 20 to match what most people used in Trimmomatic and TrimGalore

#Code for running on NLV Mac
for i in `ls -1 *.fastq.gz | sed 's/.fastq.gz//'`
do
/Applications/bbmap/bbduk.sh -Xmx1g in=stdin.fastq.gz in1=$i\.fastq.gz out1=$i\_clean_fastq.gz ktrim=r k=17 hdist=1 mink=8 ref=/Applications/bbmap/resources/nextera.fa.gz minlen=100 ow=t qtrim=r trimq=20
done

#Code for running on Wanda, need to put LOOP script file in same place as all fastq files and run code from folder with fastq/LOOP script with "nohup ./bbdukLOOP.sh &"
for i in `ls -1 *.fastq.gz | sed 's/.fastq.gz//'`
do
/Genetics/bbmap/bbduk.sh -Xmx1g in=stdin.fastq.gz in1=$i\.fastq.gz out1=$i\_clean_fastq.gz ktrim=r k=17 hdist=1 mink=8 ref=/Genetics/bbmap/resources/nextera.fa.gz minlen=100 ow=t qtrim=r trimq=20
done
