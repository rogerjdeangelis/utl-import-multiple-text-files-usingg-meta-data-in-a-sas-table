Import multiple text files usingg meta data in a sas table;

    The Solutions

         a. using array macro
            To delete the array of macro variables created by '%array'
            %macro arraydelete(pfx)/des="Delete array macrovariables create by array macro";
              %do i= 1 %to &&&pfx.n;
                  %symdel &pfx&i;
              %end;
            %mend arraydelete;

         b. dosubl (packaged in a single datastep)

         c. filevar

github
https://tinyurl.com/rvls87k
https://github.com/rogerjdeangelis/utl-import-multiple-text-files-usingg-meta-data-in-a-sas-table

SAS Forum  (slight variation)
https://tinyurl.com/u86ch4y
https://communities.sas.com/t5/SAS-Programming/import-multiple-files-using-dates-in-a-data-set/m-p/614266

*_                   _
(_)_ __  _ __  _   _| |_
| | '_ \| '_ \| | | | __|
| | | | | |_) | |_| | |_
|_|_| |_| .__/ \__,_|\__|
        |_|
;

%let CurDay='01JAN2020'd;

data meta;
 do d=&curDay to intnx('month',&CurDay,0,'e');
  file=cats("d:/txt/offer",put(d,yymmddd10.),".txt");
  output;
  if index(file,'2020-01-03')>0 then stop;
 end;
 keep file;
run;quit;

WORK META total obs=3

Obs               FILE

 1     d:/txt/offer2020-01-01.txt
 2     d:/txt/offer2020-01-02.txt
 3     d:/txt/offer2020-01-03.txt


* create three timestamped files with cumulative sales;

data _null_;
  file "d:/txt/offer2020-01-01.txt"; put "CUM-JANUARY" +1 "$3,000";
  file "d:/txt/offer2020-01-02.txt"; put "CUM-JANUARY" +1 "$6,500";
  file "d:/txt/offer2020-01-03.txt"; put "CUM-JANUARY" +1 "$7,000";
run;quit;


Contents of three timestamped files

d:/txt/offer/2020-01-01.txt
  CUM-JANUARY $3,000

d:/txt/offer/2020-01-02.txt
  CUM-JANUARY $6,500

d:/txt/offer/2020-01-03.txt
  CUM-JANUARY $7,000

*            _               _
  ___  _   _| |_ _ __  _   _| |_
 / _ \| | | | __| '_ \| | | | __|
| (_) | |_| | |_| |_) | |_| | |_
 \___/ \__,_|\__| .__/ \__,_|\__|
                |_|
;


WORK.WANT total obs=3

Obs        CUM        SALES

 1     CUM-JANUARY     3000
 2     CUM-JANUARY     6500
 3     CUM-JANUARY     7000

*
  __ _      __ _ _ __ _ __ __ _ _   _
 / _` |    / _` | '__| '__/ _` | | | |
| (_| |_  | (_| | |  | | | (_| | |_| |
 \__,_(_)  \__,_|_|  |_|  \__,_|\__, |
                                |___/
;

* just in case;
%symdel files1 files2 files3 filesn / nowarn;

proc datasets lib=work nolist;
  delete want;
run;quit;

filename concat clear;

%array(files,data=meta,var=file);

filename concat ( %do_over(files,phrase="? ") );
data want;
   informat cum $12. sales dollar8.;
   infile concat;
   input cum sales;
run;quit;

* If you want to delete the array variables created by the array macro;
%macro arraydelete(pfx);
  %do i= 1 %to &&&pfx.n;
      %symdel &pfx&i;
  %end;
%mend arraydelete;

%arraydelete(files);

*_            _                 _     _
| |__      __| | ___  ___ _   _| |__ | |
| '_ \    / _` |/ _ \/ __| | | | '_ \| |
| |_) |  | (_| | (_) \__ \ |_| | |_) | |
|_.__(_)  \__,_|\___/|___/\__,_|_.__/|_|

;
* just in case;
%symdel file1 file2 file3 filen / nowarn;

proc datasets lib=work nolist;
  delete want;
run;quit;

data want;

   if _n_=0 then do; %let rc=%sysfunc(dosubl('
       proc sql;
          select file into :file1- from meta
       ;quit;
       %let filen=&sqlobs;
       '));
   end;

   informat cum $12. sales dollar8.;

   %do_over(file,phrase=%str(
     do until (fin);
        infile "?" end=fin;
        input cum sales;
        output;
     end;)
     ,between=%str(fin=0;))

run;quit;

*          __ _ _
  ___     / _(_) | _____   ____ _ _ __
 / __|   | |_| | |/ _ \ \ / / _` | '__|
| (__ _  |  _| | |  __/\ V / (_| | |
 \___(_) |_| |_|_|\___| \_/ \__,_|_|

;
* just in case;
proc datasets lib=work nolist;
  delete want;
run;quit;


data want;
   set meta;
   infile dummy filevar=file;
   informat cum $12. sales dollar8.;
   input cum sales;
run;quit;

or if more tyhan one record

data want;
   informat cum $12. sales dollar8.;
   set meta;
   do until (fin);
      infile dummy filevar=file end=fin;
      input cum sales;
      output;
   end;
   fin=0;
run;quit;


