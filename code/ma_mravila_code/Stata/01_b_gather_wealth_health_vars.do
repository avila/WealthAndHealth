*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** MA: The health-wealth nexus over the life cycle
*** Au: Marcelo Rainho Avila (4679876)
*** Dt: 07.02.2024
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# 1) gather HEALTH data
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cap log close _all
log using $log/tmp/01_b_gather_wealth_health_vars.log, text replace


* 1.1) from pl.dta
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

global health_vars_in_pl /// 
plb0024_h      /// Krankgemeldet ueber 6 Wochen Vorjahr [harmonisiert]          | 1985,1986,1987,1988,1989,1991,1992,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plb0024_v1     /// Laenger als 6 Wochen krankgemeldet ja/nein  [1985-1989,1991- | 1985,1986,1987,1988,1989,1991,1992,1994,1995,1996,1997,1998
plb0024_v2     /// Wie oft ueb.6 Wochen arbeitsunfaehig  [1985-1989,1991-1992,1 | 1985,1986,1987,1988,1989,1991,1992,1994,1995,1996,1997,1998
plb0024_v3     /// Laenger als 6 Wochen krank gemeldet  [1999-2019]             | 1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plc0567        /// Beitragsschulden Krankenkasse                                | 2017
ple0004        /// Gesundheitszustand beeintr. Treppen steigen                  | 2002,2004,2006,2008,2010,2012,2014,2016,2017,2018,2019
ple0005        /// Gesundheitszustand beeintr. Anstreng. Taetigkeiten           | 2002,2004,2006,2008,2010,2012,2014,2016,2017,2018,2019
ple0006        /// Koerpergroesse in cm                                         | 2002,2004,2006,2008,2010,2012,2014,2016,2018
ple0007        /// Koerpergewicht in kg                                         | 2002,2004,2006,2008,2010,2012,2014,2016,2018
ple0008        /// Gesundheitszustand gegenwaertig                              | 1992,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0009        /// Einschraenkg.im Alltgasleben wg. gesundheitl. Probleme       | 2011,2012,2013,2015,2016,2017,2018,2019
ple0011        /// Schlafstoerung                                               | 2011,2013,2015,2017,2019
ple0012        /// Diabetes                                                     | 2009,2011,2013,2015,2017,2019
ple0013        /// Asthma                                                       | 2009,2011,2013,2015,2017,2019
ple0014        /// Herzkrankheit                                                | 2009,2011,2013,2015,2017,2019
ple0015        /// Krebserkrankung                                              | 2009,2011,2013,2015,2017,2019
ple0016        /// Schlaganfall                                                 | 2009,2011,2013,2015,2017,2019
ple0017        /// Migraene                                                     | 2009,2011,2013,2015,2017,2019
ple0018        /// Bluthochdruck                                                | 2009,2011,2013,2015,2017,2019
ple0019        /// Depressive Erkrankung                                        | 2009,2011,2013,2015,2017,2019
ple0020        /// Demenzerkrankung                                             | 2009,2011,2013,2015,2017,2019
ple0021        /// Gelenkerkrankungen (auch Arthrose, Rheuma)                   | 2011,2013,2015,2017,2019
ple0022        /// Chronische Rueckenbeschwerden                                | 2011,2013,2015,2017,2019
ple0023        /// Sonstige Krankheit                                           | 2009,2011,2013,2015,2017,2019
ple0024        /// Keine Krankheit festgestellt                                 | 2009,2011,2013,2015,2017,2019
ple0026        /// Eile, Zeitdruck letzten 4 Wochen                             | 2002,2004,2006,2008,2010,2012,2014,2016,2017,2018,2019
ple0027        /// Niedergeschlagen letzten 4 Wochen                            | 2002,2004,2006,2008,2010,2012,2014,2016,2017,2018,2019
ple0028        /// Ausgeglichen letzten 4 Wochen                                | 2002,2004,2006,2008,2010,2012,2014,2016,2017,2018,2019
ple0029        /// Energie letzten 4 Wochen                                     | 2002,2004,2006,2008,2010,2012,2014,2016,2017,2018,2019
ple0030        /// Koerperliche Schmerzen letzten 4 Wochen                      | 2002,2004,2006,2008,2010,2012,2014,2016,2017,2018,2019
ple0031        /// Weniger geschafft wg. koerperlicher Probleme                 | 2002,2004,2006,2008,2010,2012,2014,2016,2017,2018,2019
ple0032        /// Inhaltliche Einschraenkung wg. koerperlicher Probleme        | 2002,2004,2006,2008,2010,2012,2014,2016,2017,2018,2019
ple0033        /// Weniger geschafft wg. seelischer Probleme                    | 2002,2004,2006,2008,2010,2012,2014,2016,2017,2018,2019
ple0034        /// Weniger Sorgfalt wg. seelischer Probleme                     | 2002,2004,2006,2008,2010,2012,2014,2016,2017,2018,2019
ple0035        /// Einschraenkung sozialer Kontakte wg. Gesundheit              | 2002,2004,2006,2008,2010,2012,2014,2016,2017,2018,2019
ple0036        /// Leiden unter chronischen Krankheiten                         | 1984,1985,1986,1987,1988,1989,1991,2009,2010,2011,2012,2013,2014,2016,2018
ple0040        /// Erwerbs-, Schwerbehinderung                                  | 1984,1985,1986,1987,1988,1989,1991,1992,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0041        /// Behinderungsgrad in Prozent                                  | 1984,1985,1986,1987,1988,1989,1991,1992,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0044_h      /// Wegen Krankheit nicht gearbeitet Vorjahr [harmonisiert]      | 1985,1986,1987,1988,1989,1991,1992,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0044_v1     /// Keinen Tag gefehlt wegen Krankheit (unregelmaessig) [1985-20 | 1985,1987,1988,1989,1991,1992,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0044_v2     /// Keinen Tag krankgeschrieben  [1986]                          | 1986
ple0046        /// Wegen Krankheit nicht gearbeitet Vorjahr, Tage               | 1985,1986,1987,1988,1989,1991,1992,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0048        /// Wegen Krankheit des Kindes nicht gearbeitet                  | 2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0049        /// Anzahl Tage wegen Krankh. Kind nicht gearbeitet              | 2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0050        /// Aus anderen Gruenden nicht gearbeitet                        | 2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0051        /// Anzahl Tage aus anderen Gruenden nicht gearbeitet            | 2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0052        /// Keine Fehltage aus persoenlichen Gruenden                    | 2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0053        /// Krankenhausaufenthalt Vorjahr                                | 1984,1985,1986,1987,1988,1989,1991,1992,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0055        /// Krankenhausaufenthalt Vorjahr Anzahl                         | 1984,1985,1986,1987,1988,1989,1991,1992,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0056        /// Krankenhausaufenthalt Vorjahr Naechte                        | 1984,1985,1986,1987,1988,1989,1991,1992,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0072        /// Arztbesuche Anzahl                                           | 1988,1989,1991,1992,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0073        /// Arztbesuche Keine                                            | 1984,1985,1986,1987,1988,1989,1991,1992,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0080_v1     /// Tabakkonsum-Art  [1998]                                      | 1998
ple0080_v2     /// Raucher  [1999,2001]                                         | 1999,2001
ple0080_v3     /// Jemals Geraucht  [2002,2012]                                 | 2002,2012
ple0081_h      /// Rauchen gegenwaertig [harmonisiert]                          | 2002,2004,2006,2008,2010,2012,2014,2016,2018
ple0081_v1     /// Rauchen gegenwaertig  [2002,2012]                            | 2002,2012
ple0081_v2     /// Rauchen gegenwaertig (unregelmaessig) [2004-2018]            | 2004,2006,2008,2010,2014,2016,2018
ple0082        /// Alter b. Beginn Rauchen                                      | 2002,2012
ple0083        /// Kein regelm. Raucher                                         | 2002,2012
ple0084        /// Ende Rauchen Jahr                                            | 2002,2012
ple0085        /// Ende Rauchen Monat                                           | 2002,2012
ple0086_v1     /// Anzahl Zigaretten, Zigarren etc. Tag  [1998,2001]            | 1998,2001
ple0086_v2     /// Rauchen: Anzahl Zigaretten pro Tag (unregelmaessig) [2002-20 | 2002,2004,2006,2008,2010,2012,2014,2016,2018
ple0086_v3     /// Rauchen: Anzahl Pfeifen pro Tag (unregelmaessig) [2002-2018] | 2002,2004,2006,2008,2010,2012,2014,2016,2018
ple0086_v4     /// Rauchen: Anzahl Zigarren pro Tag (unregelmaessig) [2002-2018 | 2002,2004,2006,2008,2010,2012,2014,2016,2018
ple0089        /// Rauchen: Gesamt k.A.                                         | 
ple0090        /// Genuss alkoholischer Getraenke: Bier                         | 2006,2008,2010
ple0091        /// Genuss alkoholischer Getraenke: Wein, Sekt                   | 2006,2008,2010
ple0092        /// Genuss alkoholischer Getraenke: Spirituosen                  | 2006,2008,2010
ple0093        /// Genuss alkoholischer Getraenke: Mischgetraenke               | 2006,2008,2010
ple0097        /// Art der Krankenversicherung                                  | 1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0098_v1     /// Private Krankenversicherung  [1984-1986]                     | 1984,1985,1986
ple0098_v2     /// Private Krankenversicherung (Vollversicherung oder Zusatzver | 1987,1988,1989,1990,1991,1992,1993,1994,1995
ple0098_v3     /// Private Vollversicherung  [1996-1998]                        | 1996,1997,1998
ple0098_v4     /// Private Zusatzversicherung  [1996-1998]                      | 1996,1997,1998
ple0098_v5     /// Private Zusatzversicherung (Ja/Nein)  [1999-2008,2010-2014,2 | 1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2010,2011,2012,2013,2014,2016,2018
ple0099_h      /// Versichertenstatus [harmonisiert]                            | 1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0099_v1     /// Versichertenstatus - Beitragszahlendes Pflichtmitglied  [198 | 1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998
ple0099_v2     /// Versichertenstatus - Beitragszahlendes freiwilliges Mitglied | 1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998
ple0099_v3     /// Versichertenstatus - Vers. als Rentner, Arbeitsloser, Studen | 1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998
ple0099_v4     /// Versichertenstatus - Mitversichertes Familienmitglied  [1984 | 1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998
ple0099_v5     /// Versichertenstatus  [1999-2019]                              | 1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0104_h      /// Welche Krankenversicherung erst ab 1999 [harmonisiert]       | 1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0104_v1     /// Krankenversicherung - Allgemeine Ortskrankenkasse  [1984-199 | 1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998
ple0104_v2     /// Krankenversicherung - Ersatzkasse  [1984-1998]               | 1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998
ple0104_v3     /// Krankenversicherung - Betriebskrankenkasse  [1984-1998]      | 1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998
ple0104_v4     /// Krankenversicherung - Innungskrankenkasse  [1984-1998]       | 1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998
ple0104_v5     /// Krankenversicherung - Sonstige Krankenversicherung  [1984-19 | 1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998
ple0104_v6     /// Name der ges.Krankenvers.  [1999]                            | 1999
ple0104_v7     /// Name der ges.Krankenvers.  [2000-2009]                       | 2000,2001,2002,2003,2004,2005,2006,2007,2008,2009
ple0121        /// Beihilfeanspruch                                             | 1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011
ple0128_h      /// Beitrag fuer private Zusatzkrankenversicherung [harmonisiert | 1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2010,2011,2012,2013,2014,2016,2018
ple0128_v1     /// Beitrag fuer priv ZusVersicherung (DM)  [1999-2001]          | 1999,2000,2001
ple0128_v2     /// Mon. Beitrag priv. Zusatzkrankenvers. (Euro)  [2002-2008,201 | 2002,2003,2004,2005,2006,2007,2008,2010,2011,2012,2013,2014,2016,2018
ple0129        /// Beitrag fuer private Zusatzkrankenversicherung unbekannt     | 1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2010,2011,2012,2013,2014,2016,2018
ple0130        /// Krankenhausbehandlung abgedeckt                              | 1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2010,2011,2012,2013,2014,2016,2018
ple0131        /// Zahnersatz abgedeckt                                         | 1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2010,2011,2012,2013,2014,2016,2018
ple0132        /// Heil-,Hilfsmittel abgedeckt                                  | 1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2010,2011,2012,2013,2014,2016,2018
ple0133        /// Auslandsaufenthalt abgedeckt                                 | 1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2010,2011,2012,2013,2014,2016,2018
ple0134        /// Sonstige Leistungen abgedeckt                                | 1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2010,2011,2012,2013,2014,2016,2018
ple0160        /// Kassenwechsel in Vorjahr                                     | 1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
ple0162        /// Gesundheitliche Probleme laenger als halbes Jahr             | 2012,2013,2015,2016,2017,2018,2019
ple0174        /// Nicht gearbeitet wg. Pflege eines Angeh. Vorjahr             | 2015,2016,2017,2018,2019
ple0175        /// Anz. Fehltage wg. Pflege eines Angeh. Vorjahr                | 2015,2016,2017,2018,2019
ple0176        /// E-zigarette                                                  | 2016,2018
ple0177        /// Wie oft Alkohol                                              | 2016
ple0178        /// Wie viel Alkohol                                             | 2016
ple0179        /// Wie oft Fleisch                                              | 2016,2018
ple0180        /// Wie oft Fisch                                                | 2016,2018
ple0181        /// Wie oft Gefluegel                                            | 2016,2018
ple0182        /// Vegetarische oder vegane Ernaehrung                          | 2016,2018
ple0183        /// Private pflegezusatzversicherung                             | 2016,2018
ple0184        /// Beitrag fuer private Pflegezusatzversicherung pro Monat      | 2016,2018
ple0185        /// Beitrag fuer private Pflegezusatzversicherung: Weiss nicht   | 2016,2018
ple0186        /// IGel - individuelle Gesundheitsleistungen, Vorjahr           | 2016,2018
plh0182        /// Lebenszufriedenheit gegenwaertig                             | 1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plh0171        /// Zufriedenheit Gesundheit                                     | 1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plh0172        /// Zufriedenheit Schlaf                                         | 2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plh0173        /// Zufriedenheit Arbeit                                         | 1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plh0174        /// Zufriedenheit HH-Taetigk.                                    | 1984,1985,1986,1987,1988,1989,1990,1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plh0175        /// Zufriedenheit HH-Einkommen                                   | 1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plh0176        /// Zufriedenheit mit persoenlichem Einkommen                    | 2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plh0177        /// Zufriedenheit Wohnung                                        | 1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plh0178        /// Zufriedenheit Freizeit                                       | 1984,1985,1986,1987,1988,1989,1991,1992,1993,1994,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plh0179        /// Zufriedenheit Kinderbetreuung                                | 1990,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plh0180        /// Zufriedenheit Familienleben                                  | 2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plh0182        /// Lebenszufriedenheit gegenwaertig                             | 1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plh0164        /// Zufriedenh. Schul- und Berufsausbildung                      | 1989,1993,2000,2004,2008,2014,2019
plh0184        /// Haeufigkeit aergerlich letzte 4 Wochen                       | 2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plh0185        /// Haeufigkeit aengstlich letzte 4 Wochen                       | 2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plh0186        /// Haeufigkeit gluecklich letzte 4 Wochen                       | 2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plh0187        /// Haeufigkeit traurig letzte 4 Wochen                          | 2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019
plh0334        /// Taetigkeit im Leben wertvoll und nuetzlich                   | 2015,2016,2017,2018,2019
plh0204_v2     /// Persoenliche Risikobereitschaft  [2004,2006,2008-2019]       | 2004,2006,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019

