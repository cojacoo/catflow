#! /usr/bin/awk -f
BEGIN { rowcount=1  #Ein zähler der pro Zeit einmal durchläuft (Tiefen)
	  timecolcount=4  #soviele einträge in der Zeitzeile
          timecol=1    #da steht die zeit
          FS=" "	#Field Separator ist space -> können mehrere sein
          ofs="\t"	#ausgabe Field Separator 
          eintrags_index=1	#zähler für felder zurücksetzen
	  row[1]=1	#diese felder will ich, hinter dem Gleichheitszeichen steht der Positionseintrags_index, Zeileneintrags_index muss aufsteigend sortiert sein
	  column[1]=27
	  row[2]=2
	  column[2]=27
	  row[3]=3
	  column[3]=27
	  row[4]=4
	  column[4]=27
	  row[5]=5
	  column[5]=27
	  row[6]=6
	  column[6]=27
	  row[7]=7
	  column[7]=27
	  row[8]=8
	  column[8]=27
	  row[9]=9
	  column[9]=27
	  row[10]=10
	  column[10]=27
	  row[11]=11
	  column[11]=27
        }

NF==timecolcount { printf("\n" $timecol ofs)
	rowcount=1
	eintrags_index=1
}
NF!=timecolcount { while(row[eintrags_index]==rowcount){
    	printf($column[eintrags_index] ofs)
	eintrags_index++
    }
    rowcount++
}

