// IIT Institute of Software Design and Security
// FH JOANNEUM (fhj)
// Template for a Bachelor's and Master's thesis

// central place where libraries are imported
// (or macros are defined)
// which are used within all the chapters:
#import "chapters/global.typ": *

// Definitions for the glossary must be defined (i.e. registered)
// before the main document is processed
#import "chapters/glossary-definitions.typ": gls-entries
#register-glossary(gls-entries)
#show: make-glossary

#show: doc => thesis(
  // Status of the document:
  //    true...just a draft (default)
  //         includes TODO text and
  //         includes current timestamp text "Preview printed.."
  //    false...the final version:
  //         will remove the red TODO text from the title page
  //         and removes the current timestamp "Preview printed 20xx-xx-xx" from the title page
  draft: true,
  // Logo should be ok for a thesis at IIT, the
  // Institute of Software Design and Security (see https://www.fh-joanneum.at/iit)
  logo: image("./figures/bht_logo.svg", width: 60%),
  // Your study programme
  // Master:
  //   ims ... IT & Mobile Security (see https://www.fh-joanneum.at/ims)
  //   irm ... IT-Recht & Management (see https://www.fh-joanneum.at/irm)
  // Bachelor:
  //   swd ... Software Design & Cloud Computing (VZ) (see https://www.fh-joanneum.at/itm)
  //   swd ... Software Design & Cloud Computing (BB) (see https://www.fh-joanneum.at/swd)
  //   msd ... Mobile Software Development (see https://www.fh-joanneum.at/msd)
  font-size: 13pt,
  study: "mi", // ims, irm, swd, msd
  // For study programme "ims" the language is required to be in English
  language: "de", // en, de
  title: "<title>",
  // Optional subtitle. Set to none if you do not need a subtitle.
  subtitle: "<subtitle>", supervisor: "Dr. Prof. Hartmut Schirmacher", author: "Leonard Huth",
  // E.g. "Dezember 2025" or "Dec / 2025"
  submission-date: "<submission_date>",
  // For study programme "IMS"
  // the German abstract is optional, i.e. set to none.
  abstract-ge: [
    #include "./chapters/abstract.typ"
    #todo(
      [TODO: Die Kurzfassung],
    )
  ],
  after-title: [
    // Your content here, e.g. a statutory declaration:           // #include "./chapters/declaration.typ" 
  ],
  // Enable/disable outlines for "listings", "tables","equations", and/or "figures"
  show-list-of: (),
  // The *.bib file with the bibliography entries
  biblio: bibliography("biblio.bib", style: "ieee"),
  // Do not change this
  // Note: 'doc' stands for the rest of this file, the documement
  //
  doc,
)
// Include as many chapters as you like
// e.g.:

// #include "./chapters/acknowledgements.typ"
// #pagebreak()

#include "./chapters/1-intro.typ"
#pagebreak()

#include "./chapters/2-basics.typ"
#pagebreak()

#include "./chapters/3-background.typ"
#pagebreak()

#include "./chapters/4-concept.typ"
#pagebreak()

#include "./chapters/5-implementation.typ"
#pagebreak()

//#include "./chapters/6-evaluation.typ"
//#pagebreak()

//#include "./chapters/7-conclusion.typ"
//#pagebreak()

//#include "./chapters/glossary.typ"
//#pagebreak()

// Appendix (optional)
//    Will appear BEFORE the Bibliograhy and after the Glossary.
//    Alternatively, you might like the appendix AFTER the Bibliograhy.
//    In this case you have to put the 'include appendix..' - line from below
//    to near the end of file "lib.typ" ( just before the last closing "}" )
// #include "./chapters/appendix.typ"
// #pagebreak()