use pid syear $health_vars_in_pl if syear >= 2002 using $soep_data/pl.dta, clear
if 0 lluse $health_vars_in_pl

merge 1:1 pid syear using $soep_data/ppathl.dta, keepus(psample /* phrf */ gebjahr erstbefr) keep(3) gen(_mg_pl_ppathl)
mvdecode _all, mv(-1 = .a \ -2 = .b \ -3 = .c \ -4 = .d \ -5 = .e \ -6 = .f \ -7 = .g \ -8 = .h) 
xtset pid syear, yearly delta(1)

save $temp/pl_miss.dta, replace
if 0 use $temp/pl_miss.dta, clear 
desc, short
desc $health_vars_in_pl

// check if variable is good
global list_of_good_vars_conti = ""
global list_of_good_vars_categ = ""
foreach var of global health_vars_in_pl {
    qui levels_valid `var' 
    // search for variables that include years 2011, 12 OR 13 AND 2017, 18 or 19. 
    if ustrregexm("`r(levels)'", "(2011|2012).*(2018|2019|2020)") {
    
        local lab: variable label `var'
        di as res  "Var: `var'; `lab'"
        di as text "`r(levels)'"
        qui distinct `var'
        if `r(ndistinct)' > 50 {
            global list_of_good_vars_conti "$list_of_good_vars_conti `var'"
        }
        else {
            global list_of_good_vars_categ "$list_of_good_vars_categ `var'"
        }
    }
}


