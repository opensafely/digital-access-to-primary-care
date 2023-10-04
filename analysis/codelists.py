from ehrql import codelist_from_csv


f2f_consultation = codelist_from_csv(
    "codelists/user-KatieDavies_1234-generic-consultation.csv",
    column="code",
)

virtual_consultation = codelist_from_csv(
    "codelists/user-KatieDavies_1234-virtual-consultation.csv",
    column="code",
)
ethnicity_codelist = codelist_from_csv(
    "codelists/opensafely-ethnicity-snomed-0removed.csv",
    column="snomedcode",
    category_column="Grouping_6",
)
