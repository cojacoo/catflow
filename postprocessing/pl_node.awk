#! /usr/bin/awk -f
BEGIN { rowcount=0  #suche Anfang ResultatAbschnit
          timecolcount=4
          timecol=1
          FS=" "
          row[0]=1	#row[0] muss kleiner= sein als row[1] usw.
          column[0]=3
          row[1]=1
          column[1]=4
          row[2]=3
          column[2]=4
          address=0
        }

NF==timecolcount { printf("\n" $timecol ";")
        rowcount=1
        address=0
}
NF!=timecolcount { while(row[address]==rowcount){
        printf($column[address] ";")
        address++
    }
    rowcount++
}