macro list list_of_good_vars_categ list_of_good_vars_conti
/* 
list_of_good_vars_categ:
    plb0024_h plb0024_v3 ple0004 ple0005 ple0008 ple0009 ple0011 ple0012 ple0013 ple0014 ple0015 ple0016 ple0017 ple0018
    ple0019 ple0020 ple0021 ple0022 ple0023 ple0024 ple0026 ple0027 ple0028 ple0029 ple0030 ple0031 ple0032 ple0033
    ple0034 ple0035 ple0036 ple0040 ple0044_h ple0044_v1 ple0048 ple0050 ple0052 ple0053 ple0055 ple0073 ple0081_h
    ple0086_v3 ple0086_v4 ple0097 ple0098_v5 ple0099_h ple0099_v5 ple0104_h ple0129 ple0130 ple0131 ple0132 ple0133
    ple0134 ple0160 ple0162 plh0182 plh0171 plh0172 plh0173 plh0174 plh0175 plh0176 plh0177 plh0178 plh0179 plh0180
    plh0182 plh0184 plh0185 plh0186 plh0187 plh0204_v2

list_of_good_vars_conti:
    ple0006 ple0007 ple0041 ple0046 ple0049 ple0051 ple0056 ple0072 ple0086_v2 ple0128_h ple0128_v2
*/

