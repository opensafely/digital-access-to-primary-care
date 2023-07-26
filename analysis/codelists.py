from ehrql import codelist_from_csv


f2f_consultation = codelist_from_csv(
    "codelists/user-KatieDavies_1234-f2f-consultation.csv",
    column="code",
)

virtual_consultation = codelist_from_csv(
    "codelists/user-KatieDavies_1234-virtual-consultation.csv",
    column="code",
)