di `: word count $list_of_good_vars_categ' // 73 variables
desc $list_of_good_vars_categ

di `: word count $list_of_good_vars_conti' // 11 variables
desc $list_of_good_vars_conti

/* list of variables with concrete diagnoses */
global vars_diagnosed ple0011 ple0012 ple0013 ple0014 ple0015 ple0016 ple0017 ple0018 ple0019 ple0020 ple0021 ple0022 ple0023 ple0024
desc $vars_diagnosed

lab language EN
save $temp/pl_before_final_sample.dta, replace
if 0 use $temp/pl_before_final_sample.dta, clear 
desc, short


/* foreach var of varlist ple0011-ple0024 {
    /* 
    generate binary if ever got diagnosed with X disease.
    note: var_cumsum shows that people tend to switch back to no disease quite a lot
    */
    
    di 120 * "~" 
    di "VAR: `var' `: variable label `var'' " 

    cap drop `var'_*
    bysort pid (syear) : gen int `var'_cumsum = sum(`var')
    order `var'_cumsum, after(`var')
    gen int `var'_ever = `var'_cumsum >= 1, after(`var'_cumsum)

    bysort pid (syear): gen `var'_change = `var'_ever != `var'_ever[_n-1] & _n > 1
    order `var'_change, after(`var'_ever)
    egen `var'_change_ever = max(`var'_change), by(pid)
    order `var'_change_ever, after(`var'_change)

    /* copy label to new variable */
    local lab : variable label `var'
    local newlab "`lab' (`var')"
    label variable `var'_ever "`newlab'"

    /* check output */
    *tab syear `var'_ever if _keep_all == 1, m
    tab syear `var'_cumsum if _keep_all == 1,m 
}
 */

* check missings 
* ~~~~~~~~~~~~~~

foreach var of varlist $list_of_good_vars_conti $list_of_good_vars_categ {
    local lab: variable label `var'
    di 220 * "~" _n
    di as res  "Var: `var'; `lab'" 
    //levels_valid `var' 
    foreach year of numlist 2011(2)2019 {
    //foreach year of numlist 2002(5)2017 2019 {
        di "year: `year'"
        qui count if syear == `year'

        local N_year = `r(N)'
        qui count if `var'==.a & syear==`year'
        scalar share = round(r(N)/`N_year', 0.0001) 

        di "miss: `r(N)' / total: `N_year' / share miss: `=share'" 
        if `=share'>0.05 di "!!! more than 5% missing !!!!!!"
        assert `=share'<0.07
    }
}

/* if $do_checks {
    cls
    format $vars_diagnosed %9.0g
    list pid syear ple0011-ple0015 in 1/1000, sepby(pid) head(50)
    list pid syear ple0016-ple0020 in 1/1000, sepby(pid) head(50)
    list pid syear ple0021-ple0024 in 1/1000, sepby(pid) head(50)
    /* shows that generation of "_ever" and "_change" is fine */
}  

if $do_checks {
    // sum individual changes (==1 for each change)
    sum *_change
    // sum ever changes (==1 per id)
    sum *_change_ever
}
 */

* What about the concrete diseases? 
* Q147 in 2019: Hat ein Arzt bei Ihnen jemals eine oder mehrere der folgenden Krankheiten festgestellt? 
* -> only available in odd years after 2009!
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/* list of variables with concrete diagnoses */
/* global vars_diagnosed_ever ple0011_ever ple0012_ever ple0013_ever ple0014_ever ple0015_ever ple0016_ever ple0017_ever ///
    ple0018_ever ple0019_ever ple0020_ever ple0021_ever ple0022_ever ple0023_ever ple0024_ever


tabstat $vars_diagnosed_ever, by(syear) stat(mean)
 *//* Fri  6 Aug 16:40:44 CEST 2021
    syear |  ~11_ever  ~12_ever  ~13_ever  ~14_ever  p~5_ever  p~6_ever  p~7_ever  p~8_ever  p~9_ever  p~0_ever  ~21_ever  ~22_ever  ~23_ever  ~24_ever
----------+--------------------------------------------------------------------------------------------------------------------------------------------
     2011 |    .08999  .0799279  .0533485  .0952584  .0453747  .0206464  .0555318   .248849  .0598984  .0030376  .1973041  .1758508  .1394466  .3887228
     2013 |  .1321142  .0969463  .0708634  .1243772   .064709  .0254967  .0829377  .3213176  .0903816  .0048649  .2683899  .2433034  .2152863  .4593517
     2015 |  .1590376  .1050198  .0826352  .1443603  .0777428   .030695  .0980497  .3580859  .1123919  .0060318  .3131828  .2811474  .2668722  .5000335
     2017 |   .186577  .1104925  .0927859  .1592051  .0889198  .0360319  .1112658  .3896234  .1286631  .0061084   .350576  .3071213  .3123019  .5212248
     2019 |  .2055873    .11934  .1042467  .1738071  .0989969  .0417174  .1228087  .4165182  .1442767  .0084372  .3853942  .3310209  .3579263  .5324834
----------+--------------------------------------------------------------------------------------------------------------------------------------------
    Total |  .1451905   .099242  .0766852  .1330185  .0707884  .0292103  .0886746   .333329  .1002466  .0052967  .2877197  .2551043  .2407014   .468474
------------------------------------------------------------------------------------------------------------------------------------------------------- */
 */

global vars_diagnosed ple0011 ple0012 ple0013 ple0014 ple0015 ple0016 ple0017 ple0018 ple0019 ple0020 ple0021 ple0022 ple0023 ple0024
foreach var of global vars_diagnosed {
    foreach year of numlist 2011(2)2019 {
        di "`year'" 
        tab `var' psample if syear == `year', m
    }    
    di _n _n
}

tabstat $vars_diagnosed, by(syear) stat(N)

tab syear
* check for panel attrition ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/* tab syear _keep_all
Fri  6 Aug 16:40:44 CEST 2021
(SurveyYea |       _keep_all
        r) |         0          1 |     Total
-----------+----------------------+----------
      2011 |    12,266      8,803 |    21,069 
      2013 |     8,258      8,803 |    17,061 
      2015 |     6,118      8,803 |    14,921 
      2017 |     4,130      8,803 |    12,933 
      2019 |     1,864      8,803 |    10,667 
-----------+----------------------+----------
     Total |    32,636     44,015 |    76,651 

//keep if _keep_all == 1  */

labelbook, problems
cap lab drop `r(notused)' 

tab syear
desc, short
lab language EN
cap desc using $inter/gathered_p_ppath.dta, short
save $inter/gathered_p_ppath.dta, replace


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# merge with 2019 wealth and interpolate wealth for in-between years
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

desc using $inter/data_general_sample_all_years.dta, short
desc using $inter/gathered_p_ppath.dta, short
desc using $inter/wealth_interpolated.dta, short

use $inter/data_general_sample_all_years.dta, clear 
merge 1:1 pid syear using $inter/gathered_p_ppath.dta, gen(_mg_valids_gathered)
merge 1:1 pid syear using $inter/wealth_interpolated.dta, gen(_mg_valids_wealth_ipol)
bys _mg_valids_gathered     : tab syear
bys _mg_valids_wealth_ipol  : tab syear
sort pid syear

keep if _mg_valids_wealth_ipol == 3 
tab syear
count /* there should be around 420k obs */
distinct pid /*  57837 distinct pids */


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# finalize wealth merged data
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

lab language EN
qui labelbook, problems
if "`r(notused)'" != "" lab drop `r(notused)' /* drop unsed labels  */
qui compress
desc, short
tab syear
mvdecode nw_*ile*, mv(-1 = .a \ -2 = .b \ -3 = .c \ -4 = .d \ -5 = .e \ -6 = .f \ -7 = .g \ -8 = .h) 
save $inter/i_wealth_ipol.dta, replace 


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# Save subsamples (diff years)
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if 0 use $inter/i_wealth_ipol.dta, clear
* keep final sample ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
count 
count if inlist(syear, 2009, 2011, 2013, 2015, 2017, 2019) 

/* if $is_longer_run keep if !mi(nw) & _mg_gath_p_ppath==3 */
/* TODO: check who gets dropped */
/* if !$is_longer_run keep if inlist(syear, 2009, 2011, 2013, 2015, 2017, 2019) */
//tab syear _keep_all if /* inrange(psample, 1, 10) & */ inrange(syear, 2011, 2019)

count if inlist(syear, 2002, 2007, 2012, 2017, 2019) 
keep if inlist(syear, 2002, 2007, 2012, 2017, 2019) 

lab language EN
qui labelbook, problems
if "`r(notused)'" != "" lab drop `r(notused)' /* drop unsed labels  */
qui compress
desc, short
tab syear
mvdecode nw_* gw_*, mv(-1 = .a \ -2 = .b \ -3 = .c \ -4 = .d \ -5 = .e \ -6 = .f \ -7 = .g \ -8 = .h) 
save $inter/01_p_ppath_wealth_2002_2019_5yrl.dta, replace
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

log close  
cp $log/tmp/01_b_gather_wealth_health_vars.log $log/, replace

exit 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# checks
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


use $inter/01_p_ppath_wealth_2002_2019_5yrl.dta, clear
if 0 {
    count if mi(nw)
    count if !mi(nw)
    tab psample if mi(nw)
    tab psample if !mi(nw)
}
if 0 {
    fre psample
    keep if psample==14
    list pid syear nw nw, sepby(pid)
}


* check develp of net wealth
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
tabstat nw,                         by(syear) stat(mean min p1 p5 p10 p25 p50 p75 p90 p95 p99 max)
tabstat nw [w=phrf] if psample!=22, by(syear) stat(mean min p1 p5 p10 p25 p50 p75 p90 p95 p99 max)
tabstat nw [w=phrf],                by(syear) stat(mean min p1 p5 p10 p25 p50 p75 p90 p95 p99 max)

* wealth quantiles
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use $inter/01_p_ppath_wealth_merged.dta, clear
tsset pid syear, delta(2)
gen w_pile_lag = l.nw_pile 
corr nw_pile w_pile_lag
/*           | we~pile w_ptil~g
-------------+------------------
nw_pile |   1.0000
 w_pile_lag |   0.9151   1.0000 */

/* 
by pid (syear), sort: gen obs_count = _N if !mi(nw)
count if obs_count < 5
*/